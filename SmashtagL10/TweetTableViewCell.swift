//
//  TweetTableViewCell.swift
//  Smashtag
//
//  Created by iMac21.5 on 4/26/15.
//  Copyright (c) 2015 Garth MacKenzie. All rights reserved.
//

import UIKit

class TweetTableViewCell: UITableViewCell {
    
    var tweet: Tweet? {
        didSet {
            updateUI()
        }
    }
    
    @IBOutlet weak var tweetProfileImageView: UIImageView!
    @IBOutlet weak var tweetScreenNameLabel: UILabel!
    @IBOutlet weak var tweetTextLabel: UILabel!
    //added after
    @IBOutlet weak var tweetCreatedLabel: UILabel!
//    @IBOutlet weak var tweetPhotoImageView: UIImageView?
//    @IBAction func openURL(sender: UIButton) {
//        if let tweet = self.tweet {
//            if tweetTextLabel?.text != nil {
//                for photo in tweet.media {
//                    if let tweetImageURL = photo.url {
//                        UIApplication.sharedApplication().openURL(tweetImageURL)
//                    } else {
//                        sender.enabled = false
//                    }
//                }
//            }
//        }
//    }
    
    func updateUI() {
        //reset any existing tweet information
        tweetProfileImageView?.image = nil
        tweetScreenNameLabel?.text = nil
        tweetTextLabel?.attributedText = nil
        tweetCreatedLabel?.text = nil
        
        //load new info from tweet if any
        if let tweet = self.tweet {
            tweetScreenNameLabel?.text = tweet.user.description
            tweetTextLabel?.text = tweet.text
            if tweetTextLabel?.text != nil {
                for photo in tweet.media {
                    tweetScreenNameLabel.text! += " 📷"
                }
            }
            if tweet.urls.count > 0 { //add attributedText for URLs
                if let hasPartialLink = tweet.urls.first?.keyword.lastPathComponent.hasSuffix("...") {
                    if hasPartialLink {
                        println(tweet.urls.first?.keyword)
                    } else if let range = tweet.urls.first?.nsrange {
                        let attributedString = NSMutableAttributedString(string: tweet.text)
                        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.blueColor(), range: range)
                        tweetTextLabel?.attributedText = attributedString
                    }
                }
            }
//            if tweetTextLabel?.text != nil {
//                for photo in tweet.media {
//                    tweetTextLabel.text! += " 📷"
    //I added the following (from outlet tweetPhotoImageView) plus the time of tweet on right
//                    if let tweetImageURL = photo.url {
//                        let qos = Int(QOS_CLASS_USER_INITIATED.value)
//                        dispatch_async(dispatch_get_global_queue(qos, 0)) { () -> Void in //get url *slow
//                            if let imageData = NSData(contentsOfURL: tweetImageURL) { //blocks main thread
//                                dispatch_async(dispatch_get_main_queue()) {
//                                    tweetPhotoImageView?.image = UIImage(data: imageData)
//                                }
//                            }
//                        }
//                    }
            
//                }
//            }
            if let profileImageURL = tweet.user.profileImageURL {
                let qos = Int(QOS_CLASS_USER_INITIATED.value)
                dispatch_async(dispatch_get_global_queue(qos, 0)) { () -> Void in //get url *slow
                    if let imageData = NSData(contentsOfURL: profileImageURL) { //blocks main thread
                        dispatch_async(dispatch_get_main_queue()) {
                            tweetProfileImageView?.image = UIImage(data: imageData)
                        }
                    }
                }
            }
            let formatter = NSDateFormatter()
            if NSDate().timeIntervalSinceDate(tweet.created) > 24*60*60 {
                formatter.dateStyle = NSDateFormatterStyle.ShortStyle
            } else {
                formatter.timeStyle = NSDateFormatterStyle.ShortStyle
            }
            tweetCreatedLabel?.text = formatter.stringFromDate(tweet.created)
        }
    }
    
}
