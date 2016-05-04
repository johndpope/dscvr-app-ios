//
//  NewCommentViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/14/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class NewCommentViewModel {
    
    let optographID: ConstantProperty<UUID>
    let text = MutableProperty<String>("")
    let postingEnabled = MutableProperty<Bool>(false)
    let isPosting = MutableProperty<Bool>(false)
    let commentsCount = MutableProperty<Int>(0)
    
    init(optographID: UUID, commentsCount: Int) {
        self.optographID = ConstantProperty(optographID)
        self.commentsCount.value = commentsCount
        
        postingEnabled <~ text.producer.map(isNotEmpty)
            .combineLatestWith(isPosting.producer.map(negate)).map(and)
    }
    
    func postComment() -> SignalProducer<Comment, ApiError> {
        return ApiService.post("optographs/\(optographID.value)/comments", parameters: ["text": text.value])
            .on(
                started: {
                    self.isPosting.value = true
                    self.commentsCount.value++
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
                    self.commentsCount.value--
                }
        )
    }
    
}