import Foundation

extension Promise {

    @discardableResult
    public func thenFlatMap<NewValue>(on queue: DispatchQueue? = nil, _ onFulfill: @escaping (Value) throws -> Promise<NewValue>) -> Promise<NewValue> {

        let queue = queue ?? self.queue

        let work: Promise<NewValue>.Work = { fulfill, reject in

            let newFulfill: Success<Value> = { value in
                do {
                    try onFulfill(value).then(fulfill, reject)
                } catch let error {
                    reject(error)
                }
            }

            self.addCallbacks(newFulfill, reject)
        }

        return Promise<NewValue>(work, on: queue)
    }

    @discardableResult
    public func thenMap<NewValue>(on queue: DispatchQueue? = nil, _ onFullfill: @escaping (Value) throws -> NewValue) -> Promise<NewValue> {

        let queue = queue ?? self.queue

        return self.thenFlatMap(on: queue, { (value) -> Promise<NewValue> in
            do {
                return Promise<NewValue>(value: try onFullfill(value), queue: queue)
            } catch let error {
                return Promise<NewValue>(error: error, queue: queue)
            }
        })
    }

    @discardableResult
    public func then(_ fullfill: @escaping (Value) -> Void,
                     _ reject: @escaping (Error) -> Void = { _ in }) -> Promise<Value> {
        self.addCallbacks(fullfill, reject)
        return self
    }

    @discardableResult
    public func then(_ fullfill: @escaping (Value) -> Void) -> Promise<Value> {
        self.addCallbacks(fullfill, { _ in })
        return self
    }

    @discardableResult
    public func `catch`(_ reject: @escaping (Error) -> Void) -> Promise<Value> {
        return self.then({ _ in }, reject)
    }

    @discardableResult
    public func finally(_ block: @escaping () -> Void ) -> Promise<Value> {
        return self.then({ _ in block() }, { _ in block() })
    }
}
