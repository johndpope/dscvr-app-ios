//
//  TabViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 24/12/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit

class TabViewController: UIViewController {
    
    enum ActiveSide: Equatable { case Left, Right }
    
    private let blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .Dark)
        return UIVisualEffectView(effect: blurEffect)
    }()
    
    private let borderLineLayer = CALayer()
    
    private let recordButton = RecordButton()
    private let leftButton = TabButton()
    private let rightButton = TabButton()
    private let leftViewController: NavigationController
    private let rightViewController: NavigationController
    private var activeViewController: NavigationController
    
    private var uiHidden = false
    
    var delegate: TabControllerDelegate?
    
    required init() {
        leftViewController = CollectionNavViewController()
        rightViewController = ProfileNavViewController()
        
        activeViewController = leftViewController
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChildViewController(leftViewController)
        addChildViewController(rightViewController)
        
        view.insertSubview(leftViewController.view, atIndex: 0)
        
        blurView.frame = CGRect(x: 0, y: view.frame.height - 107, width: view.frame.width, height: 107)
        blurView.alpha = 0.95
        view.addSubview(blurView)
        
        borderLineLayer.backgroundColor = UIColor.whiteColor().CGColor
        borderLineLayer.opacity = 0.5
        borderLineLayer.frame = CGRect(x: 0, y: view.frame.height - 108, width: view.frame.width, height: 1)
        view.layer.addSublayer(borderLineLayer)
        
        recordButton.frame = CGRect(x: view.frame.width / 2 - 34, y: view.frame.height - 107 / 2 - 34, width: 68, height: 68)
        recordButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushCamera"))
        view.addSubview(recordButton)

        leftButton.isActive = true
        leftButton.type = .Explore
        leftButton.frame = CGRect(x: view.frame.width * 1.01 / 4 - 34, y: view.frame.height - 107 / 2 - 27.5, width: 34, height: 34)
        leftButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapLeftButton"))
        view.addSubview(leftButton)

        rightButton.isActive = false
        rightButton.type = .Profile
        rightButton.frame = CGRect(x: view.frame.width * 2.99 / 4, y: view.frame.height - 107 / 2 - 27.5, width: 34, height: 34)
        rightButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapRightButton"))
        view.addSubview(rightButton)
    }
    
    func toggleUI() {
        uiHidden = !uiHidden
        blurView.hidden = uiHidden
        borderLineLayer.hidden = uiHidden
        recordButton.hidden = uiHidden
        leftButton.hidden = uiHidden
        rightButton.hidden = uiHidden
    }
    
    func tapLeftButton() {
        if activeViewController == leftViewController {
            if activeViewController.popToRootViewControllerAnimated(true) == nil {
                delegate?.jumpToTop()
            }
        } else {
            updateActiveTab(.Left)
        }
    }
    
    func tapRightButton() {
        if activeViewController == rightViewController {
            if activeViewController.popToRootViewControllerAnimated(true) == nil {
                delegate?.jumpToTop()
            }
        } else {
            updateActiveTab(.Right)
        }
    }
    
    func pushCamera() {
        if StitchingService.isStitching() {
            let alert = UIAlertController(title: "Rendering in progress", message: "Please wait until your last Optograph has finished rendering.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            activeViewController.presentViewController(alert, animated: true, completion: nil)
        } else {
            let cameraViewController = CameraViewController()
            activeViewController.pushViewController(cameraViewController, animated: false)
        }
    }
    
    private func updateActiveTab(side: ActiveSide) {
        let isLeft = side == .Left
        leftButton.isActive = isLeft
        rightButton.isActive = !isLeft
        
        activeViewController.view.removeFromSuperview()
        activeViewController = isLeft ? leftViewController : rightViewController
        view.insertSubview(activeViewController.view, atIndex: 0)
    }

}

private class RecordButton: UIButton {
    
    private let ringLayer = CALayer()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        ringLayer.borderColor = UIColor.whiteColor().CGColor
        ringLayer.borderWidth = 1
        
        layer.addSublayer(ringLayer)
        
        backgroundColor = .Accent
        
        setTitle(String.iconWithName(.Camera_Alt), forState: .Normal)
        setTitleColor(.whiteColor(), forState: .Normal)
        titleLabel?.font = UIFont.iconOfSize(30)
    }
    
    convenience init () {
        self.init(frame: CGRectZero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = frame.width / 2
        
        ringLayer.frame = CGRect(x: -3, y: -3, width: frame.width + 6, height: frame.height + 6)
        ringLayer.cornerRadius = ringLayer.frame.width / 2
    }
    
}

private class TabButton: UIButton {
    
    enum Type { case Explore, Profile }
    var type: Type = .Explore {
        didSet {
            switch type {
            case .Explore:
                text.text = "EXPLORE"
                setTitle(String.iconWithName(.Explore), forState: .Normal)
            case .Profile:
                text.text = "PROFILE"
                setTitle(String.iconWithName(.Account_Circle), forState: .Normal)
            }
        }
    }
    
    var isActive: Bool = false {
        didSet {
            alpha = isActive ? 1 : 0.5
            activeBorderLayer.hidden = !isActive
        }
    }
    
    private let activeBorderLayer = CALayer()
    
    private let text = UILabel()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        setTitleColor(.whiteColor(), forState: .Normal)
        titleLabel?.font = UIFont.iconOfSize(34)
        
        text.font = UIFont.displayOfSize(9, withType: .Light)
        text.textColor = .whiteColor()
        text.textAlignment = .Center
        addSubview(text)
        
        activeBorderLayer.backgroundColor = UIColor.whiteColor().alpha(0.2).CGColor
        layer.addSublayer(activeBorderLayer)
    }
    
    convenience init () {
        self.init(frame: CGRectZero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private override func layoutSubviews() {
        super.layoutSubviews()
        
        let textWidth: CGFloat = 50
        text.frame = CGRect(x: (frame.width - textWidth) / 2, y: frame.height + 10, width: textWidth, height: 11)
        
        activeBorderLayer.frame = CGRect(x: -5, y: -5, width: frame.width + 10, height: frame.height + 10)
        activeBorderLayer.cornerRadius = activeBorderLayer.frame.width / 2
    }
    
}

protocol TabControllerDelegate {
    func jumpToTop()
}

extension UIViewController {
    var tabController: TabViewController? {
        return navigationController?.parentViewController as? TabViewController
    }
}