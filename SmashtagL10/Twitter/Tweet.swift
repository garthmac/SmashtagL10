//
//  Tweet.swift
//  Twitter
//
//  Created by CS193p Instructor.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import Foundation
import UIKit

// a simple container class which just holds the data in a Tweet
// IndexedKeywords are substrings of the Tweet's text
// for example, a hashtag or other user or url that is mentioned in the Tweet
// note carefully the comments on the two range properties in an IndexedKeyword
// Tweet instances re created by fetching from Twitter using a TwitterRequest

public class Tweet : CustomStringConvertible
{
    public var text: String
    public var user: User
    public var created: NSDate
    public var id: String?
    public var media = [MediaItem]()
    public var hashtags = [IndexedKeyword]()
    public var urls = [IndexedKeyword]()
    public var userMentions = [IndexedKeyword]()

    public struct IndexedKeyword: CustomStringConvertible
    {
        public var keyword: String              // will include # or @ or http:// prefix
        public var range: Range<String.Index>   // index into the Tweet's text property only
        public var nsrange: NSRange!          // index into an NS[Attributed]String made from the Tweet's text

        public init?(data: NSDictionary?, inText: String, prefix: String?) {
            let indices = data?.valueForKeyPath(TwitterKey.Entities.Indices) as? NSArray
            if let startIndex = (indices?.firstObject as? NSNumber)?.integerValue {
                if let endIndex = (indices?.lastObject as? NSNumber)?.integerValue {
                    let length = inText.characters.count
                    if length > 0 {
                        let start = max(min(startIndex, length-1), 0)
                        let end = max(min(endIndex, length), 0)
                        if end > start {
                            //var str = "Hello Swift!"
                            //str.startIndex // first index
                            //str.endIndex // end index
                            //str[str.startIndex.advancedBy(4)...str.startIndex.advancedBy(8)] // get characters in range index 4 to 8
                            //str.substringToIndex(str.startIndex.advancedBy(5)) // returns string up to the 5th character
                            //str.substringFromIndex(str.startIndex.advancedBy(5)) // returns string from the 5th character
                            self.range = Range(start: inText.startIndex.advancedBy(start), end: inText.startIndex.advancedBy(end)) //advance(inText.startIndex, start)...advance(inText.startIndex, end-1)
                            self.keyword = inText.substringWithRange(self.range)
//                            print(inText.substringWithRange(self.range))
//                            print(keyword)
                            if prefix != nil && !self.keyword.hasPrefix(prefix!) && start > 0 {
                                self.range = Range(start: inText.startIndex.advancedBy(start-1), end: inText.startIndex.advancedBy(end-1)) //advance(inText.startIndex, start-1)...advance(inText.startIndex, end-2)
                                //print(inText.substringWithRange(self.range))
                                self.keyword = inText.substringWithRange(self.range)
                            }
                            if prefix == nil || self.keyword.hasPrefix(prefix!) {
                                self.nsrange = inText.rangeOfString(self.keyword, nearRange: NSMakeRange(startIndex, endIndex-startIndex))
                                if self.nsrange.location != NSNotFound {
                                    return
                                }
                            }
                        }
                    }
                }
            }
            return nil
        }

        public var description: String { get { return "\(keyword) (\(nsrange.location), \(nsrange.location+nsrange.length-1))" } }
    }
    
    public var description: String { return "\(user) - \(created)\n\(text)\nhashtags: \(hashtags)\nurls: \(urls)\nuser_mentions: \(userMentions)" + (id == nil ? "" : "\nid: \(id!)") }

    // MARK: - Private Implementation

