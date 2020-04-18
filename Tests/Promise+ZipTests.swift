//
//  VCPromisesTests.swift
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
}
