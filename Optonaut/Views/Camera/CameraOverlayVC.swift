//
//  CameraOverlayVC.swift
//  DSCVR
//
//  Created by robert john alkuino on 11/14/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit
import AVFoundation
import Async
import Photos
import SwiftyUserDefaults
import CoreBluetooth

var btPeripheralSharedInstance: BLEService?
var btServiceSharedInstance: CBService?

// TODO: This class is a mess. duplication, ill state transistion, racing conditions. cleanup. 
class CameraOverlayVC: UIViewController {//,CBPeripheralManagerDelegate{
    
    private let session = AVCaptureSession()
    private var videoDevice : AVCaptureDevice?
    private let manualButton = UIButton()
    private let motorButton = UIButton()
    private let motorLabel = UILabel()
    private let manualLabel = UILabel()
    private var backButton = UIButton()
    private let progressView = CameraOverlayProgressView()
    var timer:NSTimer?
    var blSheet = UIAlertController()
    var deviceLastCount: Int = 0
    
    private var btDiscovery: BLEDiscovery?
    private var deviceList: [CBPeripheral] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        tabController?.delegate = self
        
        setupCamera()
        setupScene()
        
        getBluetoothList()
        btDiscovery = BLEDiscovery(onDeviceFound: onDeviceFound, onDeviceConnected: onDeviceConnected, services: [MotorControl.BLEServiceUUID])
    }
    
    func onDeviceFound(peripheral: CBPeripheral, name: NSString) {
        deviceList.append(peripheral)
    }
    
    func onDeviceConnected(peripheral: CBPeripheral) {
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .None)
    }
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        timer?.invalidate()
    }
    
    func getBluetoothList() {
        if Defaults[.SessionMotor] {
            if deviceList.count > 0 {
                if deviceLastCount != deviceList.count {
                    deviceLastCount = deviceList.count
                    blSheet.dismissViewControllerAnimated(false, completion: nil)
                    getBluetoothDevicesToPair()
                    print("may changes")
                }
            } else {
                deviceList = []
                if deviceLastCount != deviceList.count {
                    deviceLastCount = deviceList.count
                    blSheet.dismissViewControllerAnimated(false, completion: nil)
                    getBluetoothDevicesToPair()
                    print("may changes zero count")
                } else {
                    print("walang changes zero count")
                }
            }
        }
    }
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        if peripheral.state == CBPeripheralManagerState.PoweredOn {
            print("Broadcasting...")
        } else if peripheral.state == CBPeripheralManagerState.PoweredOff {
            let confirmAlert = UIAlertController(title: "", message: "Motor mode requires Bluetooth turned ON and paired to any DSCVR Orbit Motor.", preferredStyle: .Alert)
            confirmAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
            self.presentViewController(confirmAlert, animated: true, completion: nil)
        } else if peripheral.state == CBPeripheralManagerState.Unsupported {
            print("Unsupported")
        } else if peripheral.state == CBPeripheralManagerState.Unauthorized {
            print("This option is not allowed by your application")
        }
    }
    
    private func setupScene() {
        
//        backButton = backButton?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
//        navigationItem.leftBarButtonItem = UIBarButtonItem(image: backButton, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(closeCamera))
        
        
        backButton.setBackgroundImage(UIImage(named: "camera_back_button"), forState: .Normal)
        backButton.addTarget(self, action: #selector(closeCamera), forControlEvents: .TouchUpInside)
        view.addSubview(backButton)
        
        backButton.anchorInCorner(.TopLeft, xPad: 15, yPad: 26, width: 20, height: 20)
        
        progressView.progress = 0
        view.addSubview(progressView)
        
        progressView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 31)
        progressView.autoMatchDimension(.Width, toDimension: .Width, ofView: view, withOffset: -80)
        progressView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        
        
        manualButton.addTarget(self, action: #selector(manualClicked), forControlEvents: .TouchUpInside)
        motorButton.addTarget(self, action: #selector(motorClicked), forControlEvents: .TouchUpInside)
        
        view.addSubview(manualButton)
        view.addSubview(motorButton)
        
        if let buttonSize = UIImage(named: "manualButton_on")?.size {
            
            let padding = (view.width - (buttonSize.width * 2)) / 3
            
            view.groupInCenter(group: .Horizontal, views: [manualButton, motorButton], padding: padding, width: buttonSize.width, height: buttonSize.height)
        }
        
        manualLabel.text = "MANUAL MODE"
        manualLabel.font = UIFont(name: "Avenir-Heavy", size: 17)
        view.addSubview(manualLabel)
        
        motorLabel.text = "MOTOR MODE"
        motorLabel.font = UIFont(name: "Avenir-Heavy", size: 17)
        view.addSubview(motorLabel)
        
        Defaults[.SessionMotor] ? isMotorMode(true) : isMotorMode(false)
        
        manualLabel.align(.UnderCentered, relativeTo: manualButton, padding: 10, width: calcTextWidth(manualLabel.text!, withFont: manualLabel.font), height: 23)
        motorLabel.align(.UnderCentered, relativeTo: motorButton, padding: 10, width: calcTextWidth(motorLabel.text!, withFont: motorLabel.font), height: 23)
        
//        cameraButton.setBackgroundImage(UIImage(named: "camera_icn"), forState: .Normal)
//        let size = UIImage(named:"camera_icn")!.size
//        cameraButton.addTarget(self, action: #selector(record), forControlEvents: .TouchUpInside)
//        view.addSubview(cameraButton)
//        cameraButton.anchorToEdge(.Bottom, padding: 20, width: size.width, height: size.height)
    }
    
    func getCBPeripheralState(state:CBPeripheralState) -> String {
        switch state {
        case .Disconnected:
            return "Disconnected"
        case .Connected:
            return "Connected"
        case .Disconnecting:
            return "Disconnecting"
        case .Connecting:
            return "Connecting"
        }
    }
    
    func getBluetoothDevicesToPair() {
        blSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        if deviceList.count == 0 {
            timer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(getBluetoothList), userInfo: nil, repeats: true)
            blSheet.addAction(UIAlertAction(title: "Searching for nearby devices..", style: .Default, handler: { _ in
                return
            }))
        }
        
        for dev in deviceList {
            blSheet.addAction(UIAlertAction(title: "\(dev.name!)    (\(getCBPeripheralState(dev.state)))", style: .Default, handler: { _ in
                btPeripheralSharedInstance = BLEService(initWithPeripheral: dev, onServiceConnected: self.serviceConnected, bleService: MotorControl.BLEServiceUUID, bleCharacteristic: MotorControl.BLECharacteristicUUID)
                btPeripheralSharedInstance?.startDiscoveringServices()
            }))
        }
        
        blSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
        
        self.presentViewController(blSheet, animated: true, completion: nil)
        
    }
    
    func serviceConnected(service: CBService) {
        btServiceSharedInstance = service
    }
    
    func closeCamera() {
        navigationController?.popViewControllerAnimated(false)
    }
    
    func record() {
        if Defaults[.SessionMotor] {
            if deviceList.count == 0 {
                let confirmAlert = UIAlertController(title: "Error!", message: "Motor mode requires Bluetooth turned ON and paired to any DSCVR Orbit Motor.", preferredStyle: .Alert)
                confirmAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
                self.presentViewController(confirmAlert, animated: true, completion: nil)
            } else {
                for dev in deviceList {
                    if getCBPeripheralState(dev.state) == "Connected" {
                        navigationController?.pushViewController(CameraViewController(), animated: false)
                        navigationController?.viewControllers.removeAtIndex(1)
                        return
                    }
                }
                let confirmAlert = UIAlertController(title: "Error!", message: "Motor mode requires Bluetooth turned ON and paired to any DSCVR Orbit Motor.", preferredStyle: .Alert)
                confirmAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
                self.presentViewController(confirmAlert, animated: true, completion: nil)
            }
            
            
        } else {
            navigationController?.pushViewController(CameraViewController(), animated: false)
            navigationController?.viewControllers.removeAtIndex(1)
        }
    }
    
    func isMotorMode(state:Bool) {
        if state {
            manualButton.setBackgroundImage(UIImage(named: "manualButton_off"), forState: .Normal)
            motorButton.setBackgroundImage(UIImage(named: "motorButton_on"), forState: .Normal)
            
            manualLabel.textColor = UIColor(0x979797)
            motorLabel.textColor = UIColor(0xFF5E00)
        } else {
            manualButton.setBackgroundImage(UIImage(named: "manualButton_on"), forState: .Normal)
            motorButton.setBackgroundImage(UIImage(named: "motorButton_off"), forState: .Normal)
            
            manualLabel.textColor = UIColor(0xFF5E00)
            motorLabel.textColor = UIColor(0x979797)
        }
    }
    
    func manualClicked() {
        isMotorMode(false)
        Defaults[.SessionMotor] = false
        Defaults[.SessionUseMultiRing] = false
        
        timer?.invalidate()
    }
    
    func motorClicked() {
        
        isMotorMode(true)
        Defaults[.SessionMotor] = true
        Defaults[.SessionUseMultiRing] = true
        
        getBluetoothDevicesToPair()
    }
    
    private func setupCamera() {
        authorizeCamera()
        
        session.sessionPreset = AVCaptureSessionPreset1280x720
        
        videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!) else {
            return
        }
        
        session.beginConfiguration()
        
        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
        }
        
        let videoDeviceOutput = AVCaptureVideoDataOutput()
        videoDeviceOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey: NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)]
        videoDeviceOutput.alwaysDiscardsLateVideoFrames = true
        //videoDeviceOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        
        if session.canAddOutput(videoDeviceOutput) {
            session.addOutput(videoDeviceOutput)
        }
        
        let conn = videoDeviceOutput.connectionWithMediaType(AVMediaTypeVideo)
        conn.videoOrientation = AVCaptureVideoOrientation.Portrait
        
        session.commitConfiguration()
        
        try! videoDevice?.lockForConfiguration()
        
        
        var bestFormat: AVCaptureDeviceFormat?
        
        var maxFps: Double = 0
        
        for format in videoDevice!.formats.map({ $0 as! AVCaptureDeviceFormat }) {
            var ranges = format.videoSupportedFrameRateRanges as! [AVFrameRateRange]
            let frameRates = ranges[0]
            if frameRates.maxFrameRate >= maxFps && frameRates.maxFrameRate <= 30 {
                maxFps = frameRates.maxFrameRate
                bestFormat = format
                
            }
        }
        
        if videoDevice!.activeFormat.videoHDRSupported.boolValue {
            videoDevice!.automaticallyAdjustsVideoHDREnabled = false
            videoDevice!.videoHDREnabled = false
        }
        
        videoDevice!.exposureMode = .ContinuousAutoExposure
        videoDevice!.whiteBalanceMode = .ContinuousAutoWhiteBalance
        
        AVCaptureVideoStabilizationMode.Standard
        
        videoDevice!.activeVideoMinFrameDuration = CMTimeMake(1, 30)
        videoDevice!.activeVideoMaxFrameDuration = CMTimeMake(1, 30)
        
        videoDevice!.unlockForConfiguration()
        
        session.startRunning()
    }
    
    private func authorizeCamera() {
        var alreadyFailed = false
        let failAlert = {
            Async.main { [weak self] in
                if alreadyFailed {
                    return
                } else {
                    alreadyFailed = true
                }
                
                let alert = UIAlertController(title: "No access to camera", message: "Please enable permission to use the camera and photos.", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Enable", style: .Default, handler: { _ in
                    UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
                }))
                self?.presentViewController(alert, animated: true, completion: nil)
            }
        }
        
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { granted in
            if !granted {
                failAlert()
            }
        })
        
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .NotDetermined, .Restricted, .Denied: failAlert()
            default: ()
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let videoDevice = self.videoDevice {
            try! videoDevice.lockForConfiguration()
            videoDevice.focusMode = .ContinuousAutoFocus
            videoDevice.exposureMode = .ContinuousAutoExposure
            videoDevice.whiteBalanceMode = .ContinuousAutoWhiteBalance
            videoDevice.unlockForConfiguration()
        }
        
        session.stopRunning()
        videoDevice = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
