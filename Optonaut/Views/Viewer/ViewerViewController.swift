import UIKit
import QuartzCore
import SceneKit
import CoreMotion
import Device
import CoreGraphics
import Mixpanel
import ReactiveCocoa
import Crashlytics
import CardboardParams
import Async
import SwiftyUserDefaults
import Kingfisher
import SpriteKit

private let queue = dispatch_queue_create("viewer", DISPATCH_QUEUE_SERIAL)

class ViewerViewController: UIViewController, CubeRenderDelegateDelegate  {
    
    private let orientation: UIInterfaceOrientation
    private var optograph: Optograph?
    
    private var leftRenderDelegate: CubeRenderDelegate!
    private var rightRenderDelegate: CubeRenderDelegate!
    private var leftScnView: SCNView!
    private var rightScnView: SCNView!
    private let separatorLayer = CALayer()
    private var headset: CardboardParams
    private var screen: ScreenParams
    
    private var leftProgram: DistortionProgram!
    private var rightProgram: DistortionProgram!
    
    private var rotationDisposable: Disposable?
    
    private let settingsButtonView = BoundingButton()
    private var glassesSelectionView: GlassesSelectionView?
    private let leftLoadingView = UIActivityIndicatorView()
    private let rightLoadingView = UIActivityIndicatorView()
    
    private var leftCache: CubeImageCache?
    private var rightCache: CubeImageCache?
    
    var arrayOfOpto:NSArray = []
    var counter = 1
    var loadImage = MutableProperty<Bool>(false)
    var textureSize:CGFloat = 0.0
    
    
    //storytelling
    let storyPinLabel = UILabel()
    var countDown:Int = 2
    let cloudQuote = UIImageView()
    let diagonal = ViewWithDiagonalLine()
    private var lastElapsedTime = CACurrentMediaTime()
    var last_optographID:UUID = ""
    private var isPlaying: Bool = false
    private var isInsideStory: Bool = false
    var nodes:[StoryChildren] = []
    let fixedTextLabel = UILabel()
    let removeNode = UIButton()
    //
    
    required init(orientation: UIInterfaceOrientation, arrayOfoptograph:[UUID],selfOptograph:UUID,nodesData:[StoryChildren]) {
        
        self.arrayOfOpto = arrayOfoptograph
        self.orientation = orientation
        nodes = nodesData
        
        // Please set this to meaningful default values.
        
        switch UIDevice.currentDevice().deviceType {
        case .IPhone4S: screen = ScreenParams(device: .IPhone4S)
        case .IPhone5: screen = ScreenParams(device: .IPhone5)
        case .IPhone5C: screen = ScreenParams(device: .IPhone5C)
        case .IPhone5S: screen = ScreenParams(device: .IPhone5S)
        case .IPhone6: screen = ScreenParams(device: .IPhone6)
        case .IPhone6Plus: screen = ScreenParams(device: .IPhone6Plus)
        case .IPhone6S: screen = ScreenParams(device: .IPhone6S)
        case .IPhone6SPlus: screen = ScreenParams(device: .IPhone6SPlus)
        default: fatalError("device not supported")
        }
        
        headset = CardboardParams.fromBase64(Defaults[.SessionVRGlasses]).value!
        
        print("Headset: \(headset.vendor) \(headset.model)")
        
        let optograph = Models.optographs[selfOptograph]?.model
        self.optograph = optograph!
        
        textureSize = getTextureWidth(UIScreen.mainScreen().bounds.height / 2, hfov: 65) // 90 is a guess. A better value might be needed
        
        self.leftCache = CubeImageCache(optographID: optograph!.ID, side: .Left, textureSize: textureSize)
        self.rightCache = CubeImageCache(optographID: optograph!.ID, side: .Right, textureSize: textureSize)
        
        loadImage.value = true
        
        super.init(nibName: nil, bundle: nil)
    }
    
