//
//  Promise+Then.swift
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

extension Promise {

    @discardableResult
    public func then<NewValue>(on queue: DispatchQueue = .main,
                               _ map: @escaping (Value) throws -> Promise<NewValue>) -> Promise<NewValue> {

        let work: Promise<NewValue>.Work = { fulfill, reject in

            let newFulfill: Success<Value> = { value in
                do {
                    try map(value).then(on: queue, fulfill, reject)
                } catch let error {
                    reject(error)
                }
            }

            self.addCallbacks(newFulfill, reject, queue)
        }

        return Promise<NewValue>(work)
    }

    @discardableResult
    public func thenMap<NewValue>(on queue: DispatchQueue = .main,
                                  _ map: @escaping (Value) throws -> NewValue) -> Promise<NewValue> {

        return self.then(on: queue, { (value) -> Promise<NewValue> in
            do {
                return Promise<NewValue>(value: try map(value))
            } catch let error {
                return Promise<NewValue>(error: error)
            }
        })
    }

    @discardableResult
    public func then(on queue: DispatchQueue = .main,
                     _ fulfill: @escaping (Value) -> Void,
                     _ reject: @escaping (Error) -> Void = { _ in }) -> Promise<Value> {
        self.addCallbacks(fulfill, reject, queue)
        return self
    }

    @discardableResult
    public func then(on queue: DispatchQueue = .main, _ fulfill: @escaping (Value) -> Void) -> Promise<Value> {
        return self.then(on: queue, fulfill, { _ in })
    }

    @discardableResult
    public func finally(on queue: DispatchQueue = .main, _ block: @escaping () -> Void) -> Promise<Value> {
        return self.then(on: queue, { _ in block() }, { _ in block() })
    }
}
