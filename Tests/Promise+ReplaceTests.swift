//
//  Promise+ReplaceTests.swift
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

import XCTest
@testable import VCPromises

final class PromiseReplaceTests: XCTestCase {

    func test_error_replace() {

        let expectation = self.expectation(description: "waiting for promise with flat map")

        let somePromise = Promise<Int>()
        let otherPromise: Promise<Int> = somePromise.replace { error in
            return Promise(value: 1)
        }

        otherPromise.then { value in
            XCTAssertEqual(value, 1)
            expectation.fulfill()
        }

        somePromise.reject(SomeError.bar)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_multiple_error_replacing() {

        let somePromise = Promise<Int>()

        let otherPromise: Promise<Int> = somePromise
            .replace { _ in Promise(error: SomeError.bar) }
            .replace { _ in Promise(error: SomeError.bar) }
            .replace { _ in Promise(error: SomeError.bar) }
            .replace { _ in Promise(error: SomeError.bar) }
            .replace { _ in Promise(value: 1) }

        let expectation = self.expectation(description: "waiting for promise with flat map")
        otherPromise.then { value in
            XCTAssertEqual(value, 1)
            expectation.fulfill()
        }

        somePromise.reject(SomeError.bar)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_error_replacing_from_other_functions() {

        let expectation = self.expectation(description: "waiting for promise with flat map")

        var counter = 0

        func makeSomePromise() -> Promise<Int> {

            let promise = Promise<Int>()

            counter += 1

            if counter < 10 {
                promise.reject(SomeError.bar)
            } else {
                promise.fulfill(1)
            }

            return promise.replace { error in makeSomePromise() }
        }

        makeSomePromise()
            .then { value in XCTAssert(value == 1); expectation.fulfill() }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_replace_fail() {

        let expectation = self.expectation(description: "waiting for promise with flat map")

        let somePromise = Promise<Int>()
        let otherPromise: Promise<Int> = somePromise.replaceFail { Promise(value: 1) }

        otherPromise.then { value in
            XCTAssertEqual(value, 1)
            expectation.fulfill()
        }

        somePromise.reject(SomeError.bar)

        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
