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

    func test_chaining() {

        let expectation = self.expectation(description: "waiting for promise that not yet fulfilled")

        func doSomething() -> Promise<Int> { return Promise(value: 1) }
        func doAnotherThing(_ int: Int) -> Promise<String> { return Promise(value: String(int)) }
        func lastThing(_ string: String) { expectation.fulfill(); XCTAssertEqual(string, "1") }

        doSomething().then(doAnotherThing).then(lastThing)

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func test_complex_chaining() {

        let expectation = self.expectation(description: "waiting for promise that not yet fulfilled")

        func number(_ counter: Int) -> Promise<Int> { .init(value: counter) }
        func increment(_ value: Int) -> Promise<Int> { .init(value: value + 1) }
        func sum(_ values: (Int, Int, Int)) -> Promise<Int> { .init(value: values.0 + values.1 + values.2) }
        func confirm(_ value: Int) { expectation.fulfill(); XCTAssertEqual(value, 8) }

        number(1)
            .then(increment)
            .zip(with: number(3), and: number(3))
            .then(sum)
            .then(confirm)

        waitForExpectations(timeout: 0.1, handler: nil)
    }
}
