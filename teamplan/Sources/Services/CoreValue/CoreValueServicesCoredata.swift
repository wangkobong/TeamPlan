//
//  CoreValueServicesCoredata.swift
//  teamplan
//
//  Created by 크로스벨 on 3/15/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import CoreData

final class CoreValueServicesCoredata: ReadOnlyEntityManage {
    typealias Entity = CoreValueEntity
    typealias Object = CoreValueObject
    
    var context: NSManagedObjectContext
    
    init(coredataController: CoredataProtocol) {
        self.context = coredataController.context
    }
    
    func getObject(with userId: String) throws -> CoreValueObject {
        let entity = try getEntity(with: userId)
        return try convertToObject(with: entity)
    }
}

extension CoreValueServicesCoredata {

    private func getEntity(with userId: String) throws -> CoreValueEntity {
        let fetchPredicate = NSPredicate(format: EntityPredicate.coreValue.rawValue, userId)
        guard let entity = try fetchEntity(with: fetchPredicate) else{
            throw CoreValueErrorCD.UnexpectedFetchError
        }
        return entity
    }
    
    private func convertToObject(with entity: CoreValueEntity) throws -> CoreValueObject {
        guard let object = CoreValueObject(entity: entity) else {
            throw CoreValueErrorCD.UnexpectedConvertError
        }
        return object
    }
}

enum CoreValueErrorCD: LocalizedError {
    case UnexpectedFetchError
    case UnexpectedConvertError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedFetchError:
            return "Coredata: There was an unexpected error while Fetch 'CoreValue' details"
        case .UnexpectedConvertError:
            return "Coredata: There was an unexpected error while Convert 'CoreValue' details"
        }
    }
}
