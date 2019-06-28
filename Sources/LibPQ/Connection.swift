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

public enum OID: UInt32 { // https://doxygen.postgresql.org/include_2catalog_2pg__type_8h.html
    case int4 = 23 // This is a Swift.Int32 (4 bytes)
    case varchar = 1043 // Swift String
}

public struct Row {
    public let index: Int32
    public let result: Tuples
    
    public subscript(column: Int32) -> String {
//        dump(PQftype(result.result, column))
        assert(PQftype(result.result, column) == OID.varchar.rawValue)
        return String(cString: result.value(row: index, column: column))
    }
    
    public subscript(column: Int32) -> Int32 {
        assert(PQftype(result.result, column) == OID.int4.rawValue)
        let ptr = result.value(row: index, column: column)
        return ptr.withMemoryRebound(to: Int32.self, capacity: 1) { intPtr in
            Int32(bigEndian: intPtr.pointee)
        }
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

public protocol Param {
    static var oid: OID { get }
    var binaryValue: Data { get }
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
        let data = params.map { $0.binaryValue }
        let pointers: [UnsafePointer<Int8>?] = data.map { data in
            let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
            data.copyBytes(to: pointer, count: data.count)
            return UnsafeRawPointer(pointer).assumingMemoryBound(to: Int8.self)
        }
        defer {
            for (pointer, data) in zip(pointers,data) {
                UnsafeMutablePointer(mutating: pointer!).deallocate()
            }
        }
        
        let result = PQexecParams(connection, sql, Int32(params.count), params.map { type(of: $0).oid.rawValue }, pointers, data.map { Int32($0.count) }, params.map { _ in 1 }, 1)
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

extension Int32: Param {
    public static let oid = OID.int4
    public var binaryValue: Data {
        var copy = bigEndian
        return Data(bytes: &copy, count: 4)
    }
}

extension String: Param {
    public static let oid = OID.varchar
    public var binaryValue: Data {
        return data(using: .utf8)!
    }
}
