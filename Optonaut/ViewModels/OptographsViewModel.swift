//
//  OptographsTableViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/25/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import ObjectMapper

class OptographsViewModel {
    
    let results = MutableProperty<[Optograph]>([])
    let resultsLoading = MutableProperty<Bool>(false)
    
    init(source: String) {
        let callApi: SignalProducer<Bool, NSError> -> SignalProducer<JSONResponse, NSError> = flatMap(.Latest) { _ in Api.get(source, authorized: true) }
        
        resultsLoading.producer
            |> mapError { _ in NSError(domain: "", code: 0, userInfo: nil) }
            |> filter { $0 }
            |> callApi
            |> start(
                next: { json in
                    var optographs = Mapper<Optograph>().mapArray(json)!
                    optographs = optographs.sort { $0.createdAt.compare($1.createdAt) == NSComparisonResult.OrderedDescending }
                    
                    self.results.put(optographs)
                    self.resultsLoading.put(false)
                },
                error: { _ in
                    self.resultsLoading.put(false)
                }
        )
        
    }
    
}
