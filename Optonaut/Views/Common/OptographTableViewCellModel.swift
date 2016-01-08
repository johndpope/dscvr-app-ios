//
//  OptographCellViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/24/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//


import Foundation
import ReactiveCocoa

class OptographTableViewCellModel {
    
    let optograph: Optograph
    
    let previewImageUrl: ConstantProperty<String>
//    let stitchingProgress: MutableProperty<Float>
    
    init(optograph: Optograph) {
        self.optograph = optograph
        
        previewImageUrl = ConstantProperty(ImageURL(optograph.previewAssetID, fullDimension: .Width))
        
//        if !optograph.isStitched && StitchingService.hasUnstitchedRecordings() {
//            stitchingProgress = MutableProperty(0)
//            let stitchingSignal = PipelineService.statusSignalForOptograph(optograph.ID)!
//            
//            stitchingSignal.observeCompleted {
//                self.optograph.isStitched = true
//            }
//            
//            stitchingProgress <~ stitchingSignal
//                .map { result -> Float? in
//                    if case .Stitching(let progress) = result {
//                        return progress
//                    } else {
//                        return nil
//                    }
//                }
//                .ignoreNil()
//                .ignoreError()
//        } else {
//            stitchingProgress = MutableProperty(1)
//        }
    }
    
}
