//
//  WorkingArea.swift
//  NexilisLite
//
//  Created by Qindi on 19/07/22.
//

import Foundation

public class WorkingArea: Model {
    public var id: String
    public var area_id: String
    public var name: String
    public var parent: String
    public var level: String
    public var description: String
    
    public init(id: String, area_id: String, name: String, parent: String, level: String) {
        self.id = id
        self.area_id = area_id
        self.name = name
        self.parent = parent
        self.level = level
        self.description = ""
    }
    
    public static func == (lhs: WorkingArea, rhs: WorkingArea) -> Bool {
        return lhs.area_id == rhs.area_id
    }
    
    public static func getData(name: String) -> [WorkingArea] {
        var data: [WorkingArea] = []
        Database.shared.database?.inTransaction({ fmdb, rollback in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select id, area_id, name, parent, level from WORKING_AREA where name LIKE '%\(name.lowercased())%'") {
                    while cursor.next() {
                        data.append(WorkingArea(id: cursor.string(forColumnIndex: 0) ?? "",
                                                area_id: cursor.string(forColumnIndex: 1) ?? "",
                                                name: cursor.string(forColumnIndex: 2) ?? "",
                                                parent: cursor.string(forColumnIndex: 3) ?? "",
                                                level: cursor.string(forColumnIndex: 4) ?? ""))
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
}
