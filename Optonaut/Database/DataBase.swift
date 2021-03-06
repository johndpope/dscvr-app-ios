//
//  DataBase.swift
//  DSCVR
//
//  Created by Philipp Meyer on 27.04.17.
//  Copyright © 2017 Optonaut. All rights reserved.
//

import Foundation
import SQLite

class DataBase {
    
    static let sharedInstance = DataBase()
    
    let index = Expression<Int64>("index")
    let id = Expression<String>("id")
    let createdAt = Expression<Date>("createdAt")
    let updatedAt = Expression<Date>("updatedAt")
    let isStitched = Expression<Bool>("isStitched")
    let stitcherVersion = Expression<String>("stitcherVersion")
    let directionPhi = Expression<Double>("directionPhi")
    let directionTheta = Expression<Double>("directionTheta")
    let ringCount = Expression<Int>("ringCount")
    let optoID = Table("optoID")
    let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    
    init() {}
    
    func createDataBase() {
        do {
            let db = try Connection("\(path)/optographs.sqlite3")
            try db.run(optoID.create(ifNotExists: true) { i in
                i.column(index, primaryKey: .autoincrement)
                i.column(id, unique: true)
                i.column(createdAt)
                i.column(updatedAt)
                i.column(isStitched)
                i.column(stitcherVersion)
                i.column(directionPhi)
                i.column(directionTheta)
                i.column(ringCount)
            })
        } catch {
            fatalError("Error while creating Database")
        }
    }
    
    func addOptograph(optograph: Optograph) {
        do {
            let db = try Connection("\(path)/optographs.sqlite3")
            let rowid = try db.run(optoID.insert(id <- optograph.ID,
                                                 createdAt <- optograph.createdAt,
                                                 updatedAt <- optograph.updatedAt,
                                                 isStitched <- optograph.isStitched,
                                                 stitcherVersion <- optograph.stitcherVersion,
                                                 directionPhi <- optograph.directionPhi,
                                                 directionTheta <- optograph.directionTheta,
                                                 ringCount <- optograph.ringCount))
            print("addOptograph inserted id: \(rowid)")
        } catch {
            print("addOptograph insertion failed: \(error)")
        }
    }

    func getOptographIDsAsArray() -> [String] {
        var resultArray = [String]()
        do {
            let db = try Connection("\(path)/optographs.sqlite3")
            let optographID = try db.prepare(optoID.select(id))
            print("getOptographIDsAsArray success")
            for x in optographID {
                let resultAsString = x[id]
                resultArray.append(resultAsString)
            }
            return resultArray
        } catch {
            print("getOptographIDsAsArray failed")
        }
        return resultArray
    }
    
    func getOptographs() -> [Optograph] {
        var resultArray = [Optograph]()
        do {
            let db = try Connection("\(path)/optographs.sqlite3")
            let optographID = try db.prepare(optoID)
            print("getOptographs success")
            for x in optographID {
                let tempOptograph = createNewOptographFromData(optographData: x)
                resultArray.append(tempOptograph)
            }
            return resultArray
        } catch {
            print("getOptographs failed")
        }
        return resultArray
    }
    
    func getUnstitchedOptographs() -> [Optograph] {
        var resultArray = [Optograph]()
        let foundOptographs = optoID.filter(isStitched == false)
        do {
            let db = try Connection("\(path)/optographs.sqlite3")
            let optographIDs = try db.prepare(foundOptographs)
            print("getUnstitchedOptographs success")
            for x in optographIDs {
                let tempOptograph = createNewOptographFromData(optographData: x)
                resultArray.append(tempOptograph)
            }
            return resultArray
        } catch {
            print("getUnstitchedOptographs failed  \(error)")
        }
        return resultArray
    }

    func getStitchedOptographs() -> [Optograph] {
        var resultArray = [Optograph]()
        let foundOptographs = optoID.filter(isStitched == true)
        do {
            let db = try Connection("\(path)/optographs.sqlite3")
            let optographIDs = try db.prepare(foundOptographs)
            print("getStitchedOptographs success")
            for x in optographIDs {
                let tempOptograph = createNewOptographFromData(optographData: x)
                resultArray.append(tempOptograph)
            }
            return resultArray
        } catch {
            print("getStitchedOptographs failed  \(error)")
        }
        return resultArray
    }


    func saveOptograph(optograph: Optograph) {
        let foundOptograph = optoID.filter(self.id == optograph.ID)
        do {
            let db = try Connection("\(path)/optographs.sqlite3")
            if(try db.run(foundOptograph.update(createdAt <- optograph.createdAt,
                                                 updatedAt <- optograph.updatedAt,
                                                 isStitched <- optograph.isStitched,
                                                 stitcherVersion <- optograph.stitcherVersion,
                                                 directionPhi <- optograph.directionPhi,
                                                 directionTheta <- optograph.directionTheta,
                                                 ringCount <- optograph.ringCount)) != 1) {
                print("update failed, no rows were updated")
            }
        } catch {
            print("update failed \(error)")
        }
    }
    
    func getOptograph(id: UUID) -> Optograph {
        let foundOptograph = optoID.filter(self.id == "\(id)")
        do {
            let db = try Connection("\(path)/optographs.sqlite3")
            let optographData = try db.prepare(foundOptograph)
            print("getOptograph success")
            for x in optographData {
                let result = createNewOptographFromData(optographData: x)
                return result;
            }
        } catch {
            print("getOptograph failed \(error)")
        }
        return Optograph.newInstance()
    }
    
    func deleteOptograph(optographID: String) {
        let foundOptograph = optoID.filter(id == optographID)
        do {
            let db = try Connection("\(path)/optographs.sqlite3")
            if (try db.run(foundOptograph.delete()) == 1) {
                print("Delete Access success")
            } else {
                print ("Delete Access Fail")
            }
        } catch {
            print("retreiving failed")
        }
    }
    
    private func createNewOptographFromData(optographData: Row) -> Optograph {
        var tempOptograph = Optograph.newInstance()
        tempOptograph.ID = optographData[id]
        tempOptograph.createdAt = optographData[createdAt]
        tempOptograph.updatedAt = optographData[updatedAt]
        tempOptograph.isStitched = optographData[isStitched]
        tempOptograph.stitcherVersion = optographData[stitcherVersion]
        tempOptograph.directionPhi = optographData[directionPhi]
        tempOptograph.directionTheta = optographData[directionTheta]
        tempOptograph.ringCount = optographData[ringCount]
        return tempOptograph
        
    }
}
