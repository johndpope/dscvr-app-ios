//
//  PipelineService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/10/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import SQLite
import Async
import ReactiveCocoa
    
func ==(lhs: PipelineService.Status, rhs: PipelineService.Status) -> Bool {
    switch (lhs, rhs) {
    case let (.Stitching(lhs), .Stitching(rhs)): return lhs == rhs
    case let (.Publishing(lhs), .Publishing(rhs)): return lhs == rhs
    case (.StitchingFinished, .StitchingFinished): return true
    case (.PublishingFinished, .PublishingFinished): return true
    default: return false
    }
}

class PipelineService {
    
    enum Status: Equatable {
        case Stitching(Float)
        case StitchingFinished
        case Publishing(Float)
        case PublishingFinished
    }
    
    typealias StatusSignal = Signal<Status, NoError>
    
    private static var signals: [UUID: StatusSignal] = [:]
    
    static func check() {
        Async.main {
            updateOptographs()
        }
    }
    
    static func statusSignalForOptograph(id: UUID) -> StatusSignal? {
        return signals[id]
    }
    
    private static func updateOptographs() {
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personId] == PersonTable[PersonSchema.id])
            .join(LocationTable, on: LocationTable[LocationSchema.id] == OptographTable[OptographSchema.locationId])
            .filter(!OptographTable[OptographSchema.isStitched] || !OptographTable[OptographSchema.isPublished])
        
        let optographs = DatabaseService.defaultConnection.prepare(query)
            .map { row -> Optograph in
                let person = Person.fromSQL(row)
                let location = Location.fromSQL(row)
                var optograph = Optograph.fromSQL(row)
                
                optograph.person = person
                optograph.location = location
                
                return optograph
            }
            .filter { signals[$0.id] == nil }
            
        optographs.forEach { optograph in
            if !optograph.isStitched {
                signals[optograph.id] = stitch(optograph)
            } else if Reachability.connectedToNetwork() {
                signals[optograph.id] = publish(optograph)
            }
        }
        
        if optographs.filter({ !$0.isStitched }).isEmpty && StitchingService.hasUnstitchedRecordings() {
            // This happens when an optograph was recorded, but never
            // inserted into the DB, for example due to cancel.
            // So it needs to be removed.
            StitchingService.removeUnstitchedRecordings()
        }
    }
    
    private static func publish(var optograph: Optograph) -> StatusSignal {
        let (signal, sink) = StatusSignal.pipe()
        
        optograph.publish()
            .on(
                started: {
                    sendNext(sink, .Publishing(0))
                },
                completed: {
                    sendNext(sink, .Publishing(1))
                    signals.removeValueForKey(optograph.id)
                    sendNext(sink, .PublishingFinished)
                    sendCompleted(sink)
                },
                error: { _ in
                    NotificationService.push("Publishing failed...", level: .Warning)
                    signals.removeValueForKey(optograph.id)
                    sendNext(sink, .PublishingFinished)
                    sendCompleted(sink)
                }
            )
            .start()
    
        return signal
    }
    
    private static func stitch(var optograph: Optograph) -> StatusSignal {
        
        let (signal, sink) = StatusSignal.pipe()
        let stitchingSignal = StitchingService.startStitching(optograph)
        
        stitchingSignal
            .observeNext { result in
                switch result {
                case .LeftImage(let data): optograph.saveAsset(.LeftImage(data))
                case .RightImage(let data): optograph.saveAsset(.RightImage(data))
                case .Progress(let progress): sendNext(sink, .Stitching(min(0.99, progress)))
                }
            }
        
        stitchingSignal
            .observeCompleted {
                optograph.isStitched = true
                try! optograph.insertOrUpdate()
                StitchingService.removeUnstitchedRecordings()
                signals.removeValueForKey(optograph.id)
                sendNext(sink, .StitchingFinished)
                sendCompleted(sink)
                PipelineService.check()
            }
        
        return signal
    }
    
}