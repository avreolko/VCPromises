//
//  Promise+FlattenTests.swift
//  
//
//  Created by Черепянко Валентин Александрович on 18/04/2020.
//

import XCTest
@testable import VCPromises

final class PromiseFlattenTests: XCTestCase {
    func test_simple_case() {

        let workQueue = DispatchQueue(label: "work.queue", attributes: .concurrent)
        let expectation = self.expectation(description: "waiting for promise")
        expectation.expectedFulfillmentCount = 11

        let range = (0..<10000)
        let unsortedArray = range.map { _ in Int.random(in: range) }

        let makePromise: () -> Promise<[Int]> = {
            let work: Promise<[Int]>.Work = { fulfill, _ in
                fulfill(unsortedArray.sorted())
                expectation.fulfill()
                XCTAssertEqual(currentQueueLabel, "work.queue")
            }
            return Promise(work, on: workQueue)
        }

        let promises = (0..<10).map { _ in makePromise() }

        flatten(promises, on: .main).then { values in
            values.forEach { XCTAssertEqual($0, values.first!) }
            expectation.fulfill()
            XCTAssertEqual(currentQueueLabel, "com.apple.main-thread")
        }

        waitForExpectations(timeout: 1, handler: nil)
    }
}
