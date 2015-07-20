import UIKit
import QuartzCore
import SceneKit
import CoreMotion
import CoreGraphics

class ViewerViewController: UIViewController  {
    
    let orientation: UIInterfaceOrientation
    
    let motionManager = CMMotionManager()
    var leftCameraNode: SCNNode!
    var rightCameraNode: SCNNode!
    var leftScnView: SCNView!
    var rightScnView: SCNView!
    var leftScene: SCNScene!
    var rightScene: SCNScene!
    
    var originalBrightness: CGFloat!
    var enableDistortion = false
    
    required init(orientation: UIInterfaceOrientation) {
        self.orientation = orientation
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        orientation = .Unknown
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        leftScene = SCNScene()
        rightScene = SCNScene()
        
        let camera = SCNCamera()
        camera.zNear = 0.01
        camera.zFar = 10000
        
        camera.xFov = 65
        camera.yFov = 65 * Double(view.bounds.width / 2 / view.bounds.height)
        
        leftCameraNode = SCNNode()
        leftCameraNode.camera = camera
        leftCameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        leftScene.rootNode.addChildNode(leftCameraNode)
        
        rightCameraNode = SCNNode()
        rightCameraNode.camera = camera
        rightCameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        rightScene.rootNode.addChildNode(rightCameraNode)
        
        let leftSphereGeometry = SCNSphere(radius: 5.0)
        leftSphereGeometry.firstMaterial?.diffuse.contents = UIImage(named: "left_large")
        leftSphereGeometry.firstMaterial?.doubleSided = true
        let leftSphereNode = SCNNode(geometry: leftSphereGeometry)
        leftScene.rootNode.addChildNode(leftSphereNode)
        
        let rightSphereGeometry = SCNSphere(radius: 5.0)
        rightSphereGeometry.firstMaterial?.diffuse.contents = UIImage(named: "right_large")
        rightSphereGeometry.firstMaterial?.doubleSided = true
        let rightSphereNode = SCNNode(geometry: rightSphereGeometry)
        rightScene.rootNode.addChildNode(rightSphereNode)
        
        let width = view.bounds.width
        let height = view.bounds.height
        
        leftScnView = SCNView()
        leftScnView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
        leftScnView.frame = CGRect(x: 0, y: 0, width: width, height: height / 2)
        
        leftScnView.backgroundColor = .blackColor()
        leftScnView.scene = leftScene
        leftScnView.playing = true
        leftScnView.delegate = self
        
        if enableDistortion {
//            leftScnView.technique = createDistortionTechnique("displacement_left")
        }
        view.addSubview(leftScnView)
        
        rightScnView = SCNView()
        rightScnView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
        rightScnView.frame = CGRect(x: 0, y: height / 2, width: width, height: height / 2)
        
        rightScnView.backgroundColor = .blackColor()
        rightScnView.scene = rightScene
        rightScnView.playing = true
        rightScnView.delegate = self
        
        if enableDistortion {
//            rightScnView.technique = createDistortionTechnique("displacement_right")
        }
        
        view.addSubview(rightScnView)
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates()
        
        var popActivated = false // needed when viewer was opened without rotation
        motionManager.accelerometerUpdateInterval = 0.3
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: { accelerometerData, error in
            if let accelerometerData = accelerometerData {
                let x = accelerometerData.acceleration.x
                let y = accelerometerData.acceleration.y
                if !popActivated && abs(x) > abs(y) + 0.5 {
                    popActivated = true
                }
                if popActivated && abs(y) > abs(x) + 0.5 {
                    self.navigationController?.popViewControllerAnimated(false)
                }
            }
        })
    }
    
//    func createDistortionTechnique(name: String) -> SCNTechnique {
//        let data = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource(name, ofType: "json")!)
//        let json = NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary
//        let technique = SCNTechnique(dictionary: json as [NSObject : AnyObject])
//        
//        return technique!
//    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        tabBarController?.tabBar.hidden = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        originalBrightness = UIScreen.mainScreen().brightness
        UIScreen.mainScreen().brightness = 1
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.None)
        UIApplication.sharedApplication().idleTimerDisabled = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        tabBarController?.tabBar.hidden = false
        navigationController?.setNavigationBarHidden(false, animated: false)
        UIScreen.mainScreen().brightness = originalBrightness
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.None)
        UIApplication.sharedApplication().idleTimerDisabled = false
        
        motionManager.stopAccelerometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        
        super.viewWillDisappear(animated)
    }
    
}

// MARK: - SCNSceneRendererDelegate
extension ViewerViewController: SCNSceneRendererDelegate {
    
    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        if let motion = self.motionManager.deviceMotion {
            let x = -Float(motion.attitude.roll) - Float(M_PI_2)
            let y = Float(motion.attitude.yaw)
            let z = -Float(motion.attitude.pitch)
            let eulerAngles = SCNVector3(x: x, y: y, z: z)
            
            self.leftCameraNode.eulerAngles = eulerAngles
            self.rightCameraNode.eulerAngles = eulerAngles
        }
    }
    
}