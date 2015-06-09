//
//  ImageViewController.swift
//  Cassini
//
//  Created by iMac21.5 on 4/23/15.
//  Copyright (c) 2015 Garth MacKenzie. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate {
    
    // this is the model
    var imageURL: NSURL? {
        didSet {
            image = nil
            if view.window != nil { //check if on screen...never happens
                fetchImage()
            }
        }
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    private func fetchImage() {
        if let url = imageURL {
            spinner?.startAnimating()
            let qos = Int(QOS_CLASS_USER_INITIATED.value)
            dispatch_async(dispatch_get_global_queue(qos, 0)) { () -> Void in //get .jpg file *slow
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
    }
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {  //note: frame.size not image
            scrollView.contentSize = imageView.frame.size
            scrollView.delegate = self
            scrollView.minimumZoomScale = 0.03
            scrollView.maximumZoomScale = 2.0
        }
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView //this last thing + UIScrollViewDelegate at top
    }
    
    private var imageView = UIImageView()  //no frame yet
    private var image: UIImage? { // a computed property instead of func
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            //scrollView.addSubview(imageView) in viewDidLoad()
            imageView.sizeToFit()
            //use ? if not set yet
            scrollView?.contentSize = imageView.frame.size
            spinner?.stopAnimating()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.addSubview(imageView)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if image == nil {
            fetchImage() // this usually happens
        }
    }
    
    @IBAction func done(sender: AnyObject) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
