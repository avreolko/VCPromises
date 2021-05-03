//
//  Promise+Zip.swift
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
    public func zip<U>(with other: Promise<U>,
                       on queue: DispatchQueue = .main) -> Promise<(Value, U)> {

        let work: Promise<(Value, U)>.Work = { (fulfill, reject) in

            let combine = {
                guard let first = self.value, let second = other.value else { return }
                fulfill((first, second))
            }

            self.then(on: queue, { _ in combine() }, reject)
            other.then(on: queue, { _ in combine() }, reject)
        }

        return Promise<(Value, U)>(work)
    }

    @discardableResult
    public func zip<T1, T2>(with second: Promise<T1>,
                            and third: Promise<T2>,
                            on queue: DispatchQueue = .main) -> Promise<(Value, T1, T2)> {

        let work: Promise<(Value, T1, T2)>.Work = { (fulfill, reject) in
            self.zip(with: second, on: queue)
                .zip(with: third, on: queue)
                .then(on: queue, { fulfill(($0.0.0, $0.0.1, $0.1)) }, reject)
        }

        return Promise<(Value, T1, T2)>(work)
    }

    @discardableResult
    public func zip<T1, T2, T3>(with second: Promise<T1>,
                                and third: Promise<T2>,
                                and fourth: Promise<T3>,
                                on queue: DispatchQueue = .main) -> Promise<(Value, T1, T2, T3)> {

        let work: Promise<(Value, T1, T2, T3)>.Work = { (fulfill, reject) in
            self.zip(with: second, and: third, on: queue)
                .zip(with: fourth, on: queue)
                .then(on: queue, { fulfill(($0.0.0, $0.0.1, $0.0.2, $0.1)) }, reject)
        }

        return Promise<(Value, T1, T2, T3)>(work)
    }

    @discardableResult
    public func zip<T1, T2, T3, T4>(with second: Promise<T1>,
                                    and third: Promise<T2>,
                                    and fourth: Promise<T3>,
                                    and fifth: Promise<T4>,
                                    on queue: DispatchQueue = .main) -> Promise<(Value, T1, T2, T3, T4)> {

        let work: Promise<(Value, T1, T2, T3, T4)>.Work = { (fulfill, reject) in
            self.zip(with: second, and: third, on: queue)
                .zip(with: fourth, and: fifth, on: queue)
                .then(on: queue, { fulfill(($0.0.0, $0.0.1, $0.0.2, $0.1, $0.2)) }, reject)
        }

        return Promise<(Value, T1, T2, T3, T4)>(work)
    }
}

