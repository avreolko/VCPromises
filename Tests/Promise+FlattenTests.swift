import XCTest
@testable import VCPromises

final class PromiseFlattenTests: XCTestCase {
    func test_performance_on_a_concurrent_queue() {

        let worksCount = 10

        let workQueue = DispatchQueue(label: "work.queue", attributes: .concurrent)
        let expectation = self.expectation(description: "waiting for promise")
        expectation.expectedFulfillmentCount = worksCount + 1

        let range = (0..<10000)
        let unsortedArray = range.map { _ in Int.random(in: range) }

        let makePromise: (Int) -> Promise<[Int]> = { number in
            let work: Promise<[Int]>.Work = { fulfill, _ in
                evaluate(number) { fulfill(unsortedArray.sorted()) }
                expectation.fulfill()
                XCTAssertEqual(currentQueueLabel, "work.queue")
            }
            return Promise(work, on: workQueue)
        }

        var promises: [Promise<[Int]>] = []

        promises = (1..<worksCount+1).map { makePromise($0) }

        evaluate(0) {
            flatten(promises, on: .main).then { values in
                values.forEach { XCTAssertEqual($0, values.first!) }
                expectation.fulfill()
                XCTAssertEqual(currentQueueLabel, "com.apple.main-thread")
            }
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
}

private func evaluate(_ problemNumber: Int, _ problemBlock: () -> Void)
{
    let start = DispatchTime.now()
    problemBlock()
    let end = DispatchTime.now()

    let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
    let timeInterval = Double(nanoTime) / 1_000_000_000

    print("Time to evaluate problem \(problemNumber): \(timeInterval) seconds")
}
