//
//  Promise+Flatten.swift
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

public func flatten<T>(_ promises: [Promise<T>], on queue: DispatchQueue = .main) -> Promise<[T]> {

    let work: Promise<[T]>.Work = { fulfill, reject in
        let group = DispatchGroup()

        var values: [T] = []

        promises.forEach {
            group.append($0, fulfill: { values.append($0) }, reject: reject)
        }

        group.notify(queue: queue) {
            guard values.count == promises.count else { return }
            fulfill(values)
        }
    }

    return Promise(work, on: queue)
}

private extension DispatchGroup {
    func append<T>(_ promise: Promise<T>, fulfill: @escaping (T) -> Void, reject: @escaping (Error) -> Void) {
        self.enter()
        promise.then { fulfill($0); self.leave() }
        promise.catch { reject($0); self.leave() }
    }
}
