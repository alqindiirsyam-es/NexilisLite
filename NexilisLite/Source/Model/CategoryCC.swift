//
//  CategoryCC.swift
//  NexilisLite
//
//  Created by Qindi on 20/06/22.
//

import Foundation

public class CategoryCC: Model {
    public var id: String
    public var service_id: String
    public var service_name: String
    public var parent: String
    public var description: String
    public var is_tablet: String
    public var isActive: Bool
    
    public static var default_parent = "-99"
    
    public init(id: String, service_id: String, service_name: String,parent: String, description: String, is_tablet: String, isActive:Bool = false) {
        self.id = id
        self.service_id = service_id
        self.service_name = service_name
        self.parent = parent
        self.description = description
        self.is_tablet = is_tablet
        self.isActive = isActive
    }
    
    public static func == (lhs: CategoryCC, rhs: CategoryCC) -> Bool {
        return lhs.service_id == rhs.service_id
    }
    
    public static func getDatafromParent(parent: String) -> [CategoryCC] {
        var data: [CategoryCC] = []
        Database.shared.database?.inTransaction({ fmdb, rollback in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select id, service_id, service_name, description, parent, is_tablet from SERVICE_BANK where parent = '\(parent)'") {
                    while cursor.next() {
                        data.append(CategoryCC(id: cursor.string(forColumnIndex: 0) ?? "",
                                               service_id: cursor.string(forColumnIndex: 1) ?? "",
                                               service_name: cursor.string(forColumnIndex: 2) ?? "",
                                               parent: cursor.string(forColumnIndex: 4) ?? "",
                                               description: cursor.string(forColumnIndex: 3) ?? "",
                                               is_tablet: cursor.string(forColumnIndex: 5) ?? ""))
                    }
                    cursor.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        return data
    }
    
    public static func getDataFromServiceId(service_id: String) -> CategoryCC? {
        var data: CategoryCC?
        Database.shared.database?.inTransaction({ fmdb, rollback in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select id, service_id, service_name, description, parent, is_tablet from SERVICE_BANK where service_id = '\(service_id)'"), cursor.next() {
                    data = CategoryCC(id: cursor.string(forColumnIndex: 0) ?? "",
                                      service_id: cursor.string(forColumnIndex: 1) ?? "",
                                      service_name: cursor.string(forColumnIndex: 2) ?? "",
                                      parent: cursor.string(forColumnIndex: 4) ?? "",
                                      description: cursor.string(forColumnIndex: 3) ?? "",
                                      is_tablet: cursor.string(forColumnIndex: 5) ?? "")
                    cursor.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        return data
    }
}
