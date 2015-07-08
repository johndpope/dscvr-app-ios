//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import PureLayout_iOS
import Alamofire
import SwiftyJSON
import Refresher

class FeedTableViewController: OptographTableViewController {

    var fullscreen = false
    let statusBarBackgroundView = UIView()
    
    var viewModel: OptographsViewModel
    
    required init(source: String, fullscreen: Bool) {
        viewModel = OptographsViewModel(source: source)
        super.init(nibName: nil, bundle: nil)
        self.fullscreen = fullscreen
    }
    
    required init(coder aDecoder: NSCoder) {
        viewModel = OptographsViewModel(source: "")
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        statusBarBackgroundView.backgroundColor = baseColor()
        statusBarBackgroundView.hidden = !fullscreen
        navigationController?.view.addSubview(statusBarBackgroundView)
        
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        statusBarBackgroundView.hidden = !fullscreen
        navigationController?.hidesBarsOnSwipe = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        statusBarBackgroundView.hidden = true
        navigationController?.hidesBarsOnSwipe = false
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
//    override func viewDidDisappear(animated: Bool) {
//        super.viewDidDisappear(animated)
//    }
    
    override func updateViewConstraints() {
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        statusBarBackgroundView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)
        statusBarBackgroundView.autoSetDimension(.Height, toSize: 22)
        
        super.updateViewConstraints()
    }
    
}
