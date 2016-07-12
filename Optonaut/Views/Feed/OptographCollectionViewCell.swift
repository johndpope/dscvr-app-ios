//
//  CollectionViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 24/12/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import SceneKit
import SpriteKit
import Foundation
import Async
import SwiftyUserDefaults
import MediaPlayer
import Kingfisher
import AVFoundation
import AVKit

class TouchRotationSource: RotationMatrixSource {
    
    var isTouching = false
    
    // Take care, compared to the webviewer implementation,
    // phi and theta are switched since native apps and the browser use
    // different reference frames.
    var phi: Float = 0
    var theta: Float = Float(-M_PI_2)
    
    // FOV of the scene
    private let vfov: Float
    private let hfov: Float
    
    // Damping
    private var phiDiff: Float = 0
    private var thetaDiff: Float = 0
    var phiDamp: Float = 0
    var thetaDamp: Float = 0
    var dampFactor: Float = 0.9
    
    private var touchStartPoint: CGPoint?
    
    private let sceneWidth: Int
    private let sceneHeight: Int
    
    // Dependentvar optograph format. This values are suitable for
    // Stitcher version <= 7.
    private let border = Float(M_PI) / Float(6.45)
    private let minTheta: Float
    private let maxTheta: Float
    
    init(sceneSize: CGSize, hfov: Float) {
        self.hfov = hfov
        
        sceneWidth = Int(sceneSize.width)
        sceneHeight = Int(sceneSize.height)
        
        vfov = hfov * Float(sceneHeight) / Float(sceneWidth)
        
        maxTheta = -border - (vfov * Float(M_PI) / 180) / 2
        minTheta = Float(-M_PI) - maxTheta
    }
    
    func touchStart(point: CGPoint) {
        touchStartPoint = point
        isTouching = true
    }
    
    func touchMove(point: CGPoint) {
        if !isTouching {
            return
        }
        
        let x0 = Float(sceneWidth / 2)
        let y0 = Float(sceneHeight / 2)
        let flen = y0 / tan(vfov / 2 * Float(M_PI) / 180)
        
        let startPhi = atan((Float(touchStartPoint!.x) - x0) / flen)
        let startTheta = atan((Float(touchStartPoint!.y) - y0) / flen)
        let endPhi = atan((Float(point.x) - x0) / flen)
        let endTheta = atan((Float(point.y) - y0) / flen)
        
        phiDiff += Float(startPhi - endPhi)
        thetaDiff += Float(startTheta - endTheta)
        
        touchStartPoint = point
    }
    
    func touchEnd() {
        touchStartPoint = nil
        isTouching = false
    }
    
    func reset() {
        phiDiff = 0
        thetaDiff = 0
        phi = 0
        theta = 0
        phiDamp = 0
        thetaDamp = 0
    }
    
    func getRotationMatrix() -> GLKMatrix4 {
        
        if !isTouching {
            // Update from motion and damping
            phiDamp *= dampFactor
            thetaDamp *= dampFactor
            phi += phiDamp
            theta += thetaDamp
        } else {
            // Update from touch
            phi += phiDiff
            theta += thetaDiff
            phiDamp = phiDiff
            thetaDamp = thetaDiff
            phiDiff = 0
            thetaDiff = 0
        }
        
        theta = max(minTheta, min(theta, maxTheta))
        
        return phiThetaToRotationMatrix(phi, theta: theta)
    }
}

class CombinedMotionManager: RotationMatrixSource {
    private let coreMotionRotationSource: CoreMotionRotationSource
    private let touchRotationSource: TouchRotationSource
    
    private var lastCoreMotionRotationMatrix: GLKMatrix4?
    private var isRotating = false;
    
    
    func setRotation(_isRotating:Bool) {
        isRotating = _isRotating
    }
    
    init(sceneSize: CGSize, hfov: Float) {
        self.coreMotionRotationSource = CoreMotionRotationSource.Instance
        self.touchRotationSource = TouchRotationSource(sceneSize: sceneSize, hfov: hfov)
    }
    