    func initiateViewer() {
        
        if self.arrayOfOpto.count > 1 {
            var optographId_:UUID = ""
            
            clearImages()
            createField()
            
            if counter == self.arrayOfOpto.count - 1 {
                optographId_ = self.arrayOfOpto[counter] as! UUID
                counter = 0
            } else {
                optographId_ = self.arrayOfOpto[counter] as! UUID
                counter += 1
            }
            
            let optograph = Models.optographs[optographId_]?.model
            self.optograph = optograph!
            
            print("counter >>",counter)
            print("optograph details",optograph!)
            
            self.leftCache = CubeImageCache(optographID: optograph!.ID, side: .Left, textureSize: textureSize)
            self.rightCache = CubeImageCache(optographID: optograph!.ID, side: .Right, textureSize: textureSize)
            
            loadImage.value = true
        }
    }
    
    //storytelling delegate methods
    
    func showText(nodeObject: StorytellingObject){
        let nameArray = nodeObject.optographID.componentsSeparatedByString(",")
        
        dispatch_async(dispatch_get_main_queue(), {
            self.storyPinLabel.text = nameArray[0]
            self.storyPinLabel.textColor = UIColor.blackColor()
            self.storyPinLabel.font = UIFont(name: "MerriweatherLight", size: 18.0)
            self.storyPinLabel.sizeToFit()
            self.storyPinLabel.frame = CGRect(x : 0, y: 0, width: self.storyPinLabel.frame.size.width + 40, height: self.storyPinLabel.frame.size.height + 30)
            self.storyPinLabel.backgroundColor = UIColor.clearColor()
            self.storyPinLabel.center = CGPoint(x: self.view.center.x + 50, y: self.view.center.y - 50)
            self.storyPinLabel.backgroundColor = UIColor.whiteColor()
            self.storyPinLabel.textAlignment = NSTextAlignment.Center
            self.diagonal.frame = CGRectMake(0, 0, self.storyPinLabel.frame.size.width/2, 30.0)
            self.diagonal.center = CGPoint(x: self.storyPinLabel.center.x, y: self.storyPinLabel.frame.origin.y + self.storyPinLabel.frame.size.height + 10.0)
            self.diagonal.hidden = false
            
            self.view.addSubview(self.storyPinLabel)
        })
    }
    
    func isInButtonCamera(inFrustrum: Bool){
        if !inFrustrum{
            dispatch_async(dispatch_get_main_queue(), {
                self.removeNode.hidden = true
            })
        }
    }
    
    func didEnterFrustrum(nodeObject: StorytellingObject, inFrustrum: Bool){
        if !inFrustrum {
            countDown = 2
            dispatch_async(dispatch_get_main_queue(), {
                self.storyPinLabel.backgroundColor = UIColor.clearColor()
                self.cloudQuote.hidden = true
                self.diagonal.hidden = true
                self.storyPinLabel.removeFromSuperview()
            })
            return
        }
        
        
        let mediaTime = CACurrentMediaTime()
        var timeDiff = mediaTime - lastElapsedTime
        
        if (last_optographID == nodeObject.optographID) {
            
            // reset if difference is above 3 seconds
            if timeDiff > 3.0 {
                countDown = 2
                timeDiff = 0.0
                lastElapsedTime = mediaTime
            }
            
            
            let nameArray = nodeObject.optographID.componentsSeparatedByString(",")
            
            if nameArray[1] == "TXT" {
                self.showText(nodeObject)
                return
            }
            
            // per second countdown
            if timeDiff > 1.0  {
                countDown -= 1
                lastElapsedTime = mediaTime
            }
            
            if countDown == 0 {
                // reset countdown
                countDown = 2
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.storyPinLabel.text = ""
                    
                    self.isPlaying = false
                })
                
                isInsideStory = true
                
                if nameArray[1] == "NAV" || nameArray[1] == "Image"{
                    //self.showOptograph(nodeObject)
                }
            }
        } else{ // this is a new id
            last_optographID = nodeObject.optographID
        }
    }
