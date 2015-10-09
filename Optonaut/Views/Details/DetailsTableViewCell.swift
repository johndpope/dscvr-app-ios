//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ActiveLabel

class DetailsTableViewCell: UITableViewCell {
    
    weak var viewModel: DetailsViewModel!
    weak var navigationController: NavigationController?
    
    // subviews
    private let previewImageView = PlaceholderImageView()
    private let locationView = InsetLabel()
    private let avatarImageView = PlaceholderImageView()
    private let progressView = UIProgressView()
    private let displayNameView = UILabel()
    private let userNameView = UILabel()
    private let dateView = UILabel()
    private let actionButtonView = UIButton()
    private let starButtonView = UIButton()
    private let starCountView = UILabel()
    private let commentIconView = UILabel()
    private let commentCountView = UILabel()
    private let viewIconView = UILabel()
    private let viewsCountView = UILabel()
    private let textView = ActiveLabel()
    private let lineView = UIView()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        previewImageView.placeholderImage = UIImage(named: "optograph-details-placeholder")!
        previewImageView.contentMode = .ScaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.userInteractionEnabled = true
        previewImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushViewer"))
        contentView.addSubview(previewImageView)
        
        locationView.font = UIFont.robotoOfSize(12, withType: .Regular)
        locationView.textColor = .whiteColor()
        locationView.backgroundColor = UIColor(0x0).alpha(0.4)
        locationView.edgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        contentView.addSubview(locationView)
        
        progressView.progressViewStyle = UIProgressViewStyle.Bar
        progressView.progressTintColor = UIColor.Accent
        contentView.addSubview(progressView)
        
        avatarImageView.placeholderImage = UIImage(named: "avatar-placeholder")!
        avatarImageView.layer.cornerRadius = 15
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        contentView.addSubview(avatarImageView)
        
        displayNameView.font = UIFont.robotoOfSize(15, withType: .Medium)
        displayNameView.textColor = UIColor(0x4d4d4d)
        displayNameView.userInteractionEnabled = true
        displayNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        contentView.addSubview(displayNameView)
        
        userNameView.font = UIFont.robotoOfSize(12, withType: .Light)
        userNameView.textColor = UIColor(0xb3b3b3)
        userNameView.userInteractionEnabled = true
        userNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        contentView.addSubview(userNameView)
        
        dateView.font = UIFont.robotoOfSize(12, withType: .Light)
        dateView.textColor = UIColor(0xb3b3b3)
        contentView.addSubview(dateView)
        
        actionButtonView.titleLabel?.font = UIFont.icomoonOfSize(20)
        actionButtonView.setTitle(String.icomoonWithName(.DotsVertical), forState: .Normal)
        actionButtonView.setTitleColor(UIColor(0xe6e6e6), forState: .Normal)
        actionButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "didTapOptions"))
        contentView.addSubview(actionButtonView)
        
        starButtonView.titleLabel?.font = UIFont.icomoonOfSize(20)
        starButtonView.setTitle(String.icomoonWithName(.HeartOutlined), forState: .Normal)
        starButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleStar"))
        contentView.addSubview(starButtonView)
        
        starCountView.font = UIFont.robotoOfSize(12, withType: .Light)
        starCountView.textColor = UIColor(0xb3b3b3)
        contentView.addSubview(starCountView)
        
        commentIconView.font = UIFont.icomoonOfSize(20)
        commentIconView.text = String.icomoonWithName(.CommentOutlined)
        commentIconView.textColor = UIColor(0xe6e6e6)
        contentView.addSubview(commentIconView)
        
        commentCountView.font = UIFont.robotoOfSize(12, withType: .Light)
        commentCountView.textColor = UIColor(0xb3b3b3)
        contentView.addSubview(commentCountView)
        
        viewIconView.font = UIFont.icomoonOfSize(20)
        viewIconView.text = String.icomoonWithName(.Eye)
        viewIconView.textColor = UIColor(0xe6e6e6)
        contentView.addSubview(viewIconView)
        
        viewsCountView.font = UIFont.robotoOfSize(12, withType: .Light)
        viewsCountView.textColor = UIColor(0xb3b3b3)
        contentView.addSubview(viewsCountView)
        
        textView.numberOfLines = 0
        textView.userInteractionEnabled = true
        textView.font = UIFont.robotoOfSize(13, withType: .Light)
        textView.textColor = UIColor(0x4d4d4d)
        textView.mentionColor = UIColor.Accent
        textView.hashtagColor = UIColor.Accent
        textView.URLEnabled = false
        contentView.addSubview(textView)
        
        lineView.backgroundColor = UIColor(0xe5e5e5)
        contentView.addSubview(lineView)
        
        contentView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        previewImageView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView)
        previewImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: contentView)
        previewImageView.autoMatchDimension(.Height, toDimension: .Width, ofView: contentView, withMultiplier: 0.84)
        
        locationView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: previewImageView, withOffset: -13)
        locationView.autoPinEdge(.Left, toEdge: .Left, ofView: previewImageView, withOffset: 19)
        
        avatarImageView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 15)
        avatarImageView.autoPinEdge(.Left, toEdge: .Left, ofView: previewImageView, withOffset: 19)
        avatarImageView.autoSetDimensionsToSize(CGSize(width: 30, height: 30))
        
        progressView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView)
        progressView.autoMatchDimension(.Width, toDimension: .Width, ofView: contentView)
        
        displayNameView.autoPinEdge(.Top, toEdge: .Top, ofView: avatarImageView, withOffset: -2)
        displayNameView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 11)
        
        userNameView.autoPinEdge(.Top, toEdge: .Top, ofView: avatarImageView)
        userNameView.autoPinEdge(.Left, toEdge: .Right, ofView: displayNameView, withOffset: 4)
        
        dateView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: avatarImageView, withOffset: 2)
        dateView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 11)
        
        actionButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 12)
        actionButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -19)
        
        starButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarImageView, withOffset: 12)
        starButtonView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 19)
        
        starCountView.autoPinEdge(.Top, toEdge: .Top, ofView: starButtonView, withOffset: 8)
        starCountView.autoPinEdge(.Left, toEdge: .Right, ofView: starButtonView, withOffset: 5)
        
        commentIconView.autoPinEdge(.Top, toEdge: .Top, ofView: starButtonView, withOffset: 4)
        commentIconView.autoPinEdge(.Left, toEdge: .Right, ofView: starCountView, withOffset: 19)

        commentCountView.autoPinEdge(.Top, toEdge: .Top, ofView: starCountView)
        commentCountView.autoPinEdge(.Left, toEdge: .Right, ofView: commentIconView, withOffset: 7)
        
        viewIconView.autoPinEdge(.Top, toEdge: .Top, ofView: starButtonView, withOffset: 7)
        viewIconView.autoPinEdge(.Left, toEdge: .Right, ofView: commentCountView, withOffset: 19)

        viewsCountView.autoPinEdge(.Top, toEdge: .Top, ofView: starCountView)
        viewsCountView.autoPinEdge(.Left, toEdge: .Right, ofView: viewIconView, withOffset: 7)
        
        textView.autoPinEdge(.Top, toEdge: .Bottom, ofView: starButtonView, withOffset: 12)
        textView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 15)
        textView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -15)
        
        lineView.autoPinEdge(.Top, toEdge: .Bottom, ofView: textView, withOffset: 14)
        lineView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 19)
        lineView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -19)
        lineView.autoSetDimension(.Height, toSize: 1)
        
        super.updateConstraints()
    }
    
    func bindViewModel() {
        previewImageView.rac_url <~ viewModel.previewImageUrl
        
        locationView.rac_text <~ viewModel.location
        
        progressView.rac_hidden <~ viewModel.downloadProgress.producer.observeOn(QueueScheduler.mainQueueScheduler).map { $0 == 1 }
        
        viewModel.downloadProgress.producer
            .startOn(QueueScheduler(queue: dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)))
            .observeOn(UIScheduler())
            .startWithNext { progress in
                self.progressView.setProgress(progress, animated: true)
            }
        
        avatarImageView.rac_url <~ viewModel.avatarImageUrl
        
        displayNameView.rac_text <~ viewModel.displayName
        
        userNameView.rac_text <~ viewModel.userName
        
        dateView.rac_text <~ viewModel.timeSinceCreated
        
        starButtonView.rac_titleColor <~ viewModel.isStarred.producer.map { $0 ? UIColor.Accent : UIColor(0xe6e6e6) }
        
        starCountView.rac_text <~ viewModel.starsCount.producer.map { "\($0) likes" }
        
        commentCountView.rac_text <~ viewModel.commentsCount.producer.map { "\($0) comments" }
        
        viewsCountView.rac_text <~ viewModel.viewsCount.producer.map { "\($0) views" }
        
        textView.rac_text <~ viewModel.text
        textView.handleHashtagTap { hashtag in
            self.navigationController?.pushViewController(HashtagTableViewController(hashtag: hashtag), animated: true)
        }
        textView.handleMentionTap { userName in
            ApiService<Person>.get("persons/user-name/\(userName)")
                .startWithNext { person in
                    self.navigationController?.pushViewController(ProfileTableViewController(personId: person.id), animated: true)
                }
        }
    }
    
    func toggleStar() {
        viewModel.toggleLike()
    }
    
    func pushProfile() {
        let profileContainerViewController = ProfileTableViewController(personId: viewModel.personId.value)
        navigationController?.pushViewController(profileContainerViewController, animated: true)
    }
    
    func pushViewer() {
        if viewModel.downloadProgress.value == 1 {
            let alert = UIAlertController(title: "Rotate counter clockwise", message: "Please rotate your phone counter clockwise by 90 degree.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            self.navigationController?.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
}

// MARK: - OptographOptions
extension DetailsTableViewCell: OptographOptions {
    
    func didTapOptions() {
        showOptions(viewModel.optograph)
    }
    
}