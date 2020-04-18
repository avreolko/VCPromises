//
//  Promises+QueuingTests.swift
//  
//
//  Created by Черепянко Валентин Александрович on 18/04/2020.
//

import Foundation

import XCTest
@testable import VCPromises

final class PromisesQueuingTests: XCTestCase {

    enum SomeError: Error { case foo, bar }

    func test_queue_switching() {
        let firstQueue = DispatchQueue(label: "first")
        let secondQueue = DispatchQueue(label: "second")
        let thirdQueue = DispatchQueue(label: "third")

        let promise = Promise<Int>(queue: firstQueue)
        promise.fulfill(1)

        let expectation = self.expectation(description: "waiting for promise with multiple queue switches")
        expectation.expectedFulfillmentCount = 3

        promise
            .finally { XCTAssertEqual(currentQueueLabel, "first"); expectation.fulfill() }
            .thenMap(on: secondQueue) { $0 }
            .finally { XCTAssertEqual(currentQueueLabel, "second"); expectation.fulfill() }
            .thenMap(on: thirdQueue) { $0 }
            .finally { XCTAssertEqual(currentQueueLabel, "third"); expectation.fulfill() }

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_single_queue() {
        let queue = DispatchQueue(label: "someQueue")

        let promise = Promise<Int>(queue: queue)
        promise.fulfill(1)

        let expectation = self.expectation(description: "waiting for promise with single queue")
        expectation.expectedFulfillmentCount = 3

        promise
            .finally { XCTAssertEqual(currentQueueLabel, "someQueue"); expectation.fulfill() }
            .thenMap { $0 }
            .finally { XCTAssertEqual(currentQueueLabel, "someQueue"); expectation.fulfill() }
            .thenMap { $0 }
            .finally { XCTAssertEqual(currentQueueLabel, "someQueue"); expectation.fulfill() }

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

    func test_some_hard_work() {

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
            .zip(with: second, and: third, on: notifyQueue)
            .then { values in
                let (firstArr, secondArr, thirdArr) = values
                XCTAssertEqual(firstArr, secondArr)
                XCTAssertEqual(secondArr, thirdArr)
                XCTAssertEqual(currentQueueLabel, "notify.queue")
                expectation.fulfill()
            }

        waitForExpectations(timeout: 0.2, handler: nil)
    }
}

internal var currentQueueLabel: String? {
    let name = __dispatch_queue_get_label(nil)
    return String(cString: name, encoding: .utf8)
}
