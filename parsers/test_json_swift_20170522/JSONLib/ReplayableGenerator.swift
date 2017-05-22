/* --------------------------------------------------------------------------------------------
 * Copyright (c) Kiad Studios, LLC. All rights reserved.
 * Licensed under the MIT License. See License in the project root for license information.
 * ------------------------------------------------------------------------------------------ */

/// Creates a `GeneratorType` that is able to "replay" its previous value on the next `next()` call.
/// Useful for generator sequences in which you need to simply step-back a single element.
public final class ReplayableGenerator: IteratorProtocol, Swift.Sequence {
    public typealias Element = UInt8

    var firstRun = true
    var usePrevious = false
    var previousElement: UInt8? = nil
    var buffer: UnsafeBufferPointer<UInt8>
    var offset = 0

    /// Initializes a new `ReplayableGenerator` with an underlying `UnsafeBufferPointer<UInt8>`.
    /// - parameter sequence: the sequence that will be used to traverse the content.
    public init(_ buffer: UnsafeBufferPointer<UInt8>) {
        self.buffer = buffer
    }

    /// Moves the current element to the next element in the collection, if one exists.
    /// :return: The `current` element or `nil` if the element does not exist.
    public func next() -> Element? {
        if usePrevious {
            usePrevious = false
        }
        else {
            previousElement = offset >= buffer.count ? nil : buffer[offset]
            offset += 1
        }

        return previousElement
    }

    /// Ensures that the next call to `next()` will use the current value.
    public func replay() {
        usePrevious = true
    }

    /// Creates a generator that can be used to traversed the content. Each call to
    /// `generate` will call `replay()`.
    ///
    /// :return: A iterable collection backing the content.
    public func makeIterator() -> ReplayableGenerator {
        if firstRun {
            firstRun = false
            offset = 0
            usePrevious = false
            previousElement = nil
        }
        else {
            self.replay()
        }

        return self
    }

    /// Determines if the generator is at the end of the collection's content.
    ///
    /// :return: `true` if there more content in the collection to view, `false` otherwise.
    public func atEnd() -> Bool {
        let element = next()
        replay()

        return element == nil
    }
}