//    func showOptograph(nodeObject: StorytellingObject){
//        let nameArray = nodeObject.optographID.componentsSeparatedByString(",")
//        if nameArray[0] == self.optograph?.ID{
//            dispatch_async(dispatch_get_main_queue(), {
//                let cubeImageCache = self.imageCache.getStory(self.optographID, side: .Left)
//                self.setCubeImageCache(cubeImageCache)
//                
//                self.leftRenderDelegate.centerCameraPosition()
//                self.leftRenderDelegate.removeAllNodes(nameArray[0])
//                self.leftRenderDelegate.removeMarkers()
//                
//                self.rightRenderDelegate.centerCameraPosition()
//                self.rightRenderDelegate.removeAllNodes(nameArray[0])
//                self.rightRenderDelegate.removeMarkers()
//                
//                
//                for node in self.nodes {
//                    let objectPosition = node.objectPosition.characters.split{$0 == ","}.map(String.init)
//                    let objectRotation = node.objectRotation.characters.split{$0 == ","}.map(String.init)
//                    
//                    if objectPosition.count >= 2{
//                        
//                        let nodeItem = StorytellingObject()
//                        
//                        let nodeTranslation = SCNVector3Make(Float(objectPosition[0])!, Float(objectPosition[1])!, Float(objectPosition[2])!)
//                        let nodeRotation = SCNVector3Make(Float(objectRotation[0])!, Float(objectRotation[1])!, Float(objectRotation[2])!)
//                        
//                        nodeItem.objectRotation = nodeRotation
//                        nodeItem.objectVector3 = nodeTranslation
//                        nodeItem.objectType = node.mediaType
//                        
//                        if node.mediaType == "MUS"{
//                            nodeItem.optographID = node.objectMediaFileUrl
//                        }
//                            
//                        else if node.mediaType == "NAV"{
//                            nodeItem.optographID = node.mediaAdditionalData
//                        }
//                        
//                        print("node id: \(nodeItem.optographID)")
//                        
//                        self.leftRenderDelegate.addNodeFromServer(nodeItem)
//                        self.rightRenderDelegate.addNodeFromServer(nodeItem)
//                        
//                    }
//                }
//            })
//        } else {
//            dispatch_async(dispatch_get_main_queue(), {
//                let nameArray = nodeObject.optographID.componentsSeparatedByString(",")
//                
//                let cubeImageCache = self.imageCache.getStory(nameArray[0], side: .Left)
//                self.setCubeImageCache(cubeImageCache)
//                
//                self.leftRenderDelegate.removeMarkers()
//                self.leftRenderDelegate.centerCameraPosition()
//                
//                self.rightRenderDelegate.removeMarkers()
//                self.rightRenderDelegate.centerCameraPosition()
//                
//                
//                self.rightRenderDelegate.removeAllNodes(nodeObject.optographID)
//                self.rightRenderDelegate.addBackPin((self.optograph?.ID)!)
//                
//                self.leftRenderDelegate.removeAllNodes(nodeObject.optographID)
//                self.leftRenderDelegate.addBackPin((self.optograph?.ID)!)
//                
//            })
//        }
//    }
    
    func addVectorAndRotation(vector: SCNVector3, rotation: SCNVector3){
        
    }
    
    func createField() {
        createRenderDelegates()
        applyDistortionShader()
    }
    func clearImages() {
        leftCache!.dispose()
        rightCache!.dispose()
        leftRenderDelegate.dispose()
        rightRenderDelegate.dispose()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
    private func createRenderDelegates() {
        InvertableHeadTrackerRotationSource.InvertableInstance.inverted = orientation == .LandscapeLeft
        
        let isStory = nodes.count > 0 ? true : false
        
        leftRenderDelegate = CubeRenderDelegate(rotationMatrixSource: InvertableHeadTrackerRotationSource.InvertableInstance, fov: leftProgram.fov, cameraOffset: Float(-0.2), cubeFaceCount: 2, autoDispose: false,isStory:isStory)
        leftRenderDelegate.scnView = leftScnView
        rightRenderDelegate = CubeRenderDelegate(rotationMatrixSource: InvertableHeadTrackerRotationSource.InvertableInstance, fov: rightProgram.fov, cameraOffset: Float(0.2), cubeFaceCount: 2, autoDispose: false,isStory:isStory)
        rightRenderDelegate.scnView = rightScnView
        
        leftScnView.scene = leftRenderDelegate.scene
        leftScnView.delegate = leftRenderDelegate
        
        rightScnView.scene = rightRenderDelegate.scene
        rightScnView.delegate = rightRenderDelegate
        
        
        leftRenderDelegate.delegate = self
        rightRenderDelegate.delegate = self
    }
    
    private func applyDistortionShader() {
        leftScnView.technique = leftProgram.technique
        rightScnView.technique = rightProgram.technique
        leftRenderDelegate.fov = leftProgram.fov
        rightRenderDelegate.fov = rightProgram.fov
    }
    
    private func loadDistortionShader() {
        if headset.vendor.containsString("Zeiss") && headset.model == "VR ONE" {
            leftProgram = VROneDistortionProgram(isLeft: true)
            rightProgram = VROneDistortionProgram(isLeft: false)
        } else {
            if leftProgram == nil || leftProgram is VROneDistortionProgram {
                leftProgram = CardboardDistortionProgram(params: headset, screen: screen, eye: Eye.Left)
                rightProgram = CardboardDistortionProgram(params: headset, screen: screen, eye: Eye.Right)
            } else {
                leftProgram.setParameters(headset, screen: screen, eye: .Left)
                rightProgram.setParameters(headset, screen: screen, eye: .Right)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let width = view.frame.width
        let height = view.frame.height
        
        leftScnView = ViewerViewController.createScnView(CGRect(x: 0, y: 0, width: width, height: height / 2))
        rightScnView = ViewerViewController.createScnView(CGRect(x: 0, y: height / 2, width: width, height: height / 2))
        
        loadDistortionShader()
        createRenderDelegates()
        applyDistortionShader()
        
        view.addSubview(rightScnView)
        view.addSubview(leftScnView)
        
        separatorLayer.backgroundColor = UIColor.whiteColor().CGColor
        separatorLayer.frame = CGRect(x: 50, y: view.frame.height / 2 - 2, width: view.frame.width - 50, height: 4)
        view.layer.addSublayer(separatorLayer)
        
        leftLoadingView.activityIndicatorViewStyle = .WhiteLarge
        leftLoadingView.startAnimating()
        leftLoadingView.hidesWhenStopped = true
        leftLoadingView.frame = CGRect(x: view.frame.width / 2 - 20, y: view.frame.height / 4 - 20, width: 40, height: 40)
        view.addSubview(leftLoadingView)
        
        rightLoadingView.activityIndicatorViewStyle = .WhiteLarge
        rightLoadingView.startAnimating()
        rightLoadingView.hidesWhenStopped = true
        rightLoadingView.frame = CGRect(x: view.frame.width / 2 - 20, y: view.frame.height * 3 / 4 - 20, width: 40, height: 40)
        view.addSubview(rightLoadingView)
        
        settingsButtonView.frame = CGRect(x: 10, y: view.frame.height / 2 - 15, width: 30, height: 30)
        settingsButtonView.setTitle(String.iconWithName(.Settings), forState: .Normal)
        settingsButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        settingsButtonView.titleLabel?.font = UIFont.iconOfSize(20)
        //settingsButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ViewerViewController.showGlassesSelection)))
        settingsButtonView.addTarget(self, action: #selector(ViewerViewController.showGlassesSelection), forControlEvents: [.TouchDown])
        view.addSubview(settingsButtonView)
        
        if case .LandscapeLeft = orientation {
            view.transform = CGAffineTransformRotate(view.transform, CGFloat(M_PI))
        }
        
        if !Defaults[.SessionVRGlassesSelected] {
            showGlassesSelection()
        }
        
        let tapLeftGesture = UITapGestureRecognizer(target: self, action: #selector(initiateViewer))
        leftScnView.addGestureRecognizer(tapLeftGesture)
        
        let tapRightGesture = UITapGestureRecognizer(target: self, action: #selector(initiateViewer))
        rightScnView.addGestureRecognizer(tapRightGesture)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.Viewer")

        navigationController?.setNavigationBarHidden(true, animated: false)
        ScreenService.sharedInstance.max()
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.None)
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        var popActivated = false // needed when viewer was opened without rotation
        InvertableHeadTrackerRotationSource.InvertableInstance.start()
        RotationService.sharedInstance.rotationEnable()
        
        rotationDisposable = RotationService.sharedInstance.rotationSignal?
            .observeNext { [weak self] orientation in
                switch orientation {
                case .Portrait:
                    if popActivated {
                        dispatch_async(dispatch_get_main_queue()) {
                            self?.navigationController?.popViewControllerAnimated(false)
                        }
                        popActivated = false
                    }
                default:
                    popActivated = true
                }
            }
        
        loadImage.producer.startWithNext{ val in
            if val {
                
                let leftImageCallback = { [weak self] (image: SKTexture, index: CubeImageCache.Index) -> Void in
                    dispatch_async(dispatch_get_main_queue()) {
                        self?.leftRenderDelegate.setTexture(image, forIndex: index)
                        self?.leftLoadingView.stopAnimating()
                    }
                }
                
                self.leftRenderDelegate.nodeEnterScene = { [weak self] index in
                    dispatch_async(queue) {
                        self?.leftLoadingView.startAnimating()
                        self?.leftCache!.get(index, callback: leftImageCallback)
                    }
                }
                
                self.leftRenderDelegate.nodeLeaveScene = { [weak self] index in
                    dispatch_async(queue) { [weak self] in
                        self?.leftCache!.forget(index)
                    }
                }
                
                let rightImageCallback = { [weak self] (image: SKTexture, index: CubeImageCache.Index) -> Void in
                    dispatch_async(dispatch_get_main_queue()) {
                        self?.rightRenderDelegate.setTexture(image, forIndex: index)
                        self?.rightLoadingView.stopAnimating()
                    }
                }
                
                self.rightRenderDelegate.nodeEnterScene = { [weak self] index in
                    dispatch_async(queue) {
                        self?.rightLoadingView.startAnimating()
                        self?.rightCache!.get(index, callback: rightImageCallback)
                    }
                }
                
                self.rightRenderDelegate.nodeLeaveScene = { [weak self] index in
                    dispatch_async(queue) { [weak self] in
                        self?.rightCache!.forget(index)
                    }
                }
                
                self.rightRenderDelegate.requestAll()
                self.leftRenderDelegate.requestAll()
            }
        }
        
        for node in nodes {
            let objectPosition = node.objectPosition.characters.split{$0 == ","}.map(String.init)
            let objectRotation = node.objectRotation.characters.split{$0 == ","}.map(String.init)
            
            if node.mediaType == "FXTXT"{
                
                print("MEDIATYPE: FXTXT")
                
                dispatch_async(dispatch_get_main_queue(), {
                    
                    
                    self.fixedTextLabel.text = node.mediaAdditionalData
                    self.fixedTextLabel.textColor = UIColor.blackColor()
                    self.fixedTextLabel.font = UIFont(name: "BigNoodleTitling", size: 22.0)
                    self.fixedTextLabel.sizeToFit()
                    self.fixedTextLabel.frame = CGRect(x: 10.0, y: self.view.frame.size.height - 135.0, width: self.fixedTextLabel.frame.size.width + 5.0, height: self.fixedTextLabel.frame.size.height + 5.0)
                    self.fixedTextLabel.backgroundColor = UIColor(0xffbc00)
                    self.fixedTextLabel.textAlignment = NSTextAlignment.Center
                    
                    self.view.addSubview(self.fixedTextLabel)
                    
                    self.removeNode.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
                    self.removeNode.backgroundColor = UIColor.blackColor()
                    self.removeNode.center = CGPoint(x: self.view.center.x - 10, y: self.view.center.y - 10)
                    self.removeNode.setImage(UIImage(named: "close_icn"), forState: UIControlState.Normal)
                    //self.removeNode.addTarget(self, action: #selector(self.removePin), forControlEvents: UIControlEvents.TouchUpInside)
                    self.removeNode.hidden = true
                    self.view.addSubview(self.removeNode)
                })
            } else if node.mediaType == "MUS"{
                
                let url = NSURL(string: "https://bucket.dscvr.com" + node.objectMediaFileUrl)
                
//                if let returnPath:String = self.imageCache.insertStoryFile(url, file: nil, fileName: node.objectMediaFilename) {
//                    print(">>>>>>",returnPath)
//                    
//                    if returnPath != "" {
//                        print(returnPath)
//                        self?.playerItem = AVPlayerItem(URL: NSURL(fileURLWithPath: returnPath))
//                        self?.player = AVPlayer(playerItem: self!.playerItem!)
//                        self?.player?.rate = 1.0
//                        self?.player?.volume = 1.0
//                        self?.player!.play()
//                        
//                        NSNotificationCenter.defaultCenter().addObserver(self!, selector: #selector(self?.playerItemDidReachEnd), name: AVPlayerItemDidPlayToEndTimeNotification, object: self?.player!.currentItem)
//                    } else {
//                        self?.mp3Timer = NSTimer.scheduledTimerWithTimeInterval(5, target: self!, selector: #selector(self?.checkMp3), userInfo: ["FileUrl":"https://bucket.dscvr.com" + node.objectMediaFileUrl,"FileName":node.objectMediaFilename], repeats: true)
//                    }
//                }
            } else {
                if objectPosition.count >= 2{
                    let nodeItem = StorytellingObject()
                    
                    let nodeTranslation = SCNVector3Make(Float(objectPosition[0])!, Float(objectPosition[1])!, Float(objectPosition[2])!)
                    let nodeRotation = SCNVector3Make(Float(objectRotation[0])!, Float(objectRotation[1])!, Float(objectRotation[2])!)
                    
                    nodeItem.objectRotation = nodeRotation
                    nodeItem.objectVector3 = nodeTranslation
                    nodeItem.optographID = node.mediaAdditionalData
                    nodeItem.objectType = node.mediaType
                    
                    self.leftRenderDelegate.addNodeFromServer(nodeItem)
                    self.rightRenderDelegate.addNodeFromServer(nodeItem)
                }
                
            }
        }
    }
    
    func setViewerParameters(headset: CardboardParams) {
        self.headset = headset
        
        loadDistortionShader()
        applyDistortionShader()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Mixpanel.sharedInstance().track("View.Viewer", properties: ["optograph_id": optograph!.ID, "optograph_description" : optograph!.text])
        
        rotationDisposable?.dispose()
        RotationService.sharedInstance.rotationDisable()
        InvertableHeadTrackerRotationSource.InvertableInstance.stop()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        applyDistortionShader()
        tabController!.disableScrollView()
    }
    
    override func viewWillDisappear(animated: Bool) {
        leftCache!.dispose()
        rightCache!.dispose()
        leftRenderDelegate.dispose()
        rightRenderDelegate.dispose()
        
        leftRenderDelegate.reset()
        rightRenderDelegate.reset()
        
        tabBarController?.tabBar.hidden = false
        navigationController?.setNavigationBarHidden(false, animated: false)
        ScreenService.sharedInstance.reset()
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.None)
        UIApplication.sharedApplication().idleTimerDisabled = false
        
        super.viewWillDisappear(animated)
    }
    
    private static func createScnView(frame: CGRect) -> SCNView {
        var scnView: SCNView
        if #available(iOS 9.0, *) {
            scnView = SCNView(frame: frame, options: [SCNPreferredRenderingAPIKey: SCNRenderingAPI.OpenGLES2.rawValue])
        } else {
            scnView = SCNView(frame: frame)
        }
        
        scnView.backgroundColor = .blackColor()
        scnView.playing = true
        
        return scnView
    }
    
    func showGlassesSelection() {
        glassesSelectionView = GlassesSelectionView()
        glassesSelectionView!.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
        glassesSelectionView!.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        glassesSelectionView!.glasses = CardboardParams.fromBase64(Defaults[.SessionVRGlasses]).value!.model
        
        glassesSelectionView!.closeCallback = { [weak self] in
            Defaults[.SessionVRGlassesSelected] = true
            self?.glassesSelectionView?.removeFromSuperview()
        }
        
        glassesSelectionView!.paramsCallback = { [weak self] params in
            Defaults[.SessionVRGlassesSelected] = true
            self?.setViewerParameters(params)
        }
        
        view.addSubview(glassesSelectionView!)
    }
}

private class GlassesSelectionView: UIView {
    
    private let blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .Dark)
        return UIVisualEffectView(effect: blurEffect)
    }()
    
    private let cancelButtonView = UIButton()
    private let titleTextView = UILabel()
    private let glassesIconView = UILabel()
    private let glassesTextView = UILabel()
    private let qrcodeIconView = UILabel()
    private let qrcodeTextView = UILabel()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let loadingIndicatorView = UIActivityIndicatorView()
    
    private var loading: Bool = false
    
    var closeCallback: (() -> ())?
    var paramsCallback: (CardboardParams -> ())?
    
    var captureSession: AVCaptureSession?
    var code: String?
    
    var glasses: String? {
        didSet {
            glassesTextView.text = glasses
        }
    }
    
    init () {
        super.init(frame: CGRectZero)
        
        addSubview(blurView)
        
        cancelButtonView.setTitle(String.iconWithName(.Cancel), forState: .Normal)
        cancelButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        cancelButtonView.titleLabel?.font = UIFont.iconOfSize(20)
        cancelButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(GlassesSelectionView.cancel)))
        //cancelButtonView.addTarget(self, action: #selector(GlassesSelectionView.cancel), forControlEvents: [.TouchDown])
        addSubview(cancelButtonView)
        
        titleTextView.text = "Choose your VR glasses"
        titleTextView.textColor = .whiteColor()
        titleTextView.textAlignment = .Center
        titleTextView.font = UIFont.displayOfSize(35, withType: .Thin)
        addSubview(titleTextView)
        
        glassesIconView.text = String.iconWithName(.Cardboard)
        glassesIconView.textColor = .whiteColor()
        glassesIconView.textAlignment = .Center
        glassesIconView.font = UIFont.iconOfSize(73)
        glassesIconView.userInteractionEnabled = true
        glassesIconView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(GlassesSelectionView.cancel)))
        addSubview(glassesIconView)
        
        glassesTextView.font = UIFont.displayOfSize(15, withType: .Semibold)
        glassesTextView.textColor = .whiteColor()
        glassesTextView.textAlignment = .Center
        glassesTextView.userInteractionEnabled = true
        glassesTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(GlassesSelectionView.cancel)))
        addSubview(glassesTextView)
        
        qrcodeIconView.text = String.iconWithName(.Qrcode)
        qrcodeIconView.font = UIFont.iconOfSize(50)
        qrcodeIconView.textColor = .whiteColor()
        qrcodeIconView.textAlignment = .Center
        qrcodeIconView.userInteractionEnabled = true
        qrcodeIconView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(GlassesSelectionView.scan)))
        addSubview(qrcodeIconView)
        
        qrcodeTextView.font = UIFont.displayOfSize(15, withType: .Semibold)
        qrcodeTextView.textColor = .whiteColor()
        qrcodeTextView.text = "Scan QR code"
        qrcodeTextView.textAlignment = .Center
        qrcodeTextView.userInteractionEnabled = true
        qrcodeTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(GlassesSelectionView.scan)))
        addSubview(qrcodeTextView)
        
        loadingIndicatorView.activityIndicatorViewStyle = .WhiteLarge
        addSubview(loadingIndicatorView)
        
        Mixpanel.sharedInstance().track("View.CardboardSelection")
    }
    
    deinit {
        logRetain()
    }
    
    private func updateLoading(loading: Bool) {
        titleTextView.hidden = loading
        glassesIconView.hidden = loading
        glassesTextView.hidden = loading
        qrcodeIconView.hidden = loading
        qrcodeTextView.hidden = loading
        previewLayer?.hidden = loading
        loadingIndicatorView.hidden = !loading
        
        if loading {
            loadingIndicatorView.startAnimating()
        } else {
            loadingIndicatorView.stopAnimating()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private override func layoutSubviews() {
        blurView.frame = bounds
        
        cancelButtonView.frame = CGRect(x: bounds.width - 50, y: 20, width: 30, height: 30)
        
        titleTextView.frame = CGRect(x: 0, y: bounds.height * 0.25 - 19, width: bounds.width, height: 38)
        
        glassesIconView.frame = CGRect(x: bounds.width * 0.37 - 37, y: bounds.height * 0.5, width: 74, height: 50)
        glassesTextView.frame = CGRect(x: bounds.width * 0.37 - 100, y: bounds.height * 0.5 + 70, width: 200, height: 20)
        
        qrcodeIconView.frame = CGRect(x: bounds.width * 0.63 - 37, y: bounds.height * 0.5, width: 74, height: 50)
        qrcodeTextView.frame = CGRect(x: bounds.width * 0.63 - 100, y: bounds.height * 0.5 + 70, width: 200, height: 20)
        
        loadingIndicatorView.frame = CGRect(x: bounds.width * 0.5 - 20, y: bounds.height * 0.5 - 20, width: 40, height: 40)
        
        super.layoutSubviews()
        
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        let videoCaptureDevice: AVCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        try! videoCaptureDevice.lockForConfiguration()
        videoCaptureDevice.focusMode = .ContinuousAutoFocus
        videoCaptureDevice.unlockForConfiguration()
        
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            return
        }
        
        if captureSession!.canAddInput(videoInput) {
            captureSession!.addInput(videoInput)
        } else {
            print("Could not add video input")
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession!.canAddOutput(metadataOutput) {
            captureSession!.addOutput(metadataOutput)
            
            let queue = dispatch_queue_create("qr_scan_queue", DISPATCH_QUEUE_SERIAL)
            metadataOutput.setMetadataObjectsDelegate(self, queue: queue)
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeDataMatrixCode]
        } else {
            print("Could not add metadata output")
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer!.transform = CATransform3DMakeRotation(CGFloat(-M_PI_2), 0, 0, 1)
        previewLayer!.frame = CGRect(x: 70, y: 0, width: bounds.width - 150, height: bounds.height)
        layer.addSublayer(previewLayer!)
        
        captureSession!.startRunning()
    }
    
    dynamic func cancel() {
        captureSession?.stopRunning()
        closeCallback?()
    }
    
    dynamic func scan() {
        setupCamera()
    }
}

extension GlassesSelectionView: AVCaptureMetadataOutputObjectsDelegate {
    dynamic func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        if loading {
            return
        }
        
        for metadata in metadataObjects {
            let readableObject = metadata as! AVMetadataMachineReadableCodeObject
            let code = readableObject.stringValue
            
            if !code.isEmpty {
                
                loading = true
                captureSession?.stopRunning()
                
                Async.main { [weak self] in
                    self?.updateLoading(true)
                }
                
                let shortUrl = code.containsString("http://") ? code : "http://\(code)"
                
                CardboardParams.fromUrl(shortUrl) { [weak self] result in
                    
                    switch result {
                    case let .Success(params):
                        Async.main {
                            Defaults[.SessionVRGlasses] = params.compressedRepresentation.base64EncodedStringWithOptions([])
                            
                            let cardboardDescription = "\(params.vendor) \(params.model)"
                            Mixpanel.sharedInstance().track("View.CardboardSelection.Scanned", properties: ["cardboard": cardboardDescription, "url" : shortUrl])
                            Mixpanel.sharedInstance().people.set(["Last scanned Cardboard": cardboardDescription])
                            self?.paramsCallback?(params)
                            self?.cancel()
                        }
                    case let .Failure(error):
                        print(error)
                        self?.loading = false
                        self?.captureSession?.startRunning()
                        
                        Async.main { [weak self] in
                            self?.updateLoading(false)
                        }
                    }
                    
                }
            }
        }
    }
}