    init(coreMotionRotationSource: CoreMotionRotationSource, touchRotationSource: TouchRotationSource) {
        self.coreMotionRotationSource = coreMotionRotationSource
        self.touchRotationSource = touchRotationSource
    }
    
    func touchStart(point: CGPoint) {
        touchRotationSource.touchStart(point)
    }
    
    func touchMove(point: CGPoint) {
        touchRotationSource.touchMove(point)
    }
    
    func touchEnd() {
        touchRotationSource.touchEnd()
    }
    
    func reset() {
        touchRotationSource.reset()
    }
    
    func setDirection(direction: Direction) {
        touchRotationSource.phi = direction.phi
        touchRotationSource.theta = direction.theta
    }
    
    func getDirection() -> Direction {
        return (phi: touchRotationSource.phi, theta: touchRotationSource.theta)
    }
    
    func getRotationMatrix() -> GLKMatrix4 {
        
        let coreMotionRotationMatrix = coreMotionRotationSource.getRotationMatrix()
        
        
        
        if !touchRotationSource.isTouching {
            // Update from motion and damping
            if let lastCoreMotionRotationMatrix = lastCoreMotionRotationMatrix {
                let diffRotationMatrix = GLKMatrix4Multiply(GLKMatrix4Invert(lastCoreMotionRotationMatrix, nil), coreMotionRotationMatrix)
                
                let diffRotationTheta = atan2(diffRotationMatrix.m21, diffRotationMatrix.m22)
                let diffRotationPhi = atan2(-diffRotationMatrix.m20,
                                            sqrt(diffRotationMatrix.m21 * diffRotationMatrix.m21 +
                                                diffRotationMatrix.m22 * diffRotationMatrix.m22))
                
                
//                if isRotating == true {
//                    
//                    if Defaults[.SessionGyro] == true {
//                        
//                        touchRotationSource.phi += diffRotationPhi
//                        touchRotationSource.theta += diffRotationTheta
//                        
//                        
//                    } else {
//                        touchRotationSource.phi += 0.003;
//                        touchRotationSource.theta = -1.5;
//                    }
//                }
                if Defaults[.SessionGyro] == true {
                    
                    touchRotationSource.phi += diffRotationPhi
                    touchRotationSource.theta += diffRotationTheta
                    
                    
                }
            }
        }
        
        lastCoreMotionRotationMatrix = coreMotionRotationMatrix
        
        return touchRotationSource.getRotationMatrix()
    }
}

private let queue = dispatch_queue_create("collection_view_cell", DISPATCH_QUEUE_SERIAL)

private class OverlayViewModel {
    
    let likeCount = MutableProperty<Int>(0)
    let liked = MutableProperty<Bool>(false)
    let textToggled = MutableProperty<Bool>(false)
    
    enum UploadStatus { case Offline, Uploading, Uploaded }
    let uploadStatus = MutableProperty<UploadStatus>(.Uploaded)
    
    var optographBox: ModelBox<Optograph>!
    var personBox:ModelBox<Person>!
    
    var optograph: Optograph!
    
    let isFollowed = MutableProperty<Bool>(false)
    let avatarImageUrl = MutableProperty<String>("")
    let displayName = MutableProperty<String>("")
    let locationID = MutableProperty<UUID?>("")
    var isMe = false
    
    
    func bind(optographID: UUID) {
        
        optographBox = Models.optographs[optographID]!
        personBox = Models.persons[optographBox.model.personID]!
        
        locationID.value = optographBox.model.locationID
        
        textToggled.value = false
        
        optographBox.producer.startWithNext { [weak self] optograph in
            self?.likeCount.value = optograph.starsCount
            self?.liked.value = optograph.isStarred
            
            if optograph.isPublished {
                self?.uploadStatus.value = .Uploaded
            } else if optograph.isUploading {
                self?.uploadStatus.value = .Uploading
            } else {
                self?.uploadStatus.value = .Offline
            }
        }
        
        isMe = SessionService.personID == optographBox.model.personID
        
        personBox.producer
            .skipRepeats()
            .startWithNext { [weak self] person in
                self?.displayName.value = person.displayName
                //                self?.userName.value = person.userName
                //                self?.text.value = person.text
                //                self?.postCount.value = person.optographsCount
                //                self?.followersCount.value = person.followersCount
                //                self?.followingCount.value = person.followedCount
                self?.avatarImageUrl.value = ImageURL("persons/\(person.ID)/\(person.avatarAssetID).jpg", width: 47, height: 47)
                self?.isFollowed.value = person.isFollowed
                
        }
    }
    
