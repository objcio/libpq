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


extension Array where Element == Optional<String> {
    func withCStringsAlt<Result>(_ f: ([UnsafePointer<Int8>?]) -> Result) -> Result {
        let cStrings: [UnsafeMutablePointer<Int8>?] = map { string in
            guard let s = string else { return nil }
            return strdup(s)
        }
        defer {
            for p in cStrings { p.map { free($0) } }
        }
        return f(cStrings.map { UnsafePointer($0) })
    }
}

final public class Connection {
    var connection: OpaquePointer?
    public init(connectionInfo: URL) throws {
        connection = PQconnectdb(connectionInfo.absoluteString)
        guard PQstatus(connection) == CONNECTION_OK else {
            connection = nil
            throw PostgresError(message: "Connection failed")
        }
    }
    
    @discardableResult public func execute(_ sql: String, _ params: [Param] = []) throws -> QueryResult {
        let result = params.map { $0.stringValue }.withCStringsAlt { pointers in
            PQexecParams(connection, sql, Int32(params.count), params.map { type(of: $0).oid.rawValue }, pointers, nil, nil, 0)
        }
        switch PQresultStatus(result) {
        case PGRES_COMMAND_OK:
            PQclear(result)
            return .ok
        case PGRES_TUPLES_OK:
            return .tuples(Tuples(result: result))
        default:
            PQclear(result)
            throw PostgresError(message: String(cString: PQerrorMessage(connection)))
        }        
    }
    
    public func close() {
        connection.map { PQfinish($0) }
        connection = nil
    }
    
    deinit {
        close()
    }
}

