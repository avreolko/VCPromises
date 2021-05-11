//
//  Promise+Replace.swift
//  VCPromises
//
//  Created by Valentin Cherepyanko on 10.05.2021.
//  Copyright © 2021 Valentin Cherepyanko. All rights reserved.
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
    public func replace(
        on queue: DispatchQueue = .main,
        _ map: @escaping (Error) throws -> Promise<Value>
    ) -> Promise<Value> {

        let work: Promise<Value>.Work = { fulfill, reject in

            let newReject: Failure = { error in
                do {
                    try map(error).then(on: queue, fulfill, reject)
                } catch let error {
                    reject(error)
                }
            }

            self.addCallbacks(fulfill, newReject, queue)
        }

        return Promise<Value>(work)
    }

    @discardableResult
    public func replaceFail(
        on queue: DispatchQueue = .main,
        _ replace: @escaping () throws -> Promise<Value>
    ) -> Promise<Value> {

        let work: Promise<Value>.Work = { fulfill, reject in

            let newReject: Failure = { _ in
                do {
                    try replace().then(on: queue, fulfill, reject)
                } catch let error {
                    reject(error)
                }
            }

            self.addCallbacks(fulfill, newReject, queue)
        }

        return Promise<Value>(work)
    }
}
