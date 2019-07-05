//
//  TypeConversion.swift
//  LibPQ
//
//  Created by Chris Eidhof on 28.06.19.
//

import Foundation

public protocol Param {
    static var oid: OID { get }
    var stringValue: String? { get }
    init(stringValue string: String?)
}

// "SELECT typname, oid from pg_type;"
public enum OID: UInt32 { // https://doxygen.postgresql.org/include_2catalog_2pg__type_8h.html
    case bool = 16
    case int2 = 21
    case int4 = 23 // This is a Swift.Int32 (4 bytes)
    case int8 = 20
    case text = 25
    case varchar = 1043 // Swift String
    case timestamp = 1114
    case uuid = 2950
    case float4 = 700
    case float8 = 701
}

extension Int: Param {
    public static let oid = OID.int8
    public var stringValue: String? { return "\(self)" }
    public init(stringValue string: String?) { self = Int(string!)! }
}

extension Int64: Param {
    public static let oid = OID.int8
    public var stringValue: String? { return "\(self)" }
    public init(stringValue string: String?) { self = Int64(string!)! }
}

extension Int32: Param {
    public static let oid = OID.int4
    public var stringValue: String? { return "\(self)" }
    public init(stringValue string: String?) { self = Int32(string!)! }
}


extension Int16: Param {
    public static let oid = OID.int2
    public var stringValue: String? { return "\(self)" }
    public init(stringValue string: String?) { self = Int16(string!)! }
}

extension Int8: Param {
    public static let oid = OID.int2
    public var stringValue: String? { return "\(self)" }
    public init(stringValue string: String?) { self = Int8(string!)! }
}

extension UInt: Param {
    public static let oid = OID.int8
    public var stringValue: String? { return "\(self)" }
    public init(stringValue string: String?) { self = UInt(string!)! }
}

extension UInt64: Param {
    public static let oid = OID.int8
    public var stringValue: String? { return "\(self)" }
    public init(stringValue string: String?) { self = UInt64(string!)! }
}

extension UInt32: Param {
    public static let oid = OID.int4
    public var stringValue: String? { return "\(self)" }
    public init(stringValue string: String?) { self = UInt32(string!)! }
}

extension UInt16: Param {
    public static let oid = OID.int2
    public var stringValue: String? { return "\(self)" }
    public init(stringValue string: String?) { self = UInt16(string!)! }
}

extension UInt8: Param {
    public static let oid = OID.int2
    public var stringValue: String? { return "\(self)" }
    public init(stringValue string: String?) { self = UInt8(string!)! }
}


extension String: Param {
    public static let oid = OID.varchar
    public var stringValue: String? { return self }
    public init(stringValue string: String?) {
        self = string!
    }
}

extension Double: Param {
    public static let oid = OID.float8
    public var stringValue: String? { return "\(self)" }
    public init(stringValue string: String?) { self = Double(string!)! }
}

extension Float: Param {
    public static let oid = OID.float4
    public var stringValue: String? { return "\(self)" }
    public init(stringValue string: String?) { self = Float(string!)! }
}

extension Bool: Param {
    public init(stringValue string: String?) {
        switch string {
        case "f": self = false
        case "t": self = true
        default: fatalError("Unexpected value: \(string!) for Bool")
        }
    }
    public var stringValue: String? {
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

fileprivate let formatterWithoutMilliseconds: DateFormatter = {
    let d = DateFormatter()
    d.dateFormat = "yyyy-MM-dd HH:mm:ss"
    d.timeZone = TimeZone(abbreviation: "UTC")!
    return d
}()

extension Date: Param {
    static public let oid = OID.timestamp
    public var stringValue: String? {
        return formatter.string(from: self)
    }
    public init(stringValue string: String?) {
        self = formatter.date(from: string!) ?? formatterWithoutMilliseconds.date(from: string!)!
    }
}

extension Optional: Param where Wrapped: Param {
    static public var oid: OID { return Wrapped.oid }
    public init(stringValue string: String?) {
        self = string.flatMap { Wrapped(stringValue: $0) }
    }
    public var stringValue: String? {
        return flatMap { $0.stringValue }
    }
    
}

extension UUID: Param {
    static public let oid = OID.uuid
    public var stringValue: String? {
        return uuidString
    }
    public init(stringValue string: String?) {
        self.init(uuidString: string!)!
    }
}
