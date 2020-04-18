import Foundation

public typealias Success<T> = (T) -> Void
public typealias Failure = (Error) -> Void

struct Callback<Value> {
    private let fulfill: Success<Value>
    private let reject: Failure
    private let queue: DispatchQueue

    init(fulfill: @escaping Success<Value>,
         reject: @escaping Failure,
         queue: DispatchQueue) {

        self.fulfill = fulfill
        self.reject = reject
        self.queue = queue
    }

    func fulfill(with value: Value) {
        self.queue.async { self.fulfill(value) }
    }

    func reject(with error: Error) {
        self.queue.async { self.reject(error) }
    }
}

public class Promise<Value> {

    public typealias Work = (_ fulfill: @escaping Success<Value>, _ reject: @escaping Failure) throws -> Void

    enum State<Value> {
        case pending([Callback<Value>])
        case fulfilled(Value)
        case rejected(Error)
    }

    private var state: State<Value>

    public init() {
        self.state = .pending([])
    }

    public init(value: Value) {
        self.state = .fulfilled(value)
    }

    public init(error: Error) {
        self.state = .rejected(error)
    }

    public convenience init(_ work: @escaping Work, on queue: DispatchQueue = .global(qos: .userInitiated)) {

        self.init()

        queue.async {
            do {
                try work(self.fulfill, self.reject)
            } catch let error {
                self.reject(error)
            }
        }
    }

    public func reject(_ error: Error) {
        self.updateState(.rejected(error))
    }

    public func fulfill(_ value: Value) {
        self.updateState(.fulfilled(value))
    }

    internal func addCallbacks(_ fulfill: @escaping Success<Value>,
                               _ reject: @escaping Failure,
                               _ queue: DispatchQueue) {

        let callback = Callback(fulfill: fulfill, reject: reject, queue: queue)

        switch self.state {
        case .pending(let callbacks):
            self.state = .pending(callbacks + [callback])
        case .fulfilled(let value):
            callback.fulfill(with: value)
        case .rejected(let error):
            callback.reject(with: error)
        }
    }
}

private extension Promise {

    func updateState(_ newState: State<Value>) {

        guard case .pending(let callbacks) = self.state else { return }

        self.state = newState

        switch newState {
        case .pending: break
        case .fulfilled(let value): callbacks.forEach { $0.fulfill(with: value) }
        case .rejected(let error): callbacks.forEach { $0.reject(with: error) }
        }
    }
}
