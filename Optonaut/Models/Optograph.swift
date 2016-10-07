//
//  Optograph.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import ReactiveCocoa
import Kingfisher

enum OptographAsset {
    case PreviewImage(NSData)
    case LeftImage(NSData)
    case RightImage(NSData)
}

typealias HashtagStrings = Array<String>

func ==(lhs: CubeTextureStatus, rhs: CubeTextureStatus) -> Bool {
    return lhs.status == rhs.status
}

struct CubeTextureStatus: SQLiteValue, Equatable {
    var status: [Bool] = [false, false, false, false, false, false]
    
    var completed: Bool {
        return status.reduce(true, combine: and)
    }
    
    static var declaredDatatype: String {
        return Int64.declaredDatatype
    }
    
    static func fromDatatypeValue(datatypeValue: Int64) -> CubeTextureStatus {
        var status = CubeTextureStatus()
        var val = datatypeValue
        for i in 0..<6 {
            status.status[i] = val % 2 == 1
            val /= 2
        }
        return status
    }
    
    var datatypeValue: Int64 {
        return (0..<6)
            .filter { self.status[$0] }
            .reduce(0) { Int64(pow(2, Double($1))) + $0 }
    }
}

struct Optograph: DeletableModel {
    
    var ID: UUID
    var text: String
    var personID: UUID
    var createdAt: NSDate
    var updatedAt: NSDate
    var deletedAt: NSDate?
    var isStarred: Bool
    var starsCount: Int
    var commentsCount: Int
    var viewsCount: Int
    var locationID: UUID?
    var isPrivate: Bool
    var isStitched: Bool
    var isSubmitted: Bool
    var isOnServer: Bool
    var isPublished: Bool
    var isUploading: Bool // not saved in db
    var stitcherVersion: String
    var shareAlias: String
    var leftCubeTextureStatusUpload: CubeTextureStatus?
    var rightCubeTextureStatusUpload: CubeTextureStatus?
    var leftCubeTextureStatusSave: CubeTextureStatus?
    var rightCubeTextureStatusSave: CubeTextureStatus?
    var isStaffPick: Bool
    var hashtagString: String
    var isInFeed: Bool
    var directionPhi: Double
    var directionTheta: Double
    var postFacebook: Bool
    var postTwitter: Bool
    var postInstagram: Bool
    var shouldBePublished: Bool
    var ringCount: String
    var storyID: UUID
    
    static func newInstance() -> Optograph {
        return Optograph(
            ID: uuid(),
            text: "",
            personID: "",
            createdAt: NSDate(),
            updatedAt: NSDate(),
            deletedAt: nil,
            isStarred: false,
            starsCount: 0,
            commentsCount: 0,
            viewsCount: 0,
            locationID: nil,
            isPrivate: false,
            isStitched: true,
            isSubmitted: true,
            isOnServer: true,
            isPublished: true,
            isUploading: false,
            stitcherVersion: "",
            shareAlias: "",
            leftCubeTextureStatusUpload: nil,
            rightCubeTextureStatusUpload: nil,
            leftCubeTextureStatusSave: nil,
            rightCubeTextureStatusSave: nil,
            isStaffPick: false,
            hashtagString: "",
            isInFeed: false,
            directionPhi: 0,
            directionTheta: 0,
            postFacebook: false,
            postTwitter: false,
            postInstagram: false,
            shouldBePublished: false,
            ringCount: "",
            storyID: ""
        )
    }
    
    mutating func delete() {
        deletedAt = NSDate()
    }
    
    func report() -> SignalProducer<EmptyResponse, ApiError> {
        return ApiService<EmptyResponse>.post("optographs/\(ID)/report")
    }
    
}

