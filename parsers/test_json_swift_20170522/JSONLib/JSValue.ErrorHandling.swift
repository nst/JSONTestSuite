/* --------------------------------------------------------------------------------------------
 * Copyright (c) Kiad Studios, LLC. All rights reserved.
 * Licensed under the MIT License. See License in the project root for license information.
 * ------------------------------------------------------------------------------------------ */

extension JSValue {
    
    /// A type that holds the error code and standard error message for the various types of failures
    /// a `JSValue` can have.
    public struct ErrorMessage {
        /// The numeric value of the error number.
        public let code: Int
        
        /// The default message describing the error.
        public let message: String
    }
    
    /// All of the error codes and standard error messages when parsing JSON.
    public struct ErrorCode {
        private init() {}
        
        /// A integer that is outside of the safe range was attempted to be set.
        public static let InvalidIntegerValue = ErrorMessage(
            code:1,
            message: "The specified number is not valid. Valid numbers are within the range: [\(JSValue.MinimumSafeInt), \(JSValue.MaximumSafeInt)]")
        
        /// Error when attempting to access an element from a `JSValue` backed by a dictionary and there is no
        /// value stored at the specified key.
        public static let KeyNotFound = ErrorMessage(
            code: 2,
            message: "The specified key cannot be found.")
        
        /// Error when attempting to index into a `JSValue` that is not backed by a dictionary or array.
        public static let IndexingIntoUnsupportedType = ErrorMessage(
            code: 3,
            message: "Indexing is only supported on arrays and dictionaries."
        )
        
        /// Error when attempting to access an element from a `JSValue` backed by an array and the index is
        /// out of range.
        public static let IndexOutOfRange = ErrorMessage(
            code: 4,
            message: "The specified index is out of range of the bounds for the array.")

        /// Error when a parsing error occurs.
        public static let ParsingError = ErrorMessage(
            code: 5,
            message: "The JSON string being parsed was invalid.")
    }
}
