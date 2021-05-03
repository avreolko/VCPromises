//
//  Promise+Catch.swift
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
    public func `catch`(on queue: DispatchQueue = .main, _ reject: @escaping (Error) -> Void) -> Promise<Value> {
        return self.then(on: queue, { _ in }, reject)
    }

    @discardableResult
    public func `catch`<ErrorType>(_ as: ErrorType.Type,
                                   on queue: DispatchQueue = .main,
                                   _ reject:  @escaping (ErrorType) -> Void) -> Promise<Value> {
        return self.catch { ($0 as? ErrorType).map { reject($0) } }
    }

    @discardableResult
    public func `catch`<ErrorType: Equatable>(_ error: ErrorType,
                                              on queue: DispatchQueue = .main,
                                              _ reject:  @escaping () -> Void) -> Promise<Value> {
        return self.catch { if error == ($0 as? ErrorType) { reject() } }
    }
}

