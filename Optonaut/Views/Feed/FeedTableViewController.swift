//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import PureLayout_iOS
import Refresher

class FeedTableViewController: OptographTableViewController, RedNavbar {
    
    let viewModel = OptographsViewModel(source: "optographs/feed")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = String.icomoonWithName(.LogoText)
        
        let cameraButton = UIBarButtonItem()
        cameraButton.image = UIImage.icomoonWithName(.Camera, textColor: .whiteColor(), size: CGSize(width: 21, height: 17))
        cameraButton.target = self
        cameraButton.action = "pushCamera"
        navigationItem.setRightBarButtonItem(cameraButton, animated: false)
        
        let searchButton = UIBarButtonItem()
        searchButton.title = String.icomoonWithName(.MagnifyingGlass)
        searchButton.image = UIImage.icomoonWithName(.MagnifyingGlass, textColor: .whiteColor(), size: CGSize(width: 21, height: 17))
        searchButton.target = self
        searchButton.action = "pushSearch"
        navigationItem.setLeftBarButtonItem(searchButton, animated: false)
        
        let refreshAction = {
            NSOperationQueue().addOperationWithBlock {
                self.viewModel.resultsLoading.put(true)
            }
        }
        
        tableView.addPullToRefreshWithAction(refreshAction, withAnimator: RefreshAnimator())
        
        viewModel.results.producer.start(
            next: { results in
                self.items = results
                self.tableView.reloadData()
                self.tableView.stopPullToRefresh()
            },
            error: { _ in
                self.tableView.stopPullToRefresh()
        })
        
        viewModel.resultsLoading.put(true)
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateNavbarAppear()
        navigationController?.hidesBarsOnSwipe = true
        
        navigationController?.navigationBar.setTitleVerticalPositionAdjustment(16, forBarMetrics: .Default)
        navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.icomoonOfSize(50),
            NSForegroundColorAttributeName: UIColor.whiteColor(),
        ]
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.hidesBarsOnSwipe = false
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func updateViewConstraints() {
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        super.updateViewConstraints()
    }
    
    func pushCamera() {
        navigationController?.pushViewController(CameraViewController(), animated: false)
    }
    
    func pushSearch() {
        navigationController?.pushViewController(SearchTableViewController(), animated: false)
    }
    
}