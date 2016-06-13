//
//  DetailsViewModel.swift
//  Optonaut
//
//  Created by Robert John Alkuino on 05/16/16.
//  Copyright (c) 2016 Optonaut. All rights reserved.
//


import Foundation
import ReactiveCocoa
import SQLite
import Async

class DetailsViewModel {
    
    let isStarred = MutableProperty<Bool>(false)
    let isPublished = MutableProperty<Bool>(false)
    let starsCount = MutableProperty<Int>(0)
    let viewsCount = MutableProperty<Int>(0)
    let commentsCount = MutableProperty<Int>(0)
    let timeSinceCreated = MutableProperty<String>("")
    let avatarImageUrl = MutableProperty<String>("")
    let textureImageUrl = MutableProperty<String>("")
    let text = MutableProperty<String>("")
    let hashtags = MutableProperty<String>("")
    let locationText = MutableProperty<String>("")
    let comments = MutableProperty<[Comment]>([])
    let viewIsActive = MutableProperty<Bool>(false)
    let isLoading = MutableProperty<Bool>(true)
    let optographReloaded = MutableProperty<Void>()
    let creator_username = MutableProperty<String>("")
    let creator_userId = MutableProperty<String>("")
    let isFollowed = MutableProperty<Bool>(false)
    var isMe = false
    let likeCount = MutableProperty<Int>(0)
    let liked = MutableProperty<Bool>(false)
    
    let postingEnabled = MutableProperty<Bool>(false)
    let isPosting = MutableProperty<Bool>(false)
    
    var optographId:UUID
    
    
    var optographBox: ModelBox<Optograph>!
    var creatorDetails:ModelBox<Person>!
    
    init(optographID: UUID) {
        
        logInit()
        optographBox = Models.optographs[optographID]!
        optographId = optographID
        
        updatePropertiesDetails()
        
        postingEnabled <~ text.producer.map(isNotEmpty)
            .combineLatestWith(isPosting.producer.map(negate)).map(and)
        
        isMe = SessionService.personID == optographBox.model.personID
    }
    
    deinit {
        logRetain()
    }
    func toggleFollow() {
        let person = creatorDetails.model
        let followedBefore = person.isFollowed
        
        SignalProducer<Bool, ApiError>(value: followedBefore)
            .flatMap(.Latest) { followedBefore in
                followedBefore
                    ? ApiService<EmptyResponse>.delete("persons/\(person.ID)/follow")
                    : ApiService<EmptyResponse>.post("persons/\(person.ID)/follow", parameters: nil)
            }
            .on(
                started: { [weak self] in
                    self?.creatorDetails.insertOrUpdate { box in
                        box.model.isFollowed = !followedBefore
                    }
                },
                failed: { [weak self] _ in
                    self?.creatorDetails.insertOrUpdate { box in
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
    
    private func updatePropertiesDetails() {
        optographBox.producer.startWithNext{ [weak self] optograph in
            self?.isStarred.value = optograph.isStarred
            self?.starsCount.value = optograph.starsCount
            self?.viewsCount.value = optograph.viewsCount
            self?.commentsCount.value = optograph.commentsCount
            self?.timeSinceCreated.value = optograph.createdAt.longDescription
            self?.text.value = optograph.isPrivate ? "[private] " + optograph.text : optograph.text
            self?.hashtags.value = optograph.hashtagString
            self?.isPublished.value = optograph.isPublished
            
            if let locationID = optograph.locationID {
                let location = Models.locations[locationID]!.model
                self?.locationText.value = location.countryShort
            }
            
            self?.creatorDetails = Models.persons[optograph.personID]!
            self?.creatorDetails.producer.startWithNext{ person in
                self?.avatarImageUrl.value = "persons/\(person.ID)/\(person.avatarAssetID).jpg"
                self?.creator_username.value = person.displayName
                self?.isFollowed.value = person.isFollowed
            }
        }
    }
    
    func postComment() -> SignalProducer<Comment, ApiError> {
        return ApiService.post("optographs/\(optographId)/comments", parameters: ["text": text.value])
            .on(
                started: {
                    self.isPosting.value = true
                    self.commentsCount.value += 1
                },
                next: { comment in
                    try! comment.person.insertOrUpdate()
                    try! comment.insertOrUpdate()
                },
                completed: {
                    self.text.value = ""
                    self.isPosting.value = false
                },
                failed: { _ in
                    self.commentsCount.value -= 1
                }
        )
    }
    
    func insertNewComment(comment: Comment) {
        comments.value.orderedInsert(comment, withOrder: .OrderedAscending)
    }
    
}