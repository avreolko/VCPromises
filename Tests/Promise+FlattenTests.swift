//
//  Promise+FlattenTests.swift
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

final class PromiseFlattenTests: XCTestCase {
    func test_performance_on_a_concurrent_queue() {

        let worksCount = 10

        let workQueue = DispatchQueue(label: "work.queue", attributes: .concurrent)
        let expectation = self.expectation(description: "waiting for promise")
        expectation.expectedFulfillmentCount = worksCount + 1

        let range = (0..<25000)
        let unsortedArray = range.map { _ in Int.random(in: range) }

        let makePromise: (Int) -> Promise<[Int]> = { number in
            let work: Promise<[Int]>.Work = { fulfill, _ in
                evaluate(number) { fulfill(unsortedArray.sorted()) }
                expectation.fulfill()
                XCTAssertEqual(currentQueueLabel, "work.queue")
            }
            return Promise(work, on: workQueue)
        }

        var promises: [Promise<[Int]>] = []

        promises = (1..<worksCount+1).map { makePromise($0) }

        evaluate(0) {
            flatten(promises, on: .main).then { values in
                values.forEach { XCTAssertEqual($0, values.first!) }
                expectation.fulfill()
                XCTAssertEqual(currentQueueLabel, "com.apple.main-thread")
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_race_condition_with_multiple_queues() {
        let worksCount = 100

        let expectation = self.expectation(description: "waiting for promise")
        expectation.expectedFulfillmentCount = worksCount + 1

        let range = (0..<1000)
        let unsortedArray = range.map { _ in Int.random(in: range) }

        let makePromise: (Int) -> Promise<[Int]> = { number in
            let queueLabel = "work.queue.\(number)"

            let workQueue = Bool.random()
                ? DispatchQueue(label: queueLabel, attributes: .concurrent)
                : DispatchQueue(label: queueLabel)

            let work: Promise<[Int]>.Work = { fulfill, _ in
                fulfill(unsortedArray.sorted())
                expectation.fulfill()
                XCTAssertEqual(currentQueueLabel, queueLabel)
            }
            return Promise(work, on: workQueue)
        }

        var promises: [Promise<[Int]>] = []

        promises = (1..<worksCount+1).map { makePromise($0) }

        flatten(promises, on: .main).then { values in
            values.forEach { XCTAssertEqual($0, values.first!) }
            expectation.fulfill()
            XCTAssertEqual(currentQueueLabel, "com.apple.main-thread")
        }

        waitForExpectations(timeout: 1, handler: nil)
    }
}

private func evaluate(_ problemNumber: Int, _ problemBlock: () -> Void)
{
    let start = DispatchTime.now()
    problemBlock()
    let end = DispatchTime.now()

    let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
    let timeInterval = Double(nanoTime) / 1_000_000_000

    print("Time to evaluate problem \(problemNumber): \(timeInterval) seconds")
}
