//
//  RequestInviteViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/6/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class RequestInviteViewModel {
    
    let email = MutableProperty<String>("")
    let emailValid = MutableProperty<Bool>(false)
    let pending = MutableProperty<Bool>(false)
    
    init() {
        email.producer
            .start(next: { str in
                self.emailValid.value = isValidEmail(str)
            })
    }
    
    func requestInvite() -> SignalProducer<JSONResponse, NSError> {
        pending.value = true
        
        let parameters = ["email": email.value]
        return Api.post("persons/request-invite", authorized: false, parameters: parameters)
            .on(
                completed: { _ in
                    self.pending.value = false
                },
                error: { _ in
                    self.pending.value = false
                }
        )
    }
    
}