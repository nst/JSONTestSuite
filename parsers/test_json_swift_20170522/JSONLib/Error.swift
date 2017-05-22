/* --------------------------------------------------------------------------------------------
 * Copyright (c) Kiad Studios, LLC. All rights reserved.
 * Licensed under the MIT License. See License in the project root for license information.
 * ------------------------------------------------------------------------------------------ */

/// Represents error information for JSON parsing issues.
public final class JsonParserError: Swift.Error {
    public typealias ErrorInfoDictionary = [String:String]

    /// The error code used to differentiate between various error states.
    public let code: Int

    /// A string that is used to group errors into related error buckets.
    public let domain: String

    /// A place to store any custom information that needs to be passed along with the error instance.
    public let userInfo: ErrorInfoDictionary?


    /// Initializes a new `Error` instance.
    public init(code: Int, domain: String, userInfo: ErrorInfoDictionary?) {
        self.code = code
        self.domain = domain
        self.userInfo = userInfo
    }
}

/// The standard keys used in `Error` and `userInfo`.
public struct ErrorKeys {
    private init() {}
    
    public static let LocalizedDescription                   = "NSLocalizedDescription"
    public static let LocalizedFailureReason                 = "NSLocalizedFailureReason"
    public static let LocalizedRecoverySuggestion            = "NSLocalizedRecoverySuggestion"
    public static let LocalizedRecoveryOptions               = "NSLocalizedRecoveryOptions"
    public static let RecoveryAttempter                      = "NSRecoveryAttempter"
    public static let HelpAnchor                             = "NSHelpAnchor"
    
    public static let StringEncoding                         = "NSStringEncoding"
    public static let URL                                    = "NSURL"
    public static let FilePath                               = "NSFilePath"
}

extension JsonParserError: CustomStringConvertible {
    public var description: String {
        return "Error code: \(self.code), domain: \(self.domain)\ninfo: \(String(describing: self.userInfo))"
    }
}