private class CameraOverlayProgressView: UIView {
    
    var progress: Float = 0 {
        didSet {
            layoutSubviews()
        }
    }
    var isActive = false {
        didSet {
            foregroundLine.backgroundColor = isActive ? UIColor(hex:0xFF5E00).CGColor : UIColor.whiteColor().CGColor
            trackingPoint.backgroundColor = isActive ? UIColor(hex:0xFF5E00).CGColor : UIColor.whiteColor().CGColor
        }
    }
    
    private let firstBackgroundLine = CALayer()
    private let endPoint = CALayer()
    private let foregroundLine = CALayer()
    private let trackingPoint = CALayer()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        firstBackgroundLine.backgroundColor = UIColor.whiteColor().CGColor
        layer.addSublayer(firstBackgroundLine)
        
        endPoint.backgroundColor = UIColor.whiteColor().CGColor
        endPoint.cornerRadius = 3.5
        layer.addSublayer(endPoint)
        
        foregroundLine.cornerRadius = 1
        layer.addSublayer(foregroundLine)
        
        trackingPoint.cornerRadius = 7
        layer.addSublayer(trackingPoint)
    }
    
    convenience init () {
        self.init(frame: CGRectZero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = bounds.width - 12
        let originX = bounds.origin.x + 6
        let originY = bounds.origin.y + 6
        
        firstBackgroundLine.frame = CGRect(x: originX, y: originY - 0.6, width: width, height: 1.2)
        endPoint.frame = CGRect(x: width + 3.5, y: originY - 3.5, width: 7, height: 7)
        foregroundLine.frame = CGRect(x: originX, y: originY - 1, width: width * CGFloat(progress), height: 2)
        trackingPoint.frame = CGRect(x: originX + width * CGFloat(progress) - 6, y: originY - 6, width: 12, height: 12)
    }
}

extension CameraOverlayVC: TabControllerDelegate {
    
    func onTapCameraButton() {
        record()
    }
}

