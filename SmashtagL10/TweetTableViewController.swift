//
//  TweetTableViewController.swift
//  Smashtag
//
//  Created by iMac21.5 on 4/24/15.
//  Copyright (c) 2015 Garth MacKenzie. All rights reserved.
//

import UIKit

class TweetTableViewController: UITableViewController, UITextFieldDelegate {
    
    var tweets = [[Tweet]]()

    var searchText: String = "" {
        didSet {
            lastSucessfulRequest = nil
            searchTextField?.text = searchText
            tweets.removeAll()
            tableView.reloadData()  //blank out table
            refresh()
        }
    }
    
    // MARK: View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        refresh()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if searchText == "" {
            if let query = NSUserDefaults.standardUserDefaults().stringForKey("HashTag") {
                searchText = query
            }
        }
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        observeTextFields()
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if let observer = udObserver {
            NSNotificationCenter.defaultCenter().removeObserver(observer)
        }
    }

    var lastSucessfulRequest: TwitterRequest?
    var nextRequestToAttempt: TwitterRequest? {
        if lastSucessfulRequest == nil {
            if searchText != "" {
                return TwitterRequest(search: searchText, count: 100)
            } else {
                return nil
            }
        } else {
            return lastSucessfulRequest!.requestForNewer
        }
    }
    
    func refresh() {
        if refreshControl != nil {
            refreshControl?.beginRefreshing()
        }
        refresh(refreshControl)
    }

    @IBAction func refresh(sender: UIRefreshControl?) {
        if searchText != "" {
            if let request = nextRequestToAttempt {
                request.fetchTweets { (newTweets) -> Void in
                    dispatch_async(dispatch_get_main_queue()) { () -> Void in
                        if newTweets.count > 0 {
                            self.lastSucessfulRequest = request
                            self.tweets.insert(newTweets, atIndex: 0)
                            self.tableView.reloadData()
                            sender?.endRefreshing()
                        }
                    }
                }
            }
        } else {
            sender?.endRefreshing()
        }
    }
    
    var udObserver: NSObjectProtocol?
    
    func observeTextFields() {
        udObserver = NSNotificationCenter.defaultCenter().addObserverForName(NSUserDefaultsDidChangeNotification,
            object: nil,
            queue: nil) { (notification) -> Void in
                self.searchText = NSUserDefaults.standardUserDefaults().stringForKey("HashTag")!
        }
    }
        
    @IBOutlet weak var searchTextField: UITextField! {
        didSet {
            searchTextField.delegate = self
            searchTextField.text = searchText
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == searchTextField {
            textField.resignFirstResponder()
            searchText = textField.text
        }
        return true
    }
    
    // MARK: - UITableViewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return tweets.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return tweets[section].count
    }

    private struct Storyboard {
        static let CellReuseIdentifier = "Tweet"
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.CellReuseIdentifier, forIndexPath: indexPath) as! TweetTableViewCell

        // Configure the cell...
        cell.tweet = tweets[indexPath.section][indexPath.row]
//        cell.textLabel?.text = tweet.text
//        cell.detailTextLabel?.text = tweet.user.name
        return cell
    }

    // MARK: - Navigation
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if identifier == Constants.ShowImageSegue {
            let selectedIndex = self.tableView.indexPathForCell(sender as! UITableViewCell)
            if let cell = tableView(tableView, cellForRowAtIndexPath: selectedIndex!) as? TweetTableViewCell {
                let tweet = cell.tweet
                if tweet!.media.count == 0 && tweet!.urls.count == 0 {
                    return false
                }
            }
        }
        return true
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        var destination = segue.destinationViewController as? UIViewController
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController
        }
        if let ivc = destination as? ImageViewController {
            if segue.identifier == Constants.ShowImageSegue {
                //prepare
                let selectedIndex = self.tableView.indexPathForCell(sender as! UITableViewCell)
                if let cell = tableView(tableView, cellForRowAtIndexPath: selectedIndex!) as? TweetTableViewCell {
                    let tweet = cell.tweet
                    let media = tweet!.media
                    if media.count > 0 {
                        if let tweetImageURL = media.first!.url {
                            ivc.imageURL = tweetImageURL
                        }
                    }
                    if tweet!.urls.count > 0 {
                        if let url = NSURL(string: tweet!.urls.first!.keyword) {
                            UIApplication.sharedApplication().openURL(url)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Constants
    private struct Constants {
        static let ShowImageSegue = "Show Image"
    }

}
