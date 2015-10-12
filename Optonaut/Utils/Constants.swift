//
//  Constants.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/29/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import Device

let OnboardingVersion: Int = 1

enum EnvType {
    case Development
    case Staging
    case Production
}

var S3URL: String {
    switch Env {
    case .Development: return "http://optonaut-ios-beta-dev.s3.amazonaws.com"
    case .Staging: return "http://optonaut-ios-beta-staging.s3.amazonaws.com"
    case .Production: return "http://optonaut-ios-beta-production.s3.amazonaws.com"
    }
}

let CameraIntrinsics: [Double] = {
    switch UIDevice.currentDevice().deviceType {
    case .IPhone6, .IPhone6S, .IPhone6SPlus: return [5.9266119, 0, 1.6875, 0, 5.9266119, 3, 0, 0, 1]
    case .IPhone5S: return [5.9266119, 0, 1.6875, 0, 5.9266119, 3, 0, 0, 1]
    case .IPhone5: return [5.49075, 0, 1.276875, 0, 4.1, 2.27, 0, 0, 1] //TODO: Those are off
    default: return []
    }
}()