    func toggleFollow() {
        let person = personBox.model
        let followedBefore = person.isFollowed
        
        SignalProducer<Bool, ApiError>(value: followedBefore)
            .flatMap(.Latest) { followedBefore in
                followedBefore
                    ? ApiService<EmptyResponse>.delete("persons/\(person.ID)/follow")
                    : ApiService<EmptyResponse>.post("persons/\(person.ID)/follow", parameters: nil)
            }
            .on(
                started: { [weak self] in
                    self?.personBox.insertOrUpdate { box in
                        box.model.isFollowed = !followedBefore
                    }
                },
                failed: { [weak self] _ in
                    self?.personBox.insertOrUpdate { box in
                        box.model.isFollowed = followedBefore
                    }
                }
            )
            .start()
    }
    
    func toggleLike() {
        let starredBefore = liked.value
        let starsCountBefore = likeCount.value
        
        let optograph = optographBox.model
        
        SignalProducer<Bool, ApiError>(value: starredBefore)
            .flatMap(.Latest) { followedBefore in
                starredBefore
                    ? ApiService<EmptyResponse>.delete("optographs/\(optograph.ID)/star")
                    : ApiService<EmptyResponse>.post("optographs/\(optograph.ID)/star", parameters: nil)
            }
            .on(
                started: { [weak self] in
                    self?.optographBox.insertOrUpdate { box in
                        box.model.isStarred = !starredBefore
                        box.model.starsCount += starredBefore ? -1 : 1
                    }
                },
                failed: { [weak self] _ in
                    self?.optographBox.insertOrUpdate { box in
                        box.model.isStarred = starredBefore
                        box.model.starsCount = starsCountBefore
                    }
                }
            )
            .start()
    }
    
    func upload() {
        if !optographBox.model.isOnServer {
            let optograph = optographBox.model
            
            optographBox.update { box in
                box.model.isUploading = true
            }
            
            let postParameters = [
                "id": optograph.ID,
                "stitcher_version": StitcherVersion,
                "created_at": optograph.createdAt.toRFC3339String(),
                ]
            
            var putParameters: [String: AnyObject] = [
                "text": optograph.text,
                "is_private": optograph.isPrivate,
                "post_facebook": optograph.postFacebook,
                "post_twitter": optograph.postTwitter,
                "direction_phi": optograph.directionPhi,
                "direction_theta": optograph.directionTheta,
                ]
            if let locationID = optograph.locationID, location = Models.locations[locationID]?.model {
                putParameters["location"] = [
                    "latitude": location.latitude,
                    "longitude": location.longitude,
                    "text": location.text,
                    "country": location.country,
                    "country_short": location.countryShort,
                    "place": location.place,
                    "region": location.region,
                    "poi": location.POI,
                ]
            }
            
            SignalProducer<Bool, ApiError>(value: !optographBox.model.shareAlias.isEmpty)
                .flatMap(.Latest) { alreadyPosted -> SignalProducer<Void, ApiError> in
                    if alreadyPosted {
                        return SignalProducer(value: ())
                    } else {
                        return ApiService<OptographApiModel>.post("optographs", parameters: postParameters)
                            .on(next: { [weak self] optograph in
                                self?.optographBox.insertOrUpdate { box in
                                    box.model.shareAlias = optograph.shareAlias
                                }
                                })
                            .map { _ in () }
                    }
                }
                .flatMap(.Latest) {
                    ApiService<EmptyResponse>.put("optographs/\(optograph.ID)", parameters: putParameters)
                        .on(failed: { [weak self] _ in
                            self?.optographBox.update { box in
                                box.model.isUploading = false
                            }
                            })
                }
                .on(next: { [weak self] optograph in
                    self?.optographBox.insertOrUpdate { box in
                        box.model.isOnServer = true
                    }
                    })
                .startWithCompleted {
                    PipelineService.checkUploading()
            }
            
            
        } else {
            optographBox.insertOrUpdate { box in
                box.model.shouldBePublished = true
                box.model.isUploading = true
            }
            
            PipelineService.checkUploading()
        }
        
    }
}