func ==(lhs: Optograph, rhs: Optograph) -> Bool {
    return lhs.ID                             == rhs.ID
        && lhs.text                           == rhs.text
        && lhs.personID                       == rhs.personID
        && lhs.createdAt                      == rhs.createdAt
        && lhs.updatedAt                      == rhs.updatedAt
        && lhs.deletedAt                      == rhs.deletedAt
        && lhs.isStarred                      == rhs.isStarred
        && lhs.starsCount                     == rhs.starsCount
        && lhs.commentsCount                  == rhs.commentsCount
        && lhs.viewsCount                     == rhs.viewsCount
        && lhs.locationID                     == rhs.locationID
        && lhs.isPrivate                      == rhs.isPrivate
        && lhs.isStitched                     == rhs.isStitched
        && lhs.isSubmitted                    == rhs.isSubmitted
        && lhs.isOnServer                     == rhs.isOnServer
        && lhs.isPublished                    == rhs.isPublished
        && lhs.isUploading                    == rhs.isUploading
        && lhs.stitcherVersion                == rhs.stitcherVersion
        && lhs.shareAlias                     == rhs.shareAlias
        && lhs.leftCubeTextureStatusUpload    == rhs.leftCubeTextureStatusUpload
        && lhs.rightCubeTextureStatusUpload   == rhs.rightCubeTextureStatusUpload
        && lhs.leftCubeTextureStatusSave      == rhs.leftCubeTextureStatusSave
        && lhs.rightCubeTextureStatusSave     == rhs.rightCubeTextureStatusSave
        && lhs.isStaffPick                    == rhs.isStaffPick
        && lhs.hashtagString                  == rhs.hashtagString
//        && lhs.isInFeed                       == rhs.isInFeed // needs to be excluded since an optograph can be both in a profile and feed
        && lhs.directionPhi                   == rhs.directionPhi
        && lhs.directionTheta                 == rhs.directionTheta
//        && lhs.postFacebook                   == rhs.postFacebook // needs to be excluded since this information is not exposed from REST api
//        && lhs.postTwitter                    == rhs.postTwitter // needs to be excluded since this information is not exposed from REST api
//        && lhs.postInstagram                  == rhs.postInstagram // needs to be excluded since this information is not exposed from REST api
//        && lhs.shouldBePublished              == rhs.shouldBePublished // needs to be excluded since this information is not exposed from REST api
}

extension Optograph: MergeApiModel {
    typealias AM = OptographApiModel
    
    mutating func mergeApiModel(apiModel: AM) {
        ID = apiModel.ID
        text = apiModel.text
        personID = apiModel.person.ID
        createdAt = apiModel.createdAt
        updatedAt = apiModel.updatedAt
        deletedAt = apiModel.deletedAt
        isStarred = apiModel.isStarred
        isPrivate = apiModel.isPrivate
        stitcherVersion = apiModel.stitcherVersion
        shareAlias = apiModel.shareAlias
        starsCount = apiModel.starsCount
        commentsCount = apiModel.commentsCount
        viewsCount = apiModel.viewsCount
        locationID = apiModel.location?.ID
        isStaffPick = apiModel.isStaffPick
        directionPhi = apiModel.directionPhi
        directionTheta = apiModel.directionTheta
        storyID = apiModel.story!.ID
    }
}

extension Optograph: SQLiteModel {
    
    static func schema() -> ModelSchema {
        return OptographSchema
    }
    
    static func table() -> SQLiteTable {
        return OptographTable
    }
    
