//
//  TypeConversion.swift
//  LibPQ
//
//  Created by Chris Eidhof on 28.06.19.
//

import Foundation

public enum OID: UInt32 { // https://doxygen.postgresql.org/include_2catalog_2pg__type_8h.html
    case bool = 16
    case int4 = 23 // This is a Swift.Int32 (4 bytes)
    case text = 25
    case varchar = 1043 // Swift String
    case timestamp = 1114
    case uuid = 2950
}

extension Int32: Param {
    public static let oid = OID.int4
    public var stringValue: String {
        return "\(self)"
    }
    
    public init(stringValue string: String) {
        self = Int32(string)!
    }
    
}

extension String: Param {
    public static let oid = OID.varchar
    public var stringValue: String { return self }
    public init(stringValue string: String) {
        self = string
    }
}

extension Bool: Param {
    public init(stringValue string: String) {
        switch string {
        case "f": self = false
        case "t": self = true
        default: fatalError("Unexpected value: \(string) for Bool")
        }
    }
    public var stringValue: String {
        return self ? "t" : "f"
    }
    public static let oid: OID = OID.bool
}

fileprivate let formatter: DateFormatter = {
    let d = DateFormatter()
    d.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    d.timeZone = TimeZone(abbreviation: "UTC")!
    return d
}()

extension Date: Param {
    static public let oid = OID.timestamp
    public var stringValue: String {
        return formatter.string(from: self)
    }
    public init(stringValue string: String) {
        self = formatter.date(from: string)!
    }
}

extension UUID: Param {
    static public let oid = OID.uuid
    public var stringValue: String {
        return uuidString
    }
    public init(stringValue string: String) {
        self.init(uuidString: string)!
    }
}
