//
//  FollowersTableViewCell.swift
//  Iam360
//
//  Created by robert john alkuino on 6/22/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class FollowersTableViewCell: UITableViewCell {
    
    var userImage: UIImageView = UIImageView()
    var nameLabel: UILabel = UILabel()
    var followButton = UIButton()
    var personBox: ModelBox<Person>!
    var isFollowed = MutableProperty<Bool>(false)
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.userImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 50.0, height: 50.0))
        self.userImage.center = CGPoint(x: userImage.frame.size.width/2.0 + 20.0, y: self.contentView.frame.height/2 + 15.0)
        self.userImage.backgroundColor = UIColor.lightGrayColor()
        self.userImage.layer.cornerRadius = self.userImage.frame.size.width/2
        self.userImage.layer.borderColor = UIColor(hex:0xffbc00).CGColor
        self.userImage.layer.borderWidth = 2.0
        self.userImage.clipsToBounds = true
        self.userImage.image = UIImage(named: "avatar-placeholder")!
        
        self.nameLabel = UILabel(frame: CGRect(x: self.userImage.frame.origin.x + self.userImage.frame.size.width + 10.0, y: self.userImage.frame.origin.y + 10.0, width: 100.0, height: 30.0))
        self.nameLabel.font = UIFont.systemFontOfSize(15.0, weight: UIFontWeightMedium)
        
        self.nameLabel.textColor = UIColor.darkGrayColor()
        
        let followButtonSize = UIImage(named: "follow_button")?.size
        followButton.addTarget(self, action: #selector(toggleFollow), forControlEvents:.TouchUpInside)
        
        self.followButton.frame = CGRect(x: 0, y: 0,  width: (followButtonSize?.width)!, height: (followButtonSize?.height)!)
        self.followButton.center = CGPoint(x: self.contentView.frame.size.width - 10, y: self.userImage.center.y)
        
        self.addSubview(followButton)
        self.addSubview(userImage)
        self.addSubview(nameLabel)
        
        self.nameLabel.align(.ToTheRightCentered, relativeTo: self.userImage, padding: 10, width: 100, height: 30)
        
        isFollowed.producer.startWithNext{val in
            if val {
                self.followButton.setBackgroundImage(UIImage(named: "follow_button"), forState: .Normal)
            } else {
                self.followButton.setBackgroundImage(UIImage(named: "unfollow_button"), forState: .Normal)
            }
        }
    }
    func bind(personId:UUID) {
        personBox = Models.persons[personId]!
        
//        personBox.producer
//            .skipRepeats()
//            .startWithNext { [weak self] person in
////                self?.displayName.value = "@\(person.displayName)"
////                self?.userName.value = "@\(person.userName)"
////                self?.text.value = person.text
////                self?.postCount.value = person.optographsCount
////                self?.followersCount.value = person.followersCount
////                self?.followingCount.value = person.followedCount
//                self?.isFollowed.value = person.isFollowed
////                self?.avatarImageUrl.value = ImageURL("persons/\(person.ID)/\(person.avatarAssetID).jpg", width: 84, height: 84)
//        }
        
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
                        self?.isFollowed.value = !followedBefore
                    }
                },
                failed: { [weak self] _ in
                    self?.personBox.insertOrUpdate { box in
                        box.model.isFollowed = followedBefore
                        self?.isFollowed.value = followedBefore
                    }
                }
            )
            .start()
    }
    
    required init(coder aDecoder: NSCoder){
        //Just Call Super
        super.init(coder: aDecoder)!
    }
}
