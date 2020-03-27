//
//  VCPromisesTests.swift
//  VCPromisesTests
//
//  Created by Valentin Cherepyanko on 16.01.2020.
//  Copyright © 2020 Valentin Cherepyanko. All rights reserved.
//

import XCTest
@testable import VCPromises

final class VCPromisesTests: XCTestCase {

    enum SomeError: Error { case foo }

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

    func test_error_catch_after_reject() {

        let promise = Promise<Int>()
        promise.reject(SomeError.foo)

        let expectation = self.expectation(description: "waiting for promise with error after")
        promise.catch { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_error_catch_before_reject() {
        let promise = Promise<Int>()

        let expectation = self.expectation(description: "waiting for promise with error before")
        promise.catch { _ in
            expectation.fulfill()
        }

        promise.reject(SomeError.foo)

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

    func test_success() {
        let promise = Promise<Success>()

        let expectation = self.expectation(description: "waiting for promise with success")
        promise.then {
            expectation.fulfill()
        }

        promise.fulfill()
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_success_map() {
        let promise = Promise<Success>()

        let expectation = self.expectation(description: "waiting for promise with success")
        promise.thenMap {
            return 5
        }.then { value in
            XCTAssertEqual(5, value)
            expectation.fulfill()
        }

        promise.fulfill()
        waitForExpectations(timeout: 0.1, handler: nil)
    }
}