class OptographCollectionViewCell: UICollectionViewCell{
    
    weak var uiHidden: MutableProperty<Bool>!
    
    private let viewModel = OverlayViewModel()
    weak var navigationController: NavigationController?
    
    weak var parentViewController: UIViewController?
    // subviews
    private let topElements = UIView()
    private let bottomElements = UIView()
    private let bottomBackgroundView = UIView()
    //private let loadingOverlayView = UIView()
    
    private var scnView: SCNView!
    
    //private let loadingIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
    
    private var touchStart: CGPoint?
    
    private enum LoadingStatus { case Nothing, Preview, Loaded }
    private let loadingStatus = MutableProperty<LoadingStatus>(.Nothing)
    
    private let whiteBackground = UIView()
    private let avatarImageView = UIImageView()
    private let locationTextView = UILabel()
    private let likeCountView = UILabel()
    private let personNameView = BoundingLabel()
    private let optionsButtonView = BoundingButton()
    private let likeButtonView = BoundingButton()
    private let blackSpace = UIView()
    let hiddenViewToBounce = UIView()
    
    let shareImageAsset = UIImageView()
    private let bouncingButton = UIButton()
    var pointX:CGFloat = 214.0
    var pointY:CGFloat = 260.0
    var phiDamp: Float = 0
    var dampFactor: Float = 0.9
    var thetaDamp: Float = 0
    var phi: Float = 0
    var theta: Float = Float(-M_PI_2)
    var isMe = false
    
    var optoId:UUID = ""
    
    var deleteCallback: (() -> ())?
    
    var hiddenGestureRecognizer:UIPanGestureRecognizer!
    var swipeView:UIScrollView?
    var collectionView:UICollectionView?
    var isShareOpen = MutableProperty<Bool>(false)
    
    var previewImage = UIImageView()
    
    var yellowView = UIView()
    let playerLayer = AVPlayerLayer()
    
    var video:AVPlayer? {
        didSet {
            self.playerLayer.player = video
//            NSNotificationCenter.defaultCenter().addObserverForName(AVPlayerItemDidPlayToEndTimeNotification, object: nil, queue: nil) { notification in
//                self.video?.seekToTime(kCMTimeZero)
//                self.video?.play()
//            }
        }
    }
    
    func setRotation (isRotating:Bool) {
        
        previewImage.hidden = false
        
        if let gyroVideo = self.video {
            if isRotating {
                print("playing")
                if gyroVideo.status == .ReadyToPlay {
                    previewImage.hidden = true
                    gyroVideo.play()
                }
            } else {
                print("pause")
                gyroVideo.pause()
            }
        } else {
            previewImage.hidden = false
        }
    }
    
    func loadPreviewImage() {
        previewImage.hidden = false
    }
    
    var id: Int = 0 {
        didSet {
            //
        }
    }
    var xCoordBegin:CGFloat = 0.0
    
    dynamic private func pushDetails() {
        
        let detailsViewController = DetailsTableViewController(optographId:optoId)
        detailsViewController.cellIndexpath = id
        navigationController?.pushViewController(detailsViewController, animated: true)
    }
    
