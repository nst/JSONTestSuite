/* --------------------------------------------------------------------------------------------
 * Copyright (c) Kiad Studios, LLC. All rights reserved.
 * Licensed under the MIT License. See License in the project root for license information.
 * ------------------------------------------------------------------------------------------ */

extension JSValue {
    /// Attempts to treat the `JSValue` as a `JSObject` and perform the lookup.
    ///
    /// - returns: A `JSValue` that represents the value found at `key`
    public subscript(key: String) -> JSValue? {
        get {
            if let dict = self.object {
                if let value = dict[key] {
                    return value
                }
            }

            return nil
        }
        set {
            if var dict = self.object {
                dict[key] = newValue
                self = JSValue(dict)
            }
        }
    }
    
    /// Attempts to treat the `JSValue` as an array and return the item at the index.
    public subscript(index: Int) -> JSValue? {
        get {
            if let array = self.array {
                if index >= 0 && index < array.count {
                    return array[index]
                }
            }
            
            return nil
        }
        set {
            if var array = self.array {
                array[index] = newValue ?? .null
                self = JSValue(array)
            }
        }
    }
}
/*
/// Provide a usability extension to allow chaining index accessors without having to
/// marked it as optional.
/// e.g. foo["hi"]?["this"]?["sucks"] vs. foo["so"]["much"]["better"]
extension Optional where Wrapped == JSValue {
    public subscript(key: String) -> JSValue? {
        get {
            return self?.object?[key]
        }
        set {
            if var dict = self?.object {
                dict[key] = newValue
                self = JSValue(dict)
            }
        }
    }
    
    /// Attempts to treat the `JSValue` as an array and return the item at the index.
    public subscript(index: Int) -> JSValue? {
        get {
            return self?.array?[index]
        }
        set {
            if var array = self?.array {
                array[index] = newValue ?? .null
                self = JSValue(array)
            }
        }
    }
}
 */
