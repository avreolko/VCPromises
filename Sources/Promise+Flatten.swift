import Foundation

public func flatten<T>(_ promises: [Promise<T>], on queue: DispatchQueue = .main) -> Promise<[T]> {

    let work: Promise<[T]>.Work = { fulfill, reject in
        let group = DispatchGroup()

        var values: [T] = []

        promises.forEach {
            group.append($0, fulfill: { values.append($0) }, reject: reject)
        }

        group.notify(queue: queue) {
            guard values.count == promises.count else { return }
            fulfill(values)
        }
    }

    return Promise(work, on: queue)
}

private extension DispatchGroup {
    func append<T>(_ promise: Promise<T>, fulfill: @escaping (T) -> Void, reject: @escaping (Error) -> Void) {
        self.enter()
        promise.then { fulfill($0); self.leave() }
        promise.catch { reject($0); self.leave() }
    }
}
