//
//  JSON.encodings.swift
//  JSON
//
//  Created by David Owens II on 8/11/14.
//  Copyright (c) 2014 David Owens II. All rights reserved.
//
//
//extension JSValue {
//    /// Provides a set of all of the valid encoding types when using data that needs to be
//    /// within the contents of a string value.
//    public struct Encodings {
//        private init() {}
//        
//        /// The encoding prefix for all base64 encoded values.
//        public static let base64 = "data:text/plain;base64,"
//    }
//
//    /// Returns the raw dencoded bytes of the value that was stored in the `string` value.
//    public var decodedString: [UInt8]? {
//        switch self.value {
//        case .JSString(let encodedStringWithPrefix):
//            //            if encodedStringWithPrefix.hasPrefix(Encodings.base64.toRaw()) {
//            //                let encodedString = encodedStringWithPrefix.stringByReplacingOccurrencesOfString(Encodings.base64.toRaw(), withString: "")
//            //                let decoded = NSData(base64EncodedString: encodedString, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
//            //
//            //                let bytesPointer = UnsafePointer<Byte>(decoded.bytes)
//            //                let bytes = UnsafeBufferPointer<Byte>(start: bytesPointer, length: decoded.length)
//            //                return [Byte](bytes)
//            //            }
//            fatalError("nyi")
//            
//        default:
//            return nil
//            }
//            
//            return nil
//    }
//}