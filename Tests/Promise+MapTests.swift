//
//  Promise+MapTests.swift
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

final class PromiseMapTests: XCTestCase {

    func test_map() {
        let intPromise = Promise<Int>()
        let stringPromise = intPromise.thenMap(String.init)

        let expectation = self.expectation(description: "waiting for promise with map")

        stringPromise.then { value in
            XCTAssertEqual(value, "10")
            expectation.fulfill()
        }

        intPromise.fulfill(10)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_flat_map() {
        let somePromise = Promise<Int>()

        let otherPromise: Promise<String> = somePromise.then { int in
            let promise = Promise<String>()
            promise.fulfill(String(int))
            return promise
        }

        let expectation = self.expectation(description: "waiting for promise with flat map")
        otherPromise.then { value in
            XCTAssertEqual(value, "8")
            expectation.fulfill()
        }

        somePromise.fulfill(8)

        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
