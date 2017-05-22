/* --------------------------------------------------------------------------------------------
 * Copyright (c) Kiad Studios, LLC. All rights reserved.
 * Licensed under the MIT License. See License in the project root for license information.
 * ------------------------------------------------------------------------------------------ */

extension JSValue : ExpressibleByIntegerLiteral {
    private static func convert(_ value: Int64) -> JSValue {
        return JSValue(Double(value))
    }

    public init(integerLiteral value: Int64) {
        self = JSValue.convert(value)
    }
}

extension JSValue : ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = JSValue(value)
    }
}

extension JSValue : ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = JSValue(value)
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self = JSValue(value)
    }
	
    public init(unicodeScalarLiteral value: String) {
		self = JSValue(value)
	}
}

extension JSValue : ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JSValue...) {
        self = JSValue(elements)
    }
}

extension JSValue : ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, JSValue)...) {
        var dict = [String:JSValue]()
        for (k, v) in elements {
            dict[k] = v
        }
        
        self = JSValue(dict)
    }
}

extension JSValue : ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension JSValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = JSValue(value)
    }
}
