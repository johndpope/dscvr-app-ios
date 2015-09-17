//
//  Utils.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/20/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import ReactiveCocoa


func uuid() -> UUID {
    return NSUUID().UUIDString.lowercaseString
}

func isValidEmail(email: String) -> Bool {
    let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
    let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailTest.evaluateWithObject(email)
}

func isValidPassword(password: String) -> Bool {
    return password.characters.count >= 5
}

func isValidUserName(userName: String) -> Bool {
    let userNameRegEx = "^[a-zA-Z0-9_]+$"
    let userNameTest = NSPredicate(format:"SELF MATCHES %@", userNameRegEx)
    return userNameTest.evaluateWithObject(userName)
}

func identity<T>(el: T) -> T {
    return el
}

func calcTextHeight(text: String, withWidth width: CGFloat) -> CGFloat {
    let attributes = [NSFontAttributeName: UIFont.robotoOfSize(13, withType: .Light)]
    let textAS = NSAttributedString(string: text, attributes: attributes)
    let tmpSize = CGSize(width: width, height: 100000)
    let textRect = textAS.boundingRectWithSize(tmpSize, options: [.UsesFontLeading, .UsesLineFragmentOrigin], context: nil)
    
    return textRect.height
}

class NotificationSignal {
    
    var producer: SignalProducer<Void, NoError>!
    private var notifyCallback: (() -> ())?
    
    init() {
        producer = SignalProducer({ sink, disposable in
            self.notifyCallback = {
                sendNext(sink, ())
            }
            disposable.addDisposable {
                self.notifyCallback = nil
            }
        })
    }
    
    func notify() {
        notifyCallback?()
    }
    
}

//class NotificationSignal {
//    
//    let (signal, sink) =  Signal<Void, NoError>.pipe()
//    
//    func notify() {
//        sendNext(sink, ())
//    }
//    
//}


