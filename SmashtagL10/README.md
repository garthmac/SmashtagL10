# SmashtagL10

uses Twitter API with UITableViewController, UITextFieldDelegate, UITableViewCell,
    UINavigationController, UIScrollView
uses segues for transitions and Submits a block for asynchronous execution on a 
    dispatch queue and returns immediately.
uses Settings.bundle for settings
- specify default Hash Tag eg. #stanford for Twitter Search Query (editable in use)
- select switch to enable/disable openURL for valid links (blue text)

App gets upto last 100 "Tweets" and displays userProfile image, tweetUserName+camera icon 
  in place of inline image, time of tweet and tweet text 
- When table cell is selected, will navigate to zoomable/scroll view of image with button
  for (Save to Album) and/or open website (if tweet only includes a valid URL (blue text))

- added swipe right for viewing web (only needed if cell selection has both photo and highlighted URL)
-selecting tweet cell opens URL if no photo and <Settings><OpenURLs> enabled

written in Xcode 6.3.2 for iOS8.3+
updated to Xcode 7.1 on Oct 26/15
