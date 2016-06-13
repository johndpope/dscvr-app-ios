//
//  ViewController.swift
//  PhotoViewGallery
//
//  Created by Thadz on 25/05/2016.
//  Copyright © 2016 Brewed Concepts. All rights reserved.
//

import UIKit
import Photos
import ReactiveCocoa

let albumName = "RICOH THETA"           //Replace with required folder name
let albumNames = ["RICOH THETA","ROBERT","WHAT THE PUCK"]



class ViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate {

    var collectionView: UICollectionView!
    let imagePicked = MutableProperty<UIImage?>(nil)
    var albumFound : Bool = false
    var assetCollection: PHAssetCollection = PHAssetCollection()
    var photosAsset: PHFetchResult!
    var assetThumbnailSize:CGSize!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 70, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 90.0, height: 90.0)
        
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerClass(PhotoThumbnail.self, forCellWithReuseIdentifier: "Cell")
        collectionView.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(collectionView)
        
        
        for object in albumNames {
            print(object)
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection:PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
        
        if let first_Obj:AnyObject = collection.firstObject{
            //found the album
            self.albumFound = true
            self.assetCollection = first_Obj as! PHAssetCollection
        }else{
            //Album placeholder for the asset collection, used to reference collection in completion handler
            var albumPlaceholder:PHObjectPlaceholder!
            //create the folder
            NSLog("\nFolder \"%@\" does not exist\nCreating now...", albumName)
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(albumName)
                albumPlaceholder = request.placeholderForCreatedAssetCollection
                },
                                                               completionHandler: {(success:Bool, error:NSError?)in
                                                                if(success){
                                                                    print("Successfully created folder")
                                                                    self.albumFound = true
                                                                    let collection = PHAssetCollection.fetchAssetCollectionsWithLocalIdentifiers([albumPlaceholder.localIdentifier], options: nil)
                                                                    self.assetCollection = collection.firstObject as! PHAssetCollection
                                                                }else{
                                                                    print("Error creating folder")
                                                                    self.albumFound = false
                                                                }
            })
        }
        
        let closeButton = UIButton()
        closeButton.setBackgroundImage(UIImage(named:"close_icn"), forState: .Normal)
        closeButton.anchorInCorner(.TopLeft, xPad: 10, yPad: 10, width: 40 , height: 40)
        closeButton.addTarget(self, action: #selector(closePhotoLibrary), forControlEvents: .TouchUpInside)
        self.view.addSubview(closeButton)
        
        let photoLabel = UILabel()
        photoLabel.textAlignment = .Center
        photoLabel.text = "360 Images"
        photoLabel.font = .fontDisplay(20, withType: .Semibold)
        self.view.addSubview(photoLabel)
        photoLabel.anchorToEdge(.Top, padding: 10, width: 150, height: 40)
    }
    
    func closePhotoLibrary() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        
        // Get size of the collectionView cell for thumbnail image
        if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout{
            let cellSize = layout.itemSize
            self.assetThumbnailSize = CGSizeMake(cellSize.width, cellSize.height)
        }
        
        //fetch the photos from collection
        self.navigationController?.hidesBarsOnTap = false   //!! Use optional chaining
        self.photosAsset = PHAsset.fetchAssetsInAssetCollection(self.assetCollection, options: nil)
        
        
        if let photoCnt = self.photosAsset?.count{
            if(photoCnt == 0){
                //notify if photos are not available
            }
        }
        self.collectionView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count: Int = 0
        if(self.photosAsset != nil){
            count = self.photosAsset.count
        }
        return count;
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! PhotoThumbnail
        cell.backgroundColor = UIColor.whiteColor()
        
        let asset: PHAsset = self.photosAsset[indexPath.item] as! PHAsset
        
        // Create options for retrieving image (Degrades quality if using .Fast)
        //        let imageOptions = PHImageRequestOptions()
        //        imageOptions.resizeMode = PHImageRequestOptionsResizeMode.Fast
        PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: self.assetThumbnailSize, contentMode: .AspectFill, options: nil, resultHandler: {(result, info)in
            if let image = result {
                cell.imageView.image = image
            }
        })
        
        return cell
    }
    
    //UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat{
        return 4
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat{
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let cellSize = CGSizeMake(90.0, 90.0)
        
        return cellSize
    }
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let asset: PHAsset = self.photosAsset[indexPath.item] as! PHAsset
        
        let imageOptions = PHImageRequestOptions()
        imageOptions.deliveryMode = .HighQualityFormat
        imageOptions.synchronous = true
        
        PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: CGSizeMake(CGFloat(5376), CGFloat(2688)), contentMode: .AspectFill, options: imageOptions, resultHandler: {(result, info)in
            if let image = result {
                self.imagePicked.value = image
                self.closePhotoLibrary()
            }
        })
        
    }
}