    static func fromSQL(row: SQLiteRow) -> Optograph {
        let leftCubeTextureStatusUpload = row.get(OptographSchema.leftCubeTextureStatusUpload)
        let rightCubeTextureStatusUpload = row.get(OptographSchema.rightCubeTextureStatusUpload)
        let leftCubeTextureStatusSave = row.get(OptographSchema.leftCubeTextureStatusSave)
        let rightCubeTextureStatusSave = row.get(OptographSchema.leftCubeTextureStatusSave)
        
        return Optograph(
            ID: row[OptographSchema.ID],
            text: row[OptographSchema.text],
            personID: row[OptographSchema.personID],
            createdAt: row[OptographSchema.createdAt],
            updatedAt: row[OptographSchema.updatedAt],
            deletedAt: row[OptographSchema.deletedAt],
            isStarred: row[OptographSchema.isStarred],
            starsCount: row[OptographSchema.starsCount],
            commentsCount: row[OptographSchema.commentsCount],
            viewsCount: row[OptographSchema.viewsCount],
            locationID: row[OptographSchema.locationID],
            isPrivate: row[OptographSchema.isPrivate],
            isStitched: row[OptographSchema.isStitched],
            isSubmitted: row[OptographSchema.isSubmitted],
            isOnServer: row[OptographSchema.isOnServer],
            isPublished: row[OptographSchema.isPublished],
            isUploading: false,
            stitcherVersion: row[OptographSchema.stitcherVersion],
            shareAlias: row[OptographSchema.shareAlias],
            leftCubeTextureStatusUpload: leftCubeTextureStatusUpload,
            rightCubeTextureStatusUpload: rightCubeTextureStatusUpload,
            leftCubeTextureStatusSave: leftCubeTextureStatusSave,
            rightCubeTextureStatusSave: rightCubeTextureStatusSave,
            isStaffPick: row[OptographSchema.isStaffPick],
            hashtagString: row[OptographSchema.hashtagString],
            isInFeed: row[OptographSchema.isInFeed],
            directionPhi: row[OptographSchema.directionPhi],
            directionTheta: row[OptographSchema.directionTheta],
            postFacebook: row[OptographSchema.postFacebook],
            postTwitter: row[OptographSchema.postTwitter],
            postInstagram: row[OptographSchema.postInstagram],
            shouldBePublished: row[OptographSchema.shouldBePublished],
            ringCount: row[OptographSchema.ringCount],
            storyID: row[OptographSchema.storyID]
        )
    }
    
    func toSQL() -> [SQLiteSetter] {
        return [
            OptographSchema.ID <-- ID,
            OptographSchema.text <-- text,
            OptographSchema.personID <-- personID,
            OptographSchema.createdAt <-- createdAt,
            OptographSchema.updatedAt <-- updatedAt,
            OptographSchema.deletedAt <-- deletedAt,
            OptographSchema.isStarred <-- isStarred,
            OptographSchema.starsCount <-- starsCount,
            OptographSchema.commentsCount <-- commentsCount,
            OptographSchema.viewsCount <-- viewsCount,
            OptographSchema.locationID <-- locationID,
            OptographSchema.isPrivate <-- isPrivate,
            OptographSchema.isStitched <-- isStitched,
            OptographSchema.isSubmitted <-- isSubmitted,
            OptographSchema.isOnServer <-- isOnServer,
            OptographSchema.isPublished <-- isPublished,
            OptographSchema.stitcherVersion <-- stitcherVersion,
            OptographSchema.shareAlias <-- shareAlias,
            OptographSchema.leftCubeTextureStatusUpload <-- leftCubeTextureStatusUpload,
            OptographSchema.rightCubeTextureStatusUpload <-- rightCubeTextureStatusUpload,
            OptographSchema.leftCubeTextureStatusSave <-- leftCubeTextureStatusSave,
            OptographSchema.rightCubeTextureStatusSave <-- rightCubeTextureStatusSave,
            OptographSchema.isStaffPick <-- isStaffPick,
            OptographSchema.hashtagString <-- hashtagString,
            OptographSchema.isInFeed <-- isInFeed,
            OptographSchema.directionPhi <-- directionPhi,
            OptographSchema.directionTheta <-- directionTheta,
            OptographSchema.postFacebook <-- postFacebook,
            OptographSchema.postTwitter <-- postTwitter,
            OptographSchema.postInstagram <-- postInstagram,
            OptographSchema.shouldBePublished <-- shouldBePublished,
            OptographSchema.ringCount <-- ringCount,
            OptographSchema.storyID   <-- storyID
        ]
    }
    
}
