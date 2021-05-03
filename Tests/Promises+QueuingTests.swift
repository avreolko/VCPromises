//
//  Promise+QueuingTests.swift
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

final class PromisesQueuingTests: XCTestCase {

    enum SomeError: Error { case foo, bar }

    func test_queue_switching() {
        let firstQueue = DispatchQueue(label: "first")
        let secondQueue = DispatchQueue(label: "second")
        let thirdQueue = DispatchQueue(label: "third")

        let promise = Promise<Int>()
        promise.fulfill(1)

        let expectation = self.expectation(description: "waiting for promise with multiple queue switches")
        expectation.expectedFulfillmentCount = 3

        promise
            .finally(on: firstQueue) { XCTAssertEqual(currentQueueLabel, "first"); expectation.fulfill() }
            .finally(on: secondQueue) { XCTAssertEqual(currentQueueLabel, "second"); expectation.fulfill() }
            .finally(on: thirdQueue) { XCTAssertEqual(currentQueueLabel, "third"); expectation.fulfill() }

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_single_queue() {
        let queue = DispatchQueue(label: "someQueue")

        let promise = Promise<Int>()
        promise.fulfill(1)

        let expectation = self.expectation(description: "waiting for promise with single queue")
        expectation.expectedFulfillmentCount = 3

        promise
            .finally(on: queue) { XCTAssertEqual(currentQueueLabel, "someQueue"); expectation.fulfill() }
            .finally(on: queue) { XCTAssertEqual(currentQueueLabel, "someQueue"); expectation.fulfill() }
            .finally(on: queue) { XCTAssertEqual(currentQueueLabel, "someQueue"); expectation.fulfill() }

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_default_queue() {

        let promise = Promise<Int>()
        promise.fulfill(1)

        let expectation = self.expectation(description: "waiting for promise with single queue")
        expectation.expectedFulfillmentCount = 3

        promise
            .finally { XCTAssertEqual(currentQueueLabel, "com.apple.main-thread"); expectation.fulfill() }
            .thenMap { $0 }
            .finally { XCTAssertEqual(currentQueueLabel, "com.apple.main-thread"); expectation.fulfill() }
            .thenMap { $0 }
            .finally { XCTAssertEqual(currentQueueLabel, "com.apple.main-thread"); expectation.fulfill() }

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_some_hard_work_on_background_thread_and_zipping_in_another() {

        let expectation = self.expectation(description: "waiting for promise with single queue")
        expectation.expectedFulfillmentCount = 4

        let workQueue = DispatchQueue(label: "work.queue", attributes: .concurrent)
        let notifyQueue = DispatchQueue(label: "notify.queue", attributes: .concurrent)

        let range = (0..<10000)
        let unsortedArray = range.map { _ in Int.random(in: range) }

        let work: Promise<[Int]>.Work = { fulfill, _ in
            fulfill(unsortedArray.sorted())
            expectation.fulfill()
            XCTAssertEqual(currentQueueLabel, "work.queue")
        }

        let promise = Promise(work, on: workQueue)
        let second = Promise(work, on: workQueue)
        let third = Promise(work, on: workQueue)

        promise
            .zip(with: second, and: third)
            .then(on: notifyQueue) { values in
                let (firstArr, secondArr, thirdArr) = values
                XCTAssertEqual(firstArr, secondArr)
                XCTAssertEqual(secondArr, thirdArr)
                XCTAssertEqual(currentQueueLabel, "notify.queue")
                expectation.fulfill()
            }

        waitForExpectations(timeout: 0.2, handler: nil)
    }

    func test_zip_concurrency() {

        let expectation = self.expectation(description: "waiting for promise with single queue")
        expectation.expectedFulfillmentCount = 1

        let workQueue = DispatchQueue(label: "work.queue", attributes: .concurrent)
        let notifyQueue = DispatchQueue(label: "notify.queue", attributes: .concurrent)

        let makePromise: (Int) -> Promise<Int> = { value in
            let work: Promise<Int>.Work = { fulfill, _ in
                workQueue.asyncAfter(deadline: .now() + 0.5, execute: { fulfill(value) })
                XCTAssertEqual(currentQueueLabel, "work.queue")
            }
            return Promise(work, on: workQueue)
        }

        makePromise(1).zip(
            with: makePromise(2),
            and: makePromise(3),
            and: makePromise(4),
            and: makePromise(5)
        ).then(on: notifyQueue) { values in
            XCTAssertEqual(values.0, 1)
            XCTAssertEqual(values.1, 2)
            XCTAssertEqual(values.2, 3)
            XCTAssertEqual(values.3, 4)
            XCTAssertEqual(values.4, 5)
            expectation.fulfill()
            XCTAssertEqual(currentQueueLabel, "notify.queue")
        }

        waitForExpectations(timeout: 0.6, handler: nil)
    }
}

internal var currentQueueLabel: String? {
    let name = __dispatch_queue_get_label(nil)
    return String(cString: name, encoding: .utf8)
}
