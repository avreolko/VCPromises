//
//  VCPromisesTests.swift
//  VCPromisesTests
//
//  Created by Valentin Cherepyanko on 16.01.2020.
//  Copyright © 2020 Valentin Cherepyanko. All rights reserved.
//

import XCTest
@testable import VCPromises

class VCPromisesTests: XCTestCase {

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

    func test_map() {
        let intPromise = Promise<Int>()
        let stringPromise = intPromise.thenMap(String.init)

        let expectation = self.expectation(description: "waiting for promise with map")

        stringPromise.then { value in
            XCTAssertEqual(value, "10")
            expectation.fulfill()
        }

        intPromise.fulfill(10)

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_flat_map() {
        let somePromise = Promise<Int>()

        let otherPromise: Promise<String> = somePromise.thenFlatMap { int in
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

        waitForExpectations(timeout: 0.1, handler: nil)
    }
}
