//
//  TweetTableViewCell.swift
//  Smashtag
//
//  Created by iMac21.5 on 4/26/15.
//  Copyright (c) 2015 Garth MacKenzie. All rights reserved.
//

import UIKit

// A protocol that the TableViewCell uses to inform its delegate of state change
protocol TableViewCellDelegate {
    func openURL(sender: AnyObject)
}

class TweetTableViewCell: UITableViewCell {
    
    var tweet: Tweet? {
        didSet { updateUI() }
    }
    
    @IBOutlet weak var tweetProfileImageView: UIImageView!
    @IBOutlet weak var tweetScreenNameLabel: UILabel!
    @IBOutlet weak var tweetTextLabel: UILabel!
    //added after
    @IBOutlet weak var camera: UILabel!
    @IBOutlet weak var tweetCreatedLabel: UILabel!
    
    var originalCenter = CGPoint()
    var deleteOnDragRelease = false
    var completeOnDragRelease = true
    // The object that acts as delegate for this cell.
    var delegate: TableViewCellDelegate?
    
    func updateUI() {
        // add a pan recognizer
        let recognizer = UIPanGestureRecognizer(target: self, action: "handlePan:")
        recognizer.delegate = self
        addGestureRecognizer(recognizer)

        //reset any existing tweet information
        tweetProfileImageView?.image = nil
        tweetScreenNameLabel?.text = nil
        tweetTextLabel?.attributedText = nil
        tweetCreatedLabel?.text = nil
        camera?.text = nil
        
        if let tweet = self.tweet { //load new info from tweet if any
            tweetScreenNameLabel?.text = tweet.user.description
            tweetTextLabel?.text = tweet.text
            if tweetTextLabel?.text != nil {
                for photo in tweet.media {
                    camera?.text = "📷"
                }
            }
            if tweet.urls.count > 0 { //add attributedText for URLs
                if let lastPath = tweet.urls.first?.keyword.lastPathComponent {
                    if lastPath.hasSuffix("…") {
                        //println(tweet.urls.first?.keyword)
                    } else {
                        if let range = tweet.urls.first?.nsrange {
                            let attributedString = NSMutableAttributedString(string: tweet.text)
                            attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.blueColor(), range: range)
                            tweetTextLabel?.attributedText = attributedString
                        }
                    }
                }
            }
            if let profileImageURL = tweet.user.profileImageURL {
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) { () -> Void in //get url *slow
                    if let imageData = NSData(contentsOfURL: profileImageURL) { //blocks main thread
                        dispatch_async(dispatch_get_main_queue()) {
                            self.tweetProfileImageView?.image = UIImage(data: imageData)
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
    //MARK: - horizontal pan gesture methods
    func handlePan(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .Began {
            // when the gesture begins, record the current center location
            originalCenter = center
        }
        if recognizer.state == .Changed {
            let translation = recognizer.translationInView(self)
            center = CGPointMake(originalCenter.x + translation.x, originalCenter.y)
            // has the user dragged the item far enough to initiate a delete/complete?
            deleteOnDragRelease = frame.origin.x < -frame.size.width / 2.0
        }
        if recognizer.state == .Ended {
            // the frame this cell had before user dragged it
            let originalFrame = CGRect(x: 0, y: frame.origin.y,
                width: bounds.size.width, height: bounds.size.height)
            if !deleteOnDragRelease {
                // if the item is not being deleted, snap back to the original location
                UIView.animateWithDuration(0.2, animations: {self.frame = originalFrame})
            } else if completeOnDragRelease {
                if delegate != nil {
                    if tweet!.urls.count > 0 {
                        delegate!.openURL(self)
                    }
                }
                UIView.animateWithDuration(0.2, animations: {self.frame = originalFrame})
            }
        }
    }
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGestureRecognizer.translationInView(superview!)
            if fabs(translation.x) > fabs(translation.y) {
                return true
            }
            return false
        }
        return false
    }
}
extension String {
    var ns: NSString {
        return self as NSString
    }
    var pathExtension: String? {
        return ns.pathExtension
    }
    var lastPathComponent: String? {
        return ns.lastPathComponent
    }
}
