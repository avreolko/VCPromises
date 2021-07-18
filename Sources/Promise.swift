//
//  Promise.swift
//  VCPromises
//
//  Copyright © 2020 Valentin Cherepyanko. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

public typealias Success<T> = (T) -> Void
public typealias Failure = (Error) -> Void

struct Callback<Value> {

    private let fulfill: Success<Value>
    private let reject: Failure
    private let queue: DispatchQueue

    init(fulfill: @escaping Success<Value>,
         reject: @escaping Failure,
         queue: DispatchQueue) {

        self.fulfill = fulfill
        self.reject = reject
        self.queue = queue
    }

    func fulfill(with value: Value) {
        self.queue.async { self.fulfill(value) }
    }

    func reject(with error: Error) {
        self.queue.async { self.reject(error) }
    }
}

public class Promise<Value> {

    private let stateLock = NSRecursiveLock()

    public typealias Work = (_ fulfill: @escaping Success<Value>, _ reject: @escaping Failure) throws -> Void

    enum State<Value> {
        case pending([Callback<Value>])
        case fulfilled(Value)
        case rejected(Error)
    }

    private var state: State<Value>

    public init() {
        self.state = .pending([])
    }

    public init(value: Value) {
        self.state = .fulfilled(value)
    }

    public init(error: Error) {
        self.state = .rejected(error)
    }

    public convenience init(_ work: @escaping Work, on queue: DispatchQueue = .global(qos: .userInitiated)) {

        self.init()

        queue.async {
            do {
                try work(self.fulfill, self.reject)
            } catch let error {
                self.reject(error)
            }
        }
    }

    public func reject(_ error: Error) {
        self.updateState(.rejected(error))
    }

    public func fulfill(_ value: Value) {
        self.updateState(.fulfilled(value))
    }

    internal func addCallbacks(_ fulfill: @escaping Success<Value>,
                               _ reject: @escaping Failure,
                               _ queue: DispatchQueue) {

        let callback = Callback(fulfill: fulfill, reject: reject, queue: queue)

        self.stateLock.lock()

        switch self.state {
        case .pending(let callbacks):
            self.state = .pending(callbacks + [callback])
        case .fulfilled(let value):
            callback.fulfill(with: value)
        case .rejected(let error):
            callback.reject(with: error)
        }

        self.stateLock.unlock()
    }
}

internal extension Promise {
    var value: Value? {
        guard case .fulfilled(let value) = self.state else {
            return nil
        }

        return value
    }
}

private extension Promise {

    func updateState(_ newState: State<Value>) {

        self.stateLock.lock()

        guard case .pending(let callbacks) = self.state else { return }
        self.state = newState

        self.stateLock.unlock()

        switch newState {
        case .pending: break
        case .fulfilled(let value): callbacks.forEach { $0.fulfill(with: value) }
        case .rejected(let error): callbacks.forEach { $0.reject(with: error) }
        }
    }
}