    init?(data: NSDictionary?) {
        if let user = User(data: data?.valueForKeyPath(TwitterKey.User) as? NSDictionary) {
            self.user = user
            if let text = data?.valueForKeyPath(TwitterKey.Text) as? String {
                self.text = text
                if let created = (data?.valueForKeyPath(TwitterKey.Created) as? String)?.asTwitterDate {
                    self.created = created
                    self.id = data?.valueForKeyPath(TwitterKey.ID) as? String
                    if let mediaEntities = data?.valueForKeyPath(TwitterKey.Media) as? NSArray {
                        for mediaData in mediaEntities {
                            if let mediaItem = MediaItem(data: mediaData as? NSDictionary) {
                                self.media.append(mediaItem)
                            }
                        }
                    }
                    let hashtagMentionsArray = data?.valueForKeyPath(TwitterKey.Entities.Hashtags) as? NSArray
                    self.hashtags = getIndexedKeywords(hashtagMentionsArray, inText: text, prefix: "#")
                    let urlMentionsArray = data?.valueForKeyPath(TwitterKey.Entities.URLs) as? NSArray
                    self.urls = getIndexedKeywords(urlMentionsArray, inText: text, prefix: "h")
                    let userMentionsArray = data?.valueForKeyPath(TwitterKey.Entities.UserMentions) as? NSArray
                    self.userMentions = getIndexedKeywords(userMentionsArray, inText: text, prefix: "@")
                    return
                }
            }
        }
        // we've failed
        // but compiler won't let us out of here with non-optional values unset
        // so set them to anything just to able to return nil
        // we could make these implicitly-unwrapped optionals, but they should never be nil, ever
        self.text = ""
        self.user = User()
        self.created = NSDate()
        return nil
    }

    private func getIndexedKeywords(dictionary: NSArray?, inText: String, prefix: String? = nil) -> [IndexedKeyword] {
        var results = [IndexedKeyword]()
        if let indexedKeywords = dictionary {
            for indexedKeywordData in indexedKeywords {
                if let indexedKeyword = IndexedKeyword(data: indexedKeywordData as? NSDictionary, inText: inText, prefix: prefix) {
                    results.append(indexedKeyword)
                }
            }
        }
        return results
    }
    
    struct TwitterKey {
        static let User = "user"
        static let Text = "text"
        static let Created = "created_at"
        static let ID = "id_str"
        static let Media = "entities.media"
        struct Entities {
            static let Hashtags = "entities.hashtags"
            static let URLs = "entities.urls"
            static let UserMentions = "entities.user_mentions"
            static let Indices = "indices"
        }
    }
}

private extension NSString {
    func rangeOfString(substring: NSString, nearRange: NSRange) -> NSRange {
        var start = max(min(nearRange.location, length-1), 0)
        var end = max(min(nearRange.location + nearRange.length, length), 0)
        var done = false
        while !done {
            let range = rangeOfString(substring as String, options: NSStringCompareOptions(), range: NSMakeRange(start, end-start))
            if range.location != NSNotFound {
                return range
            }
            done = true
            if start > 0 { start-- ; done = false }
            if end < length { end++ ; done = false }
        }
        return NSMakeRange(NSNotFound, 0)
    }
}
private extension String {
    var asTwitterDate: NSDate? {
        get {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
            return dateFormatter.dateFromString(self)
        }
    }
}
//    func rangesOfString(findStr:String) -> [Range<String.Index>] {
//        var arr = [Range<String.Index>]()
//        var startInd = self.startIndex
//        // check first that the first character of search string exists
//        if self.characters.contains(findStr.characters.first!) {
//            // if so set this as the place to start searching
//            startInd = self.characters.indexOf(findStr.characters.first!)!
//        }
//        else {
//            // if not return empty array
//            return arr
//        }
//        var i = self.startIndex.distanceTo(startInd)
//        while i<=self.characters.count-findStr.characters.count {
//            if self[self.startIndex.advancedBy(i)..<self.startIndex.advancedBy(i+findStr.characters.count)] == findStr {
//                arr.append(Range(start:self.startIndex.advancedBy(i),end:self.startIndex.advancedBy(i+findStr.characters.count)))
//                i = i+findStr.characters.count
//            }
//            else {
//                i++
//            }
//        }
//        return arr
//    }
//} // try further optimisation by jumping to next index of first search character after every find


//"a very good hello, hello".rangesOfString("hello")
