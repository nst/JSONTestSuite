/* --------------------------------------------------------------------------------------------
 * Copyright (c) Kiad Studios, LLC. All rights reserved.
 * Licensed under the MIT License. See License in the project root for license information.
 * ------------------------------------------------------------------------------------------ */

/// A convenience type declaration for use with top-level JSON objects.
public typealias JSON = JSValue

/// The error domain for all `JSValue` related errors.
public let JSValueErrorDomain      = "com.kiadstudios.json.error"

/// A representative type for all possible JSON values.
///
/// See http://json.org for a full description.
public enum JSValue : Equatable {

    /// The maximum integer that is safely representable in JavaScript.
    public static let MaximumSafeInt: Int64 = 9007199254740991
    
    /// The minimum integer that is safely representable in JavaScript.
    public static let MinimumSafeInt: Int64 = -9007199254740991

    /// Holds an array of JavaScript values that conform to valid `JSValue` types.
    case array([JSValue])

    /// Holds an unordered set of key/value pairs conforming to valid `JSValue` types.
    case object([String : JSValue])

    /// Holds the value conforming to JavaScript's String object.
    case string(String)
    
    /// Holds the value conforming to JavaScript's Number object.
    case number(Double)
    
    /// Holds the value conforming to JavaScript's Boolean wrapper.
    case bool(Bool)
    
    /// Holds the value that corresponds to `null`.
    case null

    /// Initializes a new `JSValue` with a `[JSValue]` value.
    public init(_ value: [JSValue]) {
        self = .array(value)
    }

    /// Initializes a new `JSValue` with a `[String:JSValue]` value.
    public init(_ value: [String:JSValue]) {
        self = .object(value)
    }

    /// Initializes a new `JSValue` with a `String` value.
    public init(_ value: String) {
        self = .string(value)
    }

    /// Initializes a new `JSValue` with a `Double` value.
    public init(_ value: Double) {
        self = .number(value)
    }
    
    /// Initializes a new `JSValue` with a `Bool` value.
    public init(_ value: Bool) {
        self = .bool(value)
    }
}

// All of the stupid number-type initializers because of the lack of type conversion.
// Grr... convenience initializers not allowed in this context...
// Also... without the labels, Swift cannot seem to actually get the type inference correct (6.1b3)
extension JSValue {
    /// Convenience initializer for a `JSValue` with a non-standard `JSNumberType` value.
    public init(int8 value: Int8) {
        self = .number(Double(value))
    }

    /// Convenience initializer for a `JSValue` with a non-standard `JSNumberType` value.
    public init(in16 value: Int16) {
        self = .number(Double(value))
    }

    /// Convenience initializer for a `JSValue` with a non-standard `JSNumberType` value.
    public init(int32 value: Int32) {
        self = .number(Double(value))
    }

    /// Convenience initializer for a `JSValue` with a non-standard `JSNumberType` value.
    public init(int64 value: Int64) {
        self = .number(Double(value))
    }

    /// Convenience initializer for a `JSValue` with a non-standard `JSNumberType` value.
    public init(uint8 value: UInt8) {
        self = .number(Double(value))
    }
    
    /// Convenience initializer for a `JSValue` with a non-standard `JSNumberType` value.
    public init(uint16 value: UInt16) {
        self = .number(Double(value))
    }
    
    /// Convenience initializer for a `JSValue` with a non-standard `JSNumberType` value.
    public init(uint32 value: UInt32) {
        self = .number(Double(value))
    }
    
    /// Convenience initializer for a `JSValue` with a non-standard `JSNumberType` value.
    public init(uint64 value: UInt64) {
        self = .number(Double(value))
    }

    /// Convenience initializer for a `JSValue` with a non-standard `JSNumberType` value.
    public init(int value: Int) {
        self = .number(Double(value))
    }
    
    /// Convenience initializer for a `JSValue` with a non-standard `JSNumberType` value.
    public init(uint value: UInt) {
        self = .number(Double(value))
    }
    
    /// Convenience initializer for a `JSValue` with a non-standard `JSNumberType` value.
    public init(float value: Float) {
        self = .number(Double(value))
    }
}

extension JSValue: CustomStringConvertible {
    
    /// Attempts to convert the `JSValue` into its string representation.
    ///
    /// - parameter indent: the indent string to use; defaults to "  ". If `nil` is
    ///                     given, then the JSON is flattened.
    ///
    /// - returns: A `FailableOf<T>` that will contain the `String` value if successful,
    ///           otherwise, the `Error` information for the conversion.
    public func stringify(_ indent: String? = "  ") -> String {
        return prettyPrint(indent, 0)
    }
    
    /// Attempts to convert the `JSValue` into its string representation.
    ///
    /// - parameter indent: the number of spaces to include.
    ///
    /// - returns: A `FailableOf<T>` that will contain the `String` value if successful,
    ///           otherwise, the `Error` information for the conversion.
    public func stringify(_ indent: Int) -> String {
        let padding = (0..<indent).reduce("") { s, i in return s + " " }
        return prettyPrint(padding, 0)
    }
    
    /// Prints out the description of the JSValue value as pretty-printed JSValue.
    public var description: String {
        return stringify()
    }
}

/// Used to compare two `JSValue` values.
///
/// - returns: `True` when `hasValue` is `true` and the underlying values are the same; `false` otherwise.
public func ==(lhs: JSValue, rhs: JSValue) -> Bool {
    switch (lhs, rhs) {
    case (.null, .null):
        return true
        
    case let (.bool(lhsValue), .bool(rhsValue)):
        return lhsValue == rhsValue

    case let (.string(lhsValue), .string(rhsValue)):
        return lhsValue == rhsValue

    case let (.number(lhsValue), .number(rhsValue)):
        return lhsValue == rhsValue

    case let (.array(lhsValue), .array(rhsValue)):
        return lhsValue == rhsValue

    case let (.object(lhsValue), .object(rhsValue)):
        return lhsValue == rhsValue
        
    default:
        return false
    }
}

extension JSValue {
    func prettyPrint(_ indent: String?, _ level: Int) -> String {
        func escape(_ value: String) -> String {
            return value
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\t", with: "\\t")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")
        }

        var currentIndent = ""
        let nextIndentLevel = level + (indent == nil ? 0 : 1)

        for _ in (0..<level) {
            currentIndent += indent ?? ""
        }
        let nextIndent = currentIndent + (indent ?? "")
        
        let newline = (indent == nil || indent == "") ? "" : "\n"
        let space = indent == "" ? "" : " "
        
        switch self {
        case .bool(let bool):
            return bool ? "true" : "false"
            
        case .number(let number):
            // JSON only stores doubles (and only 54 bits of it!). If the number actually ends in just '.0',
            // truncate it here as it should really just be output as an integer value.
            var value = "\(number)"
            if value.hasSuffix(".0") {
                value = value.replacingOccurrences(of: ".0", with: "")
            }
            return value
            
        case .string(let string):
            return "\"\(escape(string))\""
            
        case .array(let array):
            let start = "[\(newline)"
            let content = (array.map({"\(nextIndent)\($0.prettyPrint(indent, nextIndentLevel))" })).joined(separator: ",\(newline)")
            let end = "\(newline)\(currentIndent)]"
            return start + content + end
            
        case .object(let dict):
            let start = "{\(newline)"
            let content = (dict.map({ "\(nextIndent)\"\(escape($0))\":\(space)\($1.prettyPrint(indent, nextIndentLevel))"})).joined(separator: ",\(newline)")
            let end = "\(newline)\(currentIndent)}"
            return start + content + end
            
        case .null:
            return "null"
            
        }
    }
}
