import Foundation

extension Promise {

    @discardableResult
    public func `catch`(on queue: DispatchQueue = .main, _ reject: @escaping (Error) -> Void) -> Promise<Value> {
        return self.then(on: queue, { _ in }, reject)
    }

    @discardableResult
    public func `catch`<ErrorType>(_ as: ErrorType.Type,
                                   on queue: DispatchQueue = .main,
                                   _ reject:  @escaping (ErrorType) -> Void) -> Promise<Value> {
        return self.catch { ($0 as? ErrorType).map { reject($0) } }
    }

    @discardableResult
    public func `catch`<ErrorType: Equatable>(_ error: ErrorType,
                                              on queue: DispatchQueue = .main,
                                              _ reject:  @escaping () -> Void) -> Promise<Value> {
        return self.catch { if error == ($0 as? ErrorType) { reject() } }
    }
}

