//
//  CommentViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/13/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class CommentViewModel {
    
    let text: ConstantProperty<String>
    let avatarUrl: ConstantProperty<String>
    let fullName: ConstantProperty<String>
    let userName: ConstantProperty<String>
    let personId: ConstantProperty<UUID>
    let timeSinceCreated = MutableProperty<String>("")
    
    init(comment: Comment) {
        guard let person = comment.person else {
            fatalError("person can not be nil")
        }
        
        text = ConstantProperty(comment.text)
        avatarUrl = ConstantProperty("\(StaticFilePath)/profile-images/thumb/\(person.id).jpg")
        fullName = ConstantProperty(person.fullName)
        userName = ConstantProperty("@\(person.userName)")
        personId = ConstantProperty(person.id)
        timeSinceCreated.value = RoundedDuration(date: comment.createdAt).shortDescription()
    }
    
}