//
//  ImageViewController.swift
//  Cassini
//
//  Created by iMac21.5 on 4/23/15.
//  Copyright (c) 2015 Garth MacKenzie. All rights reserved.
//

import UIKit
import AssetsLibrary

class ImageViewController: UIViewController, UIScrollViewDelegate {
    
    // this is the model
    var imageURL: NSURL? {
        didSet {
            image = nil
            if view.window != nil { //check if on screen
                fetchImage()
            }
        }
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    private func fetchImage() {
        if let url = imageURL {
            spinner.startAnimating()
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) { () -> Void in //get .jpg file *slow
                let imageData = NSData(contentsOfURL: url)
                dispatch_async(dispatch_get_main_queue()) {
                    if url == self.imageURL { //mutiple selects...get last
                        if imageData != nil {
                            self.image = UIImage(data: imageData!)
                        } else {
                            self.image = nil
                        }
                    }
                }
            }
        }
        spinner.stopAnimating()
    }

    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {  //note: frame.size not image
            scrollView.delegate = self
        }
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView //this last thing + UIScrollViewDelegate at top
    }
    
    private var imageView = UIImageView()  //no frame yet
    private var image: UIImage? { // a computed property instead of func
        get { return imageView.image }
        set {
            if let image = newValue {
                imageView = UIImageView(image: image)
                imageView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: image.size)
                scrollView.addSubview(imageView)    //moved from viewDidLoad
                scrollView.contentSize = image.size
                let scrollViewFrame = scrollView.frame
                let scaleWidth = scrollViewFrame.size.width / scrollView.contentSize.width
                let scaleHeight = scrollViewFrame.size.height / scrollView.contentSize.height
                let minScale = min(scaleWidth, scaleHeight)
                scrollView.minimumZoomScale = minScale
                scrollView.maximumZoomScale = 2.0
                scrollView.zoomScale = minScale
            }
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        centerScrollViewContents()
    }
    
    func centerScrollViewContents() {
        let boundsSize = scrollView.bounds.size
        var contentsFrame = imageView.frame
        if contentsFrame.size.width < boundsSize.width {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
        } else {
            contentsFrame.origin.x = 0.0
        }
        if contentsFrame.size.height < boundsSize.height {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
        } else {
            contentsFrame.origin.y = 0.0
        }
        imageView.frame = contentsFrame
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if image == nil {
            fetchImage() // this usually happens
        }
    }

    @IBAction func savePhoto(sender: UIBarButtonItem) {
        if let imageData = UIImageJPEGRepresentation(image!, 1.0) {
            let library = ALAssetsLibrary()
            library.writeImageDataToSavedPhotosAlbum(imageData, metadata: nil, completionBlock: nil)
        }
    }

    @IBAction func back(sender: AnyObject) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
