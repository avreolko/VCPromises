import XCTest
@testable import VCPromises

final class PromiseFinallyTests: XCTestCase {

    enum SomeError: Error { case foo, bar }

    func test_success_finally() {
        let expectation = self.expectation(description: "waiting for promise with final callback")
        Promise<Int>().finally { expectation.fulfill() }.fulfill(1)
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_fail_finally() {
        let expectation = self.expectation(description: "waiting for promise with final callback")
        Promise<Int>().finally { expectation.fulfill() }.reject(SomeError.bar)
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_finally_with_zip_success() {
        let expectation = self.expectation(description: "waiting for promise with final callback")
        expectation.expectedFulfillmentCount = 3

        let first = Promise<Int>().then { _ in expectation.fulfill() }
        let second = Promise<Int>().then { _ in expectation.fulfill() }

        first.fulfill(1)
        second.fulfill(2)

        first.zip(with: second).finally { expectation.fulfill() }

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_finally_with_zip_fail() {
        let expectation = self.expectation(description: "waiting for promise with final callback")
        expectation.expectedFulfillmentCount = 3

        let first = Promise<Int>().then { _ in expectation.fulfill() }
        let second = Promise<Int>().finally { expectation.fulfill() }

        first.fulfill(1)
        second.reject(SomeError.foo)

        first.zip(with: second).finally { expectation.fulfill() }

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_finally_with_chaining() {
        let promise = Promise<Int>()

        let expectation = self.expectation(description: "waiting for promise with final callback")
        expectation.expectedFulfillmentCount = 2

        promise
            .finally { expectation.fulfill() }
            .thenMap { String($0) }
            .finally { expectation.fulfill() }

        promise.fulfill(1)

        waitForExpectations(timeout: 0.1, handler: nil)
    }
}
