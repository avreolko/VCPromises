//
//  PromiseZipTests.swift
//  VCPromisesTests
//
//  Created by Valentin Cherepyanko on 16.01.2020.
//  Copyright © 2020 Valentin Cherepyanko. All rights reserved.
//

import XCTest
@testable import VCPromises

final class PromiseZipTests: XCTestCase {

    enum SomeError: Error { case foo, bar }

    func test_two_zip_success() {

        let p1 = Promise<Int>()
        let p2 = Promise<String>()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            p1.fulfill(3)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            p2.fulfill("3")
        }

        let expectation = self.expectation(description: "waiting for promise that not yet fulfilled")

        p1
            .zip(with: p2)
            .then { _ in expectation.fulfill() }

        waitForExpectations(timeout: 0.3, handler: nil)
    }

    func test_two_zip_fail_one() {

        let mainPromise = Promise<Int>()
        let otherPromise = Promise<String>()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            mainPromise.reject(SomeError.foo)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            otherPromise.fulfill("string")
        }

        let expectation = self.expectation(description: "waiting for promise that not yet fulfilled")

        mainPromise
            .zip(with: otherPromise)
            .then { _ in XCTFail() }
            .catch { _ in expectation.fulfill() }

        waitForExpectations(timeout: 0.3, handler: nil)
    }

    func test_two_zip_fail_two() {

        let mainPromise = Promise<Int>()
        let otherPromise = Promise<String>()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            mainPromise.reject(SomeError.foo)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            otherPromise.reject(SomeError.bar)
        }

        let expectation = self.expectation(description: "waiting for promise that not yet fulfilled")
        expectation.expectedFulfillmentCount = 1

        mainPromise
            .zip(with: otherPromise)
            .then { _ in XCTFail() }
            .catch { expectation.fulfill(); XCTAssertTrue($0 is SomeError) }

        waitForExpectations(timeout: 0.3, handler: nil)
    }

    func test_two_zip_on_other_queue() {

        let mainPromise = Promise<Int>()
        let otherPromise = Promise<String>()

        let queueLabel = "Other.Queue"

        let otherQueue = DispatchQueue(label: queueLabel, attributes: .concurrent)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            mainPromise.fulfill(0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            otherPromise.fulfill("hi")
        }

        let expectation = self.expectation(description: "waiting for promise that not yet fulfilled")

        mainPromise
            .zip(with: otherPromise, on: otherQueue)
            .then { _ in
                expectation.fulfill()

                let name = __dispatch_queue_get_label(nil)
                XCTAssertEqual(String(cString: name, encoding: .utf8), queueLabel)
        }

        waitForExpectations(timeout: 0.3, handler: nil)
    }

    func test_three_zip_success() {
        let first = Promise<Int>()
        let second = Promise<Int>()
        let third = Promise<Int>()

        first.fulfill(1)
        second.fulfill(2)
        third.fulfill(3)

        let expectation = self.expectation(description: "waiting for promise that not yet fulfilled")

        first.zip(with: second, and: third).then {
            XCTAssertEqual($0.0, 1)
            XCTAssertEqual($0.1, 2)
            XCTAssertEqual($0.2, 3)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_three_zip_fail() {
        let first = Promise<Int>()
        let second = Promise<Int>()
        let third = Promise<Int>()

        first.fulfill(1)
        second.fulfill(2)
        third.reject(SomeError.foo)

        let expectation = self.expectation(description: "waiting for promise that not yet fulfilled")

        first
            .zip(with: second, and: third)
            .then { _ in XCTFail() }
            .catch { _ in expectation.fulfill() }

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_zip_underlying_then_interaction() {

        let expectation = self.expectation(description: "waiting for promise that not yet fulfilled")
        expectation.expectedFulfillmentCount = 3

        let first = Promise<Int>().then { _ in expectation.fulfill() }
        let second = Promise<Int>().then { _ in expectation.fulfill() }

        first.fulfill(1)
        second.fulfill(2)

        first.zip(with: second).then { _ in expectation.fulfill() }

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_zip_underlying_reject_interaction() {
        let expectation = self.expectation(description: "waiting for promise that not yet fulfilled")
        expectation.expectedFulfillmentCount = 3

        let first = Promise<Int>().then { _ in expectation.fulfill() }
        let second = Promise<Int>().catch { _ in expectation.fulfill() }

        first.fulfill(1)
        second.reject(SomeError.foo)

        first.zip(with: second).catch { _ in expectation.fulfill() }

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_zip_multiple_errors() {
        let expectation = self.expectation(description: "waiting for promise that not yet fulfilled")

        let first = Promise<Int>()
        let second = Promise<Int>()

        first.reject(SomeError.bar)
        second.reject(SomeError.foo)

        first.zip(with: second).catch { _ in expectation.fulfill() }

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_nested_zips() {

        let makePromise: (Int) -> Promise<Int> = {
            let promise = Promise<Int>()
            promise.fulfill($0)
            return promise
        }

        let nested1 = makePromise(2).zip(
            with: makePromise(3),
            and: makePromise(4)
        )

        let nested2 = makePromise(5).zip(
            with: makePromise(6),
            and: makePromise(7)
        )

        makePromise(1)
            .zip(with: nested1, and: nested2)
            .then { values in
                let (v1, (v2, v3, v4), (v5, v6, v7)) = values
                XCTAssertEqual(v1, 1)
                XCTAssertEqual(v2, 2)
                XCTAssertEqual(v3, 3)
                XCTAssertEqual(v4, 4)
                XCTAssertEqual(v5, 5)
                XCTAssertEqual(v6, 6)
                XCTAssertEqual(v7, 7)
            }
    }
}
