//
//  Connection.swift
//  LibPQ
//
//  Created by Chris Eidhof on 28.06.19.
//

import Foundation
import Clibpq

public struct PostgresError: Error {
    public let message: String
}


extension Array where Element == String {
    func withCStringsAlt<Result>(_ f: ([UnsafePointer<Int8>?]) -> Result) -> Result {
        let cStrings = map { strdup($0) }
        defer { cStrings.forEach { free($0) } }
        return f(cStrings.map { UnsafePointer($0) })
    }
    
}

final public class Connection {
    let connection: OpaquePointer
    public init(connectionInfo: String) throws {
        connection = PQconnectdb(connectionInfo)
        guard PQstatus(connection) == CONNECTION_OK else {
            throw PostgresError(message: "Connection failed")
        }
    }
    
    @discardableResult public func query(sql: String, params: [Param] = []) throws -> QueryResult {
        let result = params.map { $0.stringValue }.withCStringsAlt { pointers in
            PQexecParams(connection, sql, Int32(params.count), params.map { type(of: $0).oid.rawValue }, pointers, nil, nil, 0)
        }
        switch PQresultStatus(result) {
        case PGRES_COMMAND_OK:
            return .ok
        case PGRES_TUPLES_OK:
            return .tuples(Tuples(result: result))
        default:
            throw PostgresError(message: String(cString: PQerrorMessage(connection)))
        }
        
        // todo free pointers
    }
    
    public func close() {
        PQfinish(connection)
    }
    
    deinit {
        close()
    }
}

