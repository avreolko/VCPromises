//
//  PromiseCatchTests.swift
//  VCPromisesTests
//
//  Created by Valentin Cherepyanko on 16.01.2020.
//  Copyright © 2020 Valentin Cherepyanko. All rights reserved.
//

import XCTest
@testable import VCPromises

final class PromiseCatchTests: XCTestCase {

    enum SomeError: Error { case foo, bar }

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
}
