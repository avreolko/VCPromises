import Foundation

extension Promise {

    @discardableResult
    public func zip<U>(with other: Promise<U>, on queue: DispatchQueue = .main) -> Promise<(Value, U)> {

        let work: Promise<(Value, U)>.Work = { (fulfill, reject) in

            let combine = {
                guard let first = self.value, let second = other.value else { return }
                fulfill((first, second))
            }

            self.then(on: queue, { _ in combine() }, reject)
            other.then(on: queue, { _ in combine() }, reject)
        }

        return Promise<(Value, U)>(work)
    }

    @discardableResult
    public func zip<T1, T2>(with second: Promise<T1>, and third: Promise<T2>, on queue: DispatchQueue = .main) -> Promise<(Value, T1, T2)> {

        let work: Promise<(Value, T1, T2)>.Work = { (fulfill, reject) in
            self.zip(with: second, on: queue)
                .zip(with: third, on: queue)
                .then(on: queue, { fulfill(($0.0.0, $0.0.1, $0.1)) }, reject)
        }

        return Promise<(Value, T1, T2)>(work)
    }

    @discardableResult
    public func zip<T1, T2, T3>(with second: Promise<T1>,
                                and third: Promise<T2>,
                                and fourth: Promise<T3>,
                                on queue: DispatchQueue = .main) -> Promise<(Value, T1, T2, T3)> {

        let work: Promise<(Value, T1, T2, T3)>.Work = { (fulfill, reject) in
            self.zip(with: second, and: third, on: queue)
                .zip(with: fourth, on: queue)
                .then(on: queue, { fulfill(($0.0.0, $0.0.1, $0.0.2, $0.1)) }, reject)
        }

        return Promise<(Value, T1, T2, T3)>(work)
    }

    @discardableResult
    public func zip<T1, T2, T3, T4>(with second: Promise<T1>,
                                    and third: Promise<T2>,
                                    and fourth: Promise<T3>,
                                    and fifth: Promise<T4>,
                                    on queue: DispatchQueue = .main) -> Promise<(Value, T1, T2, T3, T4)> {

        let work: Promise<(Value, T1, T2, T3, T4)>.Work = { (fulfill, reject) in
            self.zip(with: second, and: third, on: queue)
                .zip(with: fourth, and: fifth, on: queue)
                .then(on: queue, { fulfill(($0.0.0, $0.0.1, $0.0.2, $0.1, $0.2)) }, reject)
        }

        return Promise<(Value, T1, T2, T3, T4)>(work)
    }
}

