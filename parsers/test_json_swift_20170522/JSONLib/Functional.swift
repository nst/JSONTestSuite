/* --------------------------------------------------------------------------------------------
 * Copyright (c) Kiad Studios, LLC. All rights reserved.
 * Licensed under the MIT License. See License in the project root for license information.
 * ------------------------------------------------------------------------------------------ */

precedencegroup FunctionalPrecedence {
  associativity: left
  higherThan: MultiplicationPrecedence
}

infix operator ⇒ : FunctionalPrecedence

/// Allows for a transformative function to be applied to a value, allowing for optionals.
///
/// - parameter lhs: The transformative function
/// - parameter rhs: The value to apply to the function
/// - returns: The transformation of `rhs` using `lhs`.
public func ⇒ <A, B>(lhs: ((A) -> B)?, rhs: A?) -> B? {
    if let lhs = lhs {
        if let rhs = rhs {
            return lhs(rhs)
        }
    }
    
    return nil
}

/// Allows for a value to be transformed by a function, allowing for optionals.
///
/// - parameter lhs: The value to apply to the function
/// - parameter rhs: The transformative function
/// - returns: The transformation of `lhs` using `rhs`.
public func ⇒ <A, B>(lhs: A?, rhs: ((A) -> B)?) -> B? {
    if let lhs = lhs {
        if let rhs = rhs {
            return rhs(lhs)
        }
    }
    
    return nil
}

/// Allows for a transformative function to be applied to a value.
///
/// - parameter lhs: The transformative function
/// - parameter rhs: The value to apply to the function
/// - returns: The transformation of `rhs` using `lhs`.
public func ⇒ <A, B>(lhs: (A) -> B, rhs: A) -> B { return lhs(rhs) }


/// Allows for a value to be transformed by a function.
///
/// - parameter lhs: The value to apply to the function
/// - parameter rhs: The transformative function
/// - returns: The transformation of `lhs` using `rhs`.
public func ⇒ <A, B>(lhs: A, rhs: (A) -> B) -> B { return rhs(lhs) }
