//
//  Promise+ThenTests.swift
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

final class PromiseThenTests: XCTestCase {

    enum SomeError: Error { case foo, bar }

    func test_multiple_thens() {
        let promise = Promise<Void>()

        let expectation = self.expectation(description: "waiting for promise with multiple thens")
        expectation.expectedFulfillmentCount = 3

        promise
            .then { _ in expectation.fulfill() }
            .then { _ in expectation.fulfill() }
            .then { _ in expectation.fulfill() }

        promise.fulfill(())

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_then_before_fulfill() {
        let promise = Promise<Int>()
        promise.fulfill(3)

        let expectation = self.expectation(description: "waiting for promise that already fulfilled")
        promise.then { value in
            XCTAssertEqual(3, value)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_then_after_fulfill() {
        let promise = Promise<Int>()

        let expectation = self.expectation(description: "waiting for promise that not yet fulfilled")
        promise.then { value in
            XCTAssertEqual(5, value)
            expectation.fulfill()
        }

        promise.fulfill(5)

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_chaining() {

        let expectation = self.expectation(description: "waiting for promise that not yet fulfilled")

        func doSomething() -> Promise<Int> { return Promise(value: 1) }
        func doAnotherThing(_ int: Int) -> Promise<String> { return Promise(value: String(int)) }
        func lastThing(_ string: String) { expectation.fulfill(); XCTAssertEqual(string, "1") }

        doSomething().then(doAnotherThing).then(lastThing)

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_complex_chaining() {

        let expectation = self.expectation(description: "waiting for promise that not yet fulfilled")

        func number(_ counter: Int) -> Promise<Int> { .init(value: counter) }
        func increment(_ value: Int) -> Promise<Int> { .init(value: value + 1) }
        func sum(_ values: (Int, Int, Int)) -> Promise<Int> { .init(value: values.0 + values.1 + values.2) }
        func confirm(_ value: Int) { expectation.fulfill(); XCTAssertEqual(value, 8) }

        number(1)
            .then(increment)
            .zip(with: number(3), and: number(3))
            .then(sum)
            .then(confirm)

        waitForExpectations(timeout: 0.1, handler: nil)
    }
}
