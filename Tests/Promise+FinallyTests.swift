//
//  Promise+FinallyTests.swift
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

import XCTest
@testable import VCPromises

final class PromiseFinallyTests: XCTestCase {

    func test_success_finally() {
        let expectation = self.expectation(description: "waiting for promise with final callback")
        Promise<Int>().finally { expectation.fulfill() }.fulfill(1)
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_fail_finally() {
        let expectation = self.expectation(description: "waiting for promise with final callback")
        Promise<Int>().finally { expectation.fulfill() }.reject(SomeError.bar)
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_finally_with_zip_success() {
        let expectation = self.expectation(description: "waiting for promise with final callback")
        expectation.expectedFulfillmentCount = 3

        let first = Promise<Int>().then { _ in expectation.fulfill() }
        let second = Promise<Int>().then { _ in expectation.fulfill() }

        first.fulfill(1)
        second.fulfill(2)

        first.zip(with: second).finally { expectation.fulfill() }

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_finally_with_zip_fail() {
        let expectation = self.expectation(description: "waiting for promise with final callback")
        expectation.expectedFulfillmentCount = 3

        let first = Promise<Int>().then { _ in expectation.fulfill() }
        let second = Promise<Int>().finally { expectation.fulfill() }

        first.fulfill(1)
        second.reject(SomeError.foo)

        first.zip(with: second).finally { expectation.fulfill() }

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_finally_with_chaining() {
        let promise = Promise<Int>()

        let expectation = self.expectation(description: "waiting for promise with final callback")
        expectation.expectedFulfillmentCount = 3

        promise
            .finally { expectation.fulfill() }
            .thenMap { String($0) }
            .finally { expectation.fulfill() }
            .then { XCTAssert($0 == "1"); expectation.fulfill() }

        promise.fulfill(1)

        waitForExpectations(timeout: 0.1, handler: nil)
    }
}
