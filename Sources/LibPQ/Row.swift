//
//  Row.swift
//  LibPQ
//
//  Created by Chris Eidhof on 02.07.19.
//

import Foundation
import Clibpq

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
    
    public func isNull(index: Int32) -> Bool {
        return PQgetisnull(result.result, self.index, index) == 1
    }
}

extension Row {
    public subscript<P: Param>(name: String) -> P? {
        return result.columnIndex(of: name).map { P.init(stringValue: self[$0]) }
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
