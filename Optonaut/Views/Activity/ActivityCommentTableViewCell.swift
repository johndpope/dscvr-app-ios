//
//  ActivityCommentTableViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/24/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit

class ActivityCommentTableViewCell: ActivityTableViewCell {
    
    private let optographImageView = PlaceholderImageView()
    
    required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        causingImageView.userInteractionEnabled = true
        causingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        
        optographImageView.userInteractionEnabled = true
        optographImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushDetails"))
        optographImageView.contentMode = .ScaleAspectFill
        contentView.addSubview(optographImageView)
        
        contentView.setNeedsUpdateConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        
        optographImageView.autoAlignAxisToSuperviewAxis(.Horizontal)
        optographImageView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -20)
        optographImageView.autoSetDimensionsToSize(CGSize(width: 32, height: 40))
        
        super.updateConstraints()
    }
    
    override func update() {
        causingImageView.setImageWithURLString(activity.activityResourceComment!.causingPerson.avatarAssetURL)
        optographImageView.setImageWithURLString(activity.activityResourceComment!.optograph.previewAssetURL)
        
        super.update()
    }
    
    func pushProfile() {
        navigationController?.pushViewController(ProfileTableViewController(personID: activity.activityResourceComment!.causingPerson.ID), animated: true)
    }
    
    func pushDetails() {
        navigationController?.pushViewController(DetailsTableViewController(optographID: activity.activityResourceComment!.optograph.ID), animated: true)
    }
    
}