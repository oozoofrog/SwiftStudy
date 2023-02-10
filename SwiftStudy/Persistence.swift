//
//  Persistence.swift
//  SwiftStudy
//
//  Created by oozoofrog on 2023/02/01.
//

import CoreData
import AppKit

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for i in 0..<10 {
            let newItem = Commit(context: viewContext)
            newItem.date = Date()
            newItem.commit = UUID().uuidString
            newItem.comment = "comment \(i)"
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SwiftStudy")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func save() async {
        let context = container.viewContext
        do {
            try await context.perform({
                try context.save()
            })
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    func insert(_ lines: [CommitLine]) async throws -> Void {
        return try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    defer {
                        continuation.resume(returning: ())
                    }
                    let objects = lines.map(\.dictionary)
                    let request = NSBatchInsertRequest(entity: Commit.entity(), objects: objects)
                    request.resultType = .objectIDs
                    guard let result = try context.execute(request) as? NSBatchInsertResult else {
                        return
                    }
                    guard let ids = result.result as? [NSManagedObjectID] else {
                        return
                    }
                    if ids.isEmpty {
                        return
                    }
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSInsertedObjectIDsKey: ids], into: [container.viewContext])

                    try context.save()
                } catch {
                    context.rollback()
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func checkAll(until commit: Commit) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    defer {
                        continuation.resume(returning: ())
                    }
                    let trueRequest = NSBatchUpdateRequest(entity: Commit.entity())
                    trueRequest.predicate = NSPredicate(format: "date <= %@", commit.date! as NSDate)
                    trueRequest.propertiesToUpdate = ["checked": true]
                    trueRequest.resultType = .updatedObjectIDsResultType

                    let falseRequest = NSBatchUpdateRequest(entity: Commit.entity())
                    falseRequest.predicate = NSPredicate(format: "date > %@ && checked == true", commit.date! as NSDate)
                    falseRequest.propertiesToUpdate = ["checked": false]
                    falseRequest.resultType = .updatedObjectIDsResultType

                    let trueResult = try! context.execute(trueRequest) as! NSBatchUpdateResult
                    let falseResult = try! context.execute(falseRequest) as! NSBatchUpdateResult

                    if let trues = trueResult.result as? [NSManagedObjectID] {
                        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSUpdatedObjectIDsKey: trues], into: [container.viewContext])
                    }
                    if let falses = falseResult.result as? [NSManagedObjectID] {
                        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSUpdatedObjectIDsKey: falses], into: [container.viewContext])
                    }

                    try context.save()
                } catch {
                    context.rollback()
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func deleteAll(_ limit: Int = 10000) async throws {
        return try await withCheckedThrowingContinuation({ continuation in
            self.container.performBackgroundTask { context in
                do {
                    defer {
                        continuation.resume(returning: ())
                    }
                    let request = NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: "Commit"))
                    request.resultType = .resultTypeObjectIDs
                    guard let result = try context.execute(request) as? NSBatchDeleteResult else {
                        return
                    }
                    guard let ids = result.result as? [NSManagedObjectID] else {
                        return
                    }
                    if ids.isEmpty {
                        return
                    }
                    for offset in 0..<(ids.count / limit + 1) {
                        let start = offset * limit
                        let end = min(start + limit, ids.count)
                        let ids = Array(ids[(offset * limit)..<end])
                        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectIDsKey: ids], into: [container.viewContext])
                    }
                    try context.save()
                } catch {
                    context.rollback()
                    continuation.resume(throwing: error)
                }
            }
        })
    }
}
