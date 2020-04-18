//
//  Promise+Zip.swift
//  
//
//  Created by Черепянко Валентин Александрович on 18/04/2020.
//

import Foundation

extension Promise {

    @discardableResult
    public func zip<Other>(with other: Promise<Other>, on queue: DispatchQueue? = nil) -> Promise<(Value, Other)> {

        let queue = queue ?? self.queue

        let work: Promise<(Value, Other)>.Work = { (fulfill, reject) in

            let group = DispatchGroup()

            var firstValue: Value?
            var secondValue: Other?

            group.append(self, fulfill: { firstValue = $0 }, reject: reject)
            group.append(other, fulfill: { secondValue = $0 }, reject: reject)

            group.notify(queue: queue) {
                guard let first = firstValue, let second = secondValue else { return }
                fulfill((first, second))
            }
        }

        return Promise<(Value, Other)>(work, on: queue)
    }

    @discardableResult
    public func zip<Second, Third>(with second: Promise<Second>, and third: Promise<Third>, on queue: DispatchQueue? = nil) -> Promise<(Value, Second, Third)> {

        let queue = queue ?? self.queue

        let work: Promise<(Value, Second, Third)>.Work = { (fulfill, reject) in
            let group = DispatchGroup()

            var firstValue: Value?
            var secondValue: Second?
            var thirdValue: Third?

            group.append(self, fulfill: { firstValue = $0 }, reject: reject)
            group.append(second, fulfill: { secondValue = $0 }, reject: reject)
            group.append(third, fulfill: { thirdValue = $0 }, reject: reject)

            group.notify(queue: queue) {
                guard let first = firstValue, let second = secondValue, let third = thirdValue else { return assertionFailure() }
                fulfill((first, second, third))
            }
        }

        return Promise<(Value, Second, Third)>(work, on: queue)
    }
}

private extension DispatchGroup {
    func append<T>(_ promise: Promise<T>, fulfill: @escaping (T) -> Void, reject: @escaping (Error) -> Void) {
        self.enter()
        promise.then { fulfill($0); self.leave() }
        promise.catch { reject($0); self.leave() }
    }
}
