//
//  ViewController.swift
//  500pxBicycle
//
//  Created by Ian MacFarlane on 9/5/16.
//  Copyright © 2016 Ian MacFarlane. All rights reserved.
//

import UIKit
import BTNavigationDropdownMenu

class PopularViewController: UIViewController {

    var feature = FivePxConstants.ParameterValues.Feature.Popular
    var posts = [FivePxPost]()
    let client = FivePxClient.sharedInstance()
    let realmClient = RealmClient.sharedInstance()
    var totalPages: Int?
    var totalItems: Int?
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var selectedCellLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureDropDownMenu()
        downloadPosts(1)
        self.tabBarItem.selectedImage = UIImage(named: "star_filled")!.imageWithRenderingMode(.AlwaysOriginal)
        self.tabBarItem.image = UIImage(named: "star")!.imageWithRenderingMode(.AlwaysOriginal)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.tabBar.hidden = false
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func showAlert(error: NSError) {
        let localDesc = error.localizedDescription
        
        let alertController = UIAlertController(title: "Error", message: localDesc, preferredStyle: .Alert)
        
        let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(defaultAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func downloadPosts(page: Int) {
        client.getPostsWithFeature(feature, page: page) { (success, error) in
            if success {
                self.totalPages = self.client.totalPages
                self.posts = self.client.fivePxPosts
                self.collectionView.reloadData()
            } else {
                if let error = error {
                    self.showAlert(error)
                }
            }
        }
    }
    
    func configureDropDownMenu() {
        let items = ["Popular", "Highest Rated", "Upcoming", "Editor's Choice", "Fresh Today", "Fresh Yesterday", "Fresh Weekly"]
        let parameter = [FivePxConstants.ParameterValues.Feature.Popular,
                         FivePxConstants.ParameterValues.Feature.HighestRated,
                         FivePxConstants.ParameterValues.Feature.Upcoming,
                         FivePxConstants.ParameterValues.Feature.EditorsChoice,
                         FivePxConstants.ParameterValues.Feature.FreshToday,
                         FivePxConstants.ParameterValues.Feature.FreshYesterday,
                         FivePxConstants.ParameterValues.Feature.FreshWeek]
        
        let menuView = BTNavigationDropdownMenu(navigationController: self.navigationController, containerView: self.navigationController!.view, title: "Popular", items: items)
        
        menuView.didSelectItemAtIndexHandler = { [weak self] (indexPath: Int) -> () in
            self!.feature = parameter[indexPath]
            self!.totalPages = nil
            self!.downloadPosts(1)
        }
        
        self.navigationItem.titleView = menuView
    }
    
    @IBAction func refreshButton(sender: UIBarButtonItem) {
        var randomPage = 1
        if totalPages != nil {
            //if let totalPages = totalPages {
            //randomPage = Int(arc4random_uniform(UInt32(totalPages))) + 1
            //}
            randomPage = Int(arc4random_uniform(UInt32(10))) + 1
        }
        
        downloadPosts(randomPage)
    }
}

extension PopularViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! CollectionViewCell
        configurePhotoCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configurePhotoCell(cell: CollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        
        let postImageUrl = posts[indexPath.item].thumbnailUrl
        let postImageID = posts[indexPath.item].id
        let postImageTitle = posts[indexPath.item].name
        
        guard let image = realmClient.getThumbnailImage(fromID: postImageID) else {
            //no image found in realm, go download it and set it to the imageview
            cell.loadingIndicator.startAnimating()
            client.loadImageToImageViewWithURL(postImageUrl, imageView: cell.imageView) { (success, error, data) in
                if success {
                    //create a realm object with the image data downloaded
                    if let data = data {
                        self.realmClient.saveThumbnailData(withId: postImageID, data: data, title: postImageTitle)
                        cell.loadingIndicator.stopAnimating()
                    }
                } else {
                    cell.loadingIndicator.stopAnimating()
                }
            }
            return
        }
        
        //image retrieved from realm successfully, set imageview to it
        cell.imageView.image = image
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
        
        let detailVC = self.storyboard?.instantiateViewControllerWithIdentifier("PhotoDetailViewController") as! PhotoDetailViewController
        detailVC.post = posts[indexPath.item]
        self.navigationController?.pushViewController(detailVC, animated: true)
    }
}

//MARK: FlowLayout Configuration

extension PopularViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let spacing: CGFloat = 1
        let itemWidth = (view.bounds.size.width / 2) - (spacing / 2)
        let itemHeight = itemWidth
        return CGSize(width: itemWidth, height: itemHeight)
    }
}

