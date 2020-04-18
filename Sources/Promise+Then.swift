import Foundation

extension Promise {

    @discardableResult
    public func thenFlatMap<NewValue>(on queue: DispatchQueue = .main, _ onFulfill: @escaping (Value) throws -> Promise<NewValue>) -> Promise<NewValue> {

        let work: Promise<NewValue>.Work = { fulfill, reject in

            let newFulfill: Success<Value> = { value in
                do {
                    try onFulfill(value).then(fulfill, reject)
                } catch let error {
                    reject(error)
                }
            }

            self.addCallbacks(newFulfill, reject, queue)
        }

        return Promise<NewValue>(work)
    }

    @discardableResult
    public func thenMap<NewValue>(on queue: DispatchQueue = .main, _ onFullfill: @escaping (Value) throws -> NewValue) -> Promise<NewValue> {

        return self.thenFlatMap(on: queue, { (value) -> Promise<NewValue> in
            do {
                return Promise<NewValue>(value: try onFullfill(value))
            } catch let error {
                return Promise<NewValue>(error: error)
            }
        })
    }

    @discardableResult
    public func then(on queue: DispatchQueue = .main,
                     _ fullfill: @escaping (Value) -> Void,
                     _ reject: @escaping (Error) -> Void = { _ in }) -> Promise<Value> {
        self.addCallbacks(fullfill, reject, queue)
        return self
    }

    @discardableResult
    public func then(on queue: DispatchQueue = .main, _ fullfill: @escaping (Value) -> Void) -> Promise<Value> {
        self.addCallbacks(fullfill, { _ in }, queue)
        return self
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