    dynamic private func pushProfile() {
        
        let profilepage = ProfileCollectionViewController(personID: viewModel.optographBox.model.personID)
        profilepage.isProfileVisit = true
        navigationController?.pushViewController(profilepage, animated: true)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = UIColor(hex:0xffbc00)
        
        shareImageAsset.layer.cornerRadius = avatarImageView.frame.size.width / 2
        shareImageAsset.image = UIImage(named: "share_hidden_icn")
        contentView.addSubview(shareImageAsset)
        
        yellowView.backgroundColor = UIColor.blackColor()
        contentView.addSubview(yellowView)
        
//        loadingOverlayView.backgroundColor = .blackColor()
//        loadingOverlayView.hidden = false
//        contentView.addSubview(loadingOverlayView)
//        
//        loadingIndicatorView.frame = contentView.frame
//        loadingIndicatorView.startAnimating()
//        contentView.addSubview(loadingIndicatorView)
        
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.yellowView.layer.addSublayer(playerLayer)
        
        previewImage.frame = CGRect(origin: CGPointZero, size: frame.size)
        yellowView.addSubview(previewImage)
        
        whiteBackground.backgroundColor = UIColor(hex:0x595959).alpha(0.80)
        yellowView.addSubview(whiteBackground)
        
        blackSpace.backgroundColor = UIColor.blackColor()
        yellowView.addSubview(blackSpace)
        
        avatarImageView.image = UIImage(named: "avatar-placeholder")!
        avatarImageView.layer.cornerRadius = 25
        avatarImageView.layer.borderColor = UIColor(hex:0xffbc00).CGColor
        avatarImageView.layer.borderWidth = 2.0
        avatarImageView.backgroundColor = .whiteColor()
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(OptographCollectionViewCell.pushProfile)))
        whiteBackground.addSubview(avatarImageView)
        
        optionsButtonView.titleLabel?.font = UIFont.iconOfSize(21)
        optionsButtonView.setImage(UIImage(named:"follow_inactive"), forState: .Normal)
        optionsButtonView.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        optionsButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(followUser)))
        whiteBackground.addSubview(optionsButtonView)
        
        personNameView.font = UIFont.displayOfSize(15, withType: .Regular)
        personNameView.textColor = UIColor(0xffbc00)
        personNameView.userInteractionEnabled = true
        personNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.pushProfile)))
        whiteBackground.addSubview(personNameView)
        
        likeButtonView.addTarget(self, action: #selector(self.toggleStar), forControlEvents: [.TouchDown])
        likeButtonView.setImage(UIImage(named:"user_unlike_icn"), forState: .Normal)
        whiteBackground.addSubview(likeButtonView)
        
        locationTextView.font = UIFont.displayOfSize(11, withType: .Light)
        locationTextView.textColor = UIColor.whiteColor()
        whiteBackground.addSubview(locationTextView)
        
        likeCountView.font = UIFont.displayOfSize(11, withType: .Semibold)
        likeCountView.textColor = .whiteColor()
        likeCountView.textAlignment = .Right
        whiteBackground.addSubview(likeCountView)
        
        hiddenGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(OptographCollectionViewCell.handlePan(_:)))
        bouncingButton.addGestureRecognizer(hiddenGestureRecognizer)
        
        bouncingButton.addTarget(self, action: #selector(self.bouncingCell), forControlEvents:.TouchUpInside)
        bouncingButton.setImage(UIImage(named: "bouncing_button")!, forState: .Normal)
        yellowView.addSubview(bouncingButton)
        
        hiddenViewToBounce.backgroundColor = UIColor.clearColor()
        yellowView.addSubview(hiddenViewToBounce)
        
        hiddenViewToBounce.addGestureRecognizer(hiddenGestureRecognizer)
        hiddenViewToBounce.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.bouncingCell)))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        yellowView.fillSuperview()
        playerLayer.fillSuperview()
        
        blackSpace.anchorAndFillEdge(.Bottom, xPad: 0, yPad: 0, otherSize: 20)
        
        hiddenViewToBounce.anchorToEdge(.Left, padding: 10, width: 70, height: 100)
        //loadingOverlayView.anchorAndFillEdge(.Top, xPad: 0, yPad: 0, otherSize: contentView.frame.height - 70 - 20)
        
        whiteBackground.align(.AboveMatchingLeft, relativeTo: blackSpace, padding: 0, width: contentView.frame.width , height: 70)
        avatarImageView.anchorToEdge(.Left, padding: 20, width: 50, height: 50)
        personNameView.align(.ToTheRightCentered, relativeTo: avatarImageView, padding: 9.5, width: 100, height: 18)
        likeButtonView.anchorInCorner(.BottomRight, xPad: 16, yPad: 21, width: 24, height: 28)
        likeCountView.align(.ToTheLeftCentered, relativeTo: likeButtonView, padding: 10, width:20, height: 13)
        let followSizeWidth = UIImage(named:"follow_active")!.size.width
        let followSizeHeight = UIImage(named:"follow_active")!.size.height
        optionsButtonView.frame = CGRect(x: avatarImageView.frame.origin.x + 2 - (followSizeWidth / 2),y: avatarImageView.frame.origin.y + (avatarImageView.frame.height * 0.75) - (followSizeWidth / 2),width: followSizeWidth,height: followSizeHeight)
        shareImageAsset.anchorToEdge(.Left, padding: 10, width: avatarImageView.frame.size.width, height: avatarImageView.frame.size.width)
        bouncingButton.anchorToEdge(.Left, padding: 10, width: avatarImageView.frame.size.width, height: avatarImageView.frame.size.width)
        personNameView.align(.ToTheRightCentered, relativeTo: avatarImageView, padding: 9.5, width: 100, height: 18)
        locationTextView.text = ""
    }
    
    func bouncingCell() {
        UIView.animateWithDuration(0.1, animations: {
            self.yellowView.frame.origin.x = 60
            }, completion:{ finished in
                UIView.animateWithDuration(0.1, animations: {
                    self.yellowView.frame.origin.x = 0
                    }, completion:{ finished in
                        UIView.animateWithDuration(0.1, animations: {
                            self.yellowView.frame.origin.x = 35
                            }, completion:{ finished in
                                UIView.animateWithDuration(0.1, animations: {
                                    self.yellowView.frame.origin.x = 0
                                    }, completion:{ finished in
                                        UIView.animateWithDuration(0.1, animations: {
                                            self.yellowView.frame.origin.x = 15
                                            }, completion:{ finished in
                                                UIView.animateWithDuration(0.1, animations: {
                                                    self.yellowView.frame.origin.x = 5
                                                    }, completion:{ finished in
                                                        self.yellowView.frame.origin.x = 0
                                                })
                                        })
                                })
                        })
                })
        })
    }
    
    func handlePan(recognizer:UIPanGestureRecognizer) {
        
        //let translationX = recognizer.locationInView(contentView).x
        let velocity = recognizer.velocityInView(contentView)
        
        switch recognizer.state {
        case .Began:
            xCoordBegin = 0.0
        case .Changed:
            xCoordBegin += 4.0
            if velocity.x > 0 {
                if (yellowView.frame.origin.x <= 45) {
                    yellowView.frame.origin.x = xCoordBegin
                } else {
                    if !isShareOpen.value {
                        if (viewModel.uploadStatus.value == .Offline || viewModel.uploadStatus.value == .Uploading) {
                            let alert = UIAlertController(title:"Oops! Your 360 image is still uploading..", message: "Please try again later..", preferredStyle: .Alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in
                                self.xCoordBegin = 0.0
                                self.yellowView.frame.origin.x = 0
                                return
                            }))
                            self.navigationController!.presentViewController(alert, animated: true, completion: nil)
                        } else {
                            swipeView?.scrollRectToVisible(CGRect(x: 0,y: 0,width: contentView.frame.width,height: 100), animated: true)
                            isShareOpen.value = true
                        }
                    }
                }
            }
        case .Cancelled:
            print("cancelled")
        case .Ended:
            xCoordBegin = 0.0
            yellowView.frame.origin.x = 0
            if isShareOpen.value {
                isShareOpen.value = false
            }
            
        default: break
        }
    }
    
    func toggleStar() {
        //        if SessionService.isLoggedIn {
        //            viewModel.toggleLike()
        //        } else {
        //
        //            let loginOverlayViewController = LoginOverlayViewController(
        //                title: "Login to like this moment",
        //                successCallback: {
        //                    self.viewModel.toggleLike()
        //                },
        //                cancelCallback: { true },
        //                alwaysCallback: {
        //                    self.parentViewController!.tabController!.unlockUI()
        //                    self.parentViewController!.tabController!.showUI()
        //                }
        //            )
        //            parentViewController!.presentViewController(loginOverlayViewController, animated: true, completion: nil)
        //        }
        
        if SessionService.isLoggedIn {
            viewModel.toggleLike()
        } else {
            let alert = UIAlertController(title:"", message: "Please login to like this moment.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            self.navigationController!.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    func followUser() {
        
        if SessionService.isLoggedIn {
            viewModel.toggleFollow()
        } else {
            let alert = UIAlertController(title:"", message: "Please login to follow this user", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            self.navigationController!.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func bindModel(optographId:UUID) {
        
        viewModel.bind(optographId)
        viewModel.avatarImageUrl.producer.startWithNext{
            self.avatarImageView.kf_setImageWithURL(NSURL(string:$0)!)
        }
        
        isMe = viewModel.isMe
        personNameView.rac_text <~ viewModel.displayName
        
        viewModel.locationID.producer.startWithNext{
            
            if let locationID = $0 {
                let location = Models.locations[locationID]!.model
                self.locationTextView.text = "\(location.text), \(location.countryShort)"
                self.personNameView.align(.ToTheRightMatchingTop, relativeTo: self.avatarImageView, padding: 9.5, width: 100, height: 18)
                self.locationTextView.align(.ToTheRightMatchingBottom, relativeTo: self.avatarImageView, padding: 9.5, width: 200, height: 18)
                self.locationTextView.text = location.text
            } else {
                self.personNameView.align(.ToTheRightCentered, relativeTo: self.avatarImageView, padding: 9.5, width: 100, height: 18)
                self.locationTextView.text = ""
            }
        }
        likeButtonView.rac_hidden <~ viewModel.uploadStatus.producer.equalsTo(.Uploaded).map(negate)
        likeCountView.rac_hidden <~ viewModel.uploadStatus.producer.equalsTo(.Uploaded).map(negate)
        likeCountView.rac_text <~ viewModel.likeCount.producer.map { "\($0)" }
        
        viewModel.liked.producer.startWithNext { [weak self] liked in
            if let strongSelf = self {
                strongSelf.likeButtonView.setImage(liked ? UIImage(named:"liked_button") : UIImage(named:"user_unlike_icn"), forState: .Normal)
            }
        }
        if isMe {
            optionsButtonView.hidden = true
        } else {
            optionsButtonView.hidden = false
            viewModel.isFollowed.producer.startWithNext{
                $0 ? self.optionsButtonView.setImage(UIImage(named:"follow_active"), forState: .Normal) : self.optionsButtonView.setImage(UIImage(named:"follow_inactive"), forState: .Normal)
            }
        }
        
        viewModel.uploadStatus.producer.equalsTo(.Uploaded)
            .startWithNext { [weak self] isUploaded in
                
                if isUploaded {
//                    let url = TextureURL(optographId, side: .Left, size: (self?.contentView.frame.width)!, face: 0, x: 0, y: 0, d: 1)
//                    self?.previewImage.kf_setImageWithURL(NSURL(string: url)!)
                    let stringUrl = "http://s3-ap-southeast-1.amazonaws.com/resources.staging-iam360.io/textures/\(optographId)/frame1.jpg"
                    self?.previewImage.kf_setImageWithURL(NSURL(string: stringUrl)!)
                    
                } else {
                    //let url = TextureURL(optographId, side: .Left, size: 0, face: 0, x: 0, y: 0, d: 1)
                    let stringUrl = "http://s3-ap-southeast-1.amazonaws.com/resources.staging-iam360.io/textures/\(optographId)/frame1.jpg"
                    if let originalImage = KingfisherManager.sharedManager.cache.retrieveImageInDiskCacheForKey(stringUrl) {
                        dispatch_async(dispatch_get_main_queue()) {
                            self?.previewImage.image = originalImage.resized(.Width, value: (self?.contentView.frame.width)!)
                        }
                    }
                }
//                self?.loadingOverlayView.hidden = true
//                self?.loadingIndicatorView.stopAnimating()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        //NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
        logRetain()
    }
}

extension OptographCollectionViewCell: OptographOptions {
    dynamic func didTapOptions() {
        showOptions(viewModel.optographBox.model.ID, deleteCallback: deleteCallback)
    }
}