//
//  ProjectExtendLogServicesCoredata.swift
//  teamplan
//
//  Created by 크로스벨 on 6/18/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import CoreData

//MARK: Main

final class ProjectExtendLogServicesCoredata {
    typealias Entity = ProjectExtendLogEntity
    typealias Object = ProjectExtendLog
    
    var object = ProjectExtendLog()
    var objects = [ProjectExtendLog]()
    
    func setObject(context: NSManagedObjectContext, object: ProjectExtendLog) -> Bool {
        let entity = Entity(context: context)
        createEntity(entity: entity, with: object)
        return checkEntity(entity: entity)
    }

    func getObjects(context: NSManagedObjectContext, with projectId: Int, and userId: String) -> Bool {
        do {
            let entities = try getEntityList(context: context, with: projectId, and: userId)
            return convertToObjects(with: entities)
        } catch {
            print("[Coredata-ExtendLog] Failed to fetch objects: \(error)")
            return false
        }
    }

    func deleteObject(context: NSManagedObjectContext, with projectId: Int, and userId: String) throws {
        let entities = try getEntityList(context: context, with: projectId, and: userId)
        for entity in entities {
            context.delete(entity)
        }
    }

    func deleteObjects(context: NSManagedObjectContext, with userId: String) throws {
        let entities = try getTotalEntity(context: context, with: userId)
        for entity in entities {
            context.delete(entity)
        }
    }
}

//MARK: Context Related

extension ProjectExtendLogServicesCoredata {
    
    private func createEntity(entity: Entity, with object: Object) {
        entity.project_id = Int32(object.projectId)
        entity.extend_count = Int32(object.extendCount)
        entity.user_id = object.userId

        entity.used_drop = Int32(object.usedDrop)
        entity.stored_drop = Int32(object.storedDrop)

        entity.extend_period = Int32(object.extendPeriod)
        entity.extend_at = object.extendAt
        entity.new_deadline = object.newDeadline

        entity.registed_todo = Int32(object.totalRegistedTodo)
        entity.finished_todo = Int32(object.totalFinshedTodo)
    }

    private func checkEntity(entity: Entity) -> Bool {
        if entity.user_id == nil {
            print("[ExtendLogRepo] nil detected: 'user_id'")
            return false
        }
        if entity.extend_at == nil {
            print("[ExtendLogRepo] nil detected: 'extend_at'")
            return false
        }
        if entity.new_deadline == nil {
            print("[ExtendLogRepo] nil detected: 'new_deadline'")
            return false
        }
        return true
    }
    
    private func getEntityList(context: NSManagedObjectContext, with projectId: Int, and userId: String) throws -> [Entity] {
        let request: NSFetchRequest<Entity> = Entity.fetchRequest()
        request.predicate = NSPredicate(format: EntityPredicate.projectExtendLog.format, userId, projectId)
        return try context.fetch(request)
    }

    private func getTotalEntity(context: NSManagedObjectContext, with userId: String) throws -> [Entity] {
        let request: NSFetchRequest<Entity> = Entity.fetchRequest()
        request.predicate = NSPredicate(format: EntityPredicate.totalProjectExtendLog.format, userId)
        return try context.fetch(request)
    }
}

//MARK: Util

extension ProjectExtendLogServicesCoredata {
    
    private func convertToObject(with entity: Entity) -> Bool {
        guard let userId = entity.user_id,
              let extendAt = entity.extend_at,
              let newDeadline = entity.new_deadline
        else {
            print("[Coredata-ProjectExtendLog] Failed to convert entity to object")
            return false
        }
        let projectId = Int(entity.project_id)
        let extendCount = Int(entity.extend_count)

        let usedDrop = Int(entity.used_drop)
        let storedDrop = Int(entity.stored_drop)

        let extendPeriod = Int(entity.extend_period)
        let registedTodo = Int(entity.registed_todo)
        let finishedTodo = Int(entity.finished_todo)

        self.object = ProjectExtendLog(
            projectId: projectId,
            extendCount: extendCount,
            userId: userId,
            usedDrop: usedDrop,
            storedDrop: storedDrop,
            extendPeriod: extendPeriod,
            extendAt: extendAt,
            newDeadline: newDeadline,
            totalRegistedTodo: registedTodo,
            totalFinshedTodo: finishedTodo
        )
        return true
    }

    private func convertToObjects(with entities: [Entity]) -> Bool {
        self.objects = entities.compactMap { entity in
            guard let userId = entity.user_id,
                  let extendAt = entity.extend_at,
                  let newDeadline = entity.new_deadline
            else {
                print("[Coredata-ProjectExtendLog] Failed to convert entity to object")
                return nil
            }
            let projectId = Int(entity.project_id)
            let extendCount = Int(entity.extend_count)

            let usedDrop = Int(entity.used_drop)
            let storedDrop = Int(entity.stored_drop)

            let extendPeriod = Int(entity.extend_period)
            let registedTodo = Int(entity.registed_todo)
            let finishedTodo = Int(entity.finished_todo)

            return ProjectExtendLog(
                projectId: projectId,
                extendCount: extendCount,
                userId: userId,
                usedDrop: usedDrop,
                storedDrop: storedDrop,
                extendPeriod: extendPeriod,
                extendAt: extendAt,
                newDeadline: newDeadline,
                totalRegistedTodo: registedTodo,
                totalFinshedTodo: finishedTodo
            )
        }
        return !self.objects.isEmpty
    }
}
