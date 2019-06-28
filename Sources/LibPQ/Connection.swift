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

public struct Row: Collection {
    public let index: Int32
    public let result: Tuples
    
    public var startIndex: Int32 {
        return 0
    }
    public var endIndex: Int32 {
        return result.numberOfFields
    }
    
    public func index(after i: Int32) -> Int32 {
        return i + 1
    }
    
    public subscript(info column: Int32) -> (oid: OID, name: String, value: String) {
        return (result.oid(column: column), result.name(column: column), self[column])
    }
    
    public subscript(index: Int32) -> String {
        return String(cString: result.value(row: self.index, column: index))
    }
}

extension Row: CustomStringConvertible {
    public var description: String {
        let x = (0..<result.numberOfFields).map {
            (result.name(column: $0), result.oid(column: $0), String(cString: result.value(row: index, column: $0)))
        }
        return "\(x)"
    }
}

public class Tuples: Collection {
    fileprivate let result: OpaquePointer?
    init(result: OpaquePointer?) {
        self.result = result
    }
    
    deinit {
        PQclear(result)
    }
    
    public var startIndex: Int32 {
        return 0
    }
    
    public var endIndex: Int32 {
        return PQntuples(result)
    }
    
    public func index(after i: Int32) -> Int32 {
        return i + 1
    }
    
    public func oid(column: Int32) -> OID {
        let type = PQftype(result, column)
        guard let oid = OID(rawValue: type) else {
            fatalError("Unkown OID \(type)")
        }
        return oid
    }
    
    public var numberOfFields: Int32 {
        return PQnfields(result)
    }
    
    public func name(column: Int32) -> String {
        return String(cString: PQfname(result, column))
    }
    
    public func value(row: Int32, column: Int32) -> UnsafeMutablePointer<Int8> {
        return PQgetvalue(result, row, column)
    }
    
    public subscript(index: Int32) -> Row {
        return Row(index: index, result: self)
    }
}

extension Tuples: CustomStringConvertible {
    public var description: String {
        if numberOfFields == 1 {
            return "\(self[0])"
        } else {
        	return "\(Array(self))"
        }
    }
}

public protocol Param {
    static var oid: OID { get }
    var stringValue: String { get }
    init(stringValue string: String)
}

public enum QueryResult {
    case tuples(Tuples)
    case ok
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
    deinit {
        PQfinish(connection)
    }
}

