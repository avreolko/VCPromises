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

    func test_then_error_catching() {

        let expectation = self.expectation(description: "waiting for promise that already fulfilled")

        func someWork() throws -> Int {
            throw SomeError.foo
        }

        let work: Promise<Int>.Work = { fulfill, _ in
            let result = try someWork()
            fulfill(result)
        }

        Promise(work, on: .global(qos: .userInitiated))
            .then(on: .main) { _ in XCTFail() }
            .catch { _ in expectation.fulfill() }

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_thenMap_error_catching() {

        let expectation = self.expectation(description: "waiting for promise that already fulfilled")

        let promise = Promise<Int>()
        promise.fulfill(1)

        promise
            .thenMap(on: .main) { _ in throw SomeError.foo }
            .catch { _ in expectation.fulfill() }

        waitForExpectations(timeout: 0.1, handler: nil)
    }
}
