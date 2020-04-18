//
//  PromiseThenTests.swift
//  VCPromisesTests
//
//  Created by Valentin Cherepyanko on 16.01.2020.
//  Copyright © 2020 Valentin Cherepyanko. All rights reserved.
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
}
