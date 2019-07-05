//
//  Result.swift
//  LibPQ
//
//  Created by Chris Eidhof on 02.07.19.
//

import Foundation
import Clibpq

public class Tuples: Collection {
    let result: OpaquePointer?
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
    
    public func columnIndex(of name: String) -> Int32? {
        let num = PQfnumber(result, name)
        return num >= 0 ? num : nil
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

public enum QueryResult {
    case tuples(Tuples)
    case ok
}
