/* --------------------------------------------------------------------------------------------
 * Copyright (c) Kiad Studios, LLC. All rights reserved.
 * Licensed under the MIT License. See License in the project root for license information.
 * ------------------------------------------------------------------------------------------ */

/*
 * Provides extensions to the `JSValue` class that allows retrieval of the supported `JSValue.JSBackingValue` values.
 */

extension JSValue {
    
    /// Attempts to retrieve a `String` out of the `JSValue`.
    ///
    /// - returns: If the `JSValue` is a `String`, then the stored `String` value is returned, otherwise `nil`.
    public var string: String? {
        switch self {
        case .string(let value): return value
        default: return nil
        }
    }

    /// Attempts to retrieve a `Double` out of the `JSValue`.
    ///
    /// - returns: If the `JSValue` is a `JSNumber`, then the stored `Double` value is returned, otherwise `nil`.
    public var number: Double? {
        switch self {
        case .number(let value): return value
        default: return nil
        }
    }

    /// Attempts to retrieve an `Int` out of the `JSValue`.
    ///
    /// - returns: If the `JSValue` is a `Double`, then the stored `Double` value is returned, otherwise `nil`.
    public var integer: Int? {
        switch self {
        case .number(let value): return Int(value)
        default: return nil
        }
    }

    
    /// Attempts to retrieve a `Bool` out of the `JSValue`.
    ///
    /// - returns: If the `JSValue` is a `Bool`, then the stored `Bool` value is returned, otherwise `nil`.
    public var bool: Bool? {
        switch self {
        case .bool(let value): return value
        default: return nil
        }
    }

    /// Attempts to retrieve a `[String:JSValue]` out of the `JSValue`.
    ///
    /// - returns: If the `JSValue` is a `[String:JSValue]`, then the stored `[String:JSValue]` value is returned, otherwise `nil`.
    public var object: [String:JSValue]? {
        switch self {
        case .object(let value): return value
        default: return nil
        }
    }
    
    /// Attempts to retrieve a `[JSValue]` out of the `JSValue`.
    ///
    /// - returns: If the `JSValue` is a `JSArray`, then the stored `[JSValue]` value is returned, otherwise `nil`.
    public var array: [JSValue]? {
        switch self {
        case .array(let value): return value
        default: return nil
        }
    }
    
    /// Used to determine if a `nil` value is stored within `JSValue`. There is no intrinsic type for this value.
    ///
    /// - returns: If the `JSValue` is a `JSNull`, then the `true` is returned, otherwise `false`.
    public var null: Bool {
        switch self {
        case .null: return true
        default: return false
        }
    }
}
/*
/// Provide a usability extension to allow chaining index accessors without having to
/// marked it as optional.
/// e.g. foo["hi"]?["this"]?["sucks"]?.string vs. foo["so"]["much"]["better"].string
extension Optional where Wrapped == JSValue {
    /// Attempts to retrieve a `String` out of the `JSValue`.
    ///
    /// - returns: If the `JSValue` is a `String`, then the stored `String` value is returned, otherwise `nil`.
    public var string: String? {
        return self?.string
    }

    /// Attempts to retrieve a `Double` out of the `JSValue`.
    ///
    /// - returns: If the `JSValue` is a `JSNumber`, then the stored `Double` value is returned, otherwise `nil`.
    public var number: Double? {
        return self?.number
    }

    /// Attempts to retrieve an `Int` out of the `JSValue`.
    ///
    /// - returns: If the `JSValue` is a `Double`, then the stored `Double` value is returned, otherwise `nil`.
    public var integer: Int? {
        return self?.integer
    }

    
    /// Attempts to retrieve a `Bool` out of the `JSValue`.
    ///
    /// - returns: If the `JSValue` is a `Bool`, then the stored `Bool` value is returned, otherwise `nil`.
    public var bool: Bool? {
        return self?.bool
    }

    /// Attempts to retrieve a `[String:JSValue]` out of the `JSValue`.
    ///
    /// - returns: If the `JSValue` is a `[String:JSValue]`, then the stored `[String:JSValue]` value is returned, otherwise `nil`.
    public var object: [String:JSValue]? {
        return self?.object
    }
    
    /// Attempts to retrieve a `[JSValue]` out of the `JSValue`.
    ///
    /// - returns: If the `JSValue` is a `JSArray`, then the stored `[JSValue]` value is returned, otherwise `nil`.
    public var array: [JSValue]? {
        return self?.array
    }
    
    /// Used to determine if a `nil` value is stored within `JSValue`. There is no intrinsic type for this value.
    ///
    /// - returns: If the `JSValue` is a `JSNull`, then the `true` is returned, otherwise `false`.
    public var null: Bool {
        return self?.null ?? false
    }
}
 */
