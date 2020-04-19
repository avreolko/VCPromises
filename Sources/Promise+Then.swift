import Foundation

extension Promise {

    @discardableResult
    public func thenFlatMap<NewValue>(on queue: DispatchQueue = .main,
                                      _ map: @escaping (Value) throws -> Promise<NewValue>) -> Promise<NewValue> {

        let work: Promise<NewValue>.Work = { fulfill, reject in

            let newFulfill: Success<Value> = { value in
                do {
                    try map(value).then(on: queue, fulfill, reject)
                } catch let error {
                    reject(error)
                }
            }

            self.addCallbacks(newFulfill, reject, queue)
        }

        return Promise<NewValue>(work)
    }

    @discardableResult
    public func thenMap<NewValue>(on queue: DispatchQueue = .main,
                                  _ map: @escaping (Value) throws -> NewValue) -> Promise<NewValue> {

        return self.thenFlatMap(on: queue, { (value) -> Promise<NewValue> in
            do {
                return Promise<NewValue>(value: try map(value))
            } catch let error {
                return Promise<NewValue>(error: error)
            }
        })
    }

    @discardableResult
    public func then(on queue: DispatchQueue = .main,
                     _ fulfill: @escaping (Value) -> Void,
                     _ reject: @escaping (Error) -> Void = { _ in }) -> Promise<Value> {
        self.addCallbacks(fulfill, reject, queue)
        return self
    }

    @discardableResult
    public func then(on queue: DispatchQueue = .main, _ fulfill: @escaping (Value) -> Void) -> Promise<Value> {
        return self.then(on: queue, fulfill, { _ in })
    }

    @discardableResult
    public func `catch`(on queue: DispatchQueue = .main, _ reject: @escaping (Error) -> Void) -> Promise<Value> {
        return self.then(on: queue, { _ in }, reject)
    }

    @discardableResult
    public func finally(on queue: DispatchQueue = .main, _ block: @escaping () -> Void) -> Promise<Value> {
        return self.then(on: queue, { _ in block() }, { _ in block() })
    }
}
