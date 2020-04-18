import Foundation

public typealias Success<T> = (T) -> Void
public typealias Failure = (Error) -> Void

struct Callback<Value> {
    let fulfill: Success<Value>
    let reject: Failure
}

public class Promise<Value> {

    public typealias Work = (_ fulfill: @escaping Success<Value>, _ reject: @escaping Failure) throws -> Void

    enum State<Value> {
        case pending([Callback<Value>])
        case fulfilled(Value)
        case rejected(Error)
    }

    private var state: State<Value>

    let queue: DispatchQueue

    public init(queue: DispatchQueue = .main) {
        self.state = .pending([])
        self.queue = queue
    }

    public init(value: Value, queue: DispatchQueue = .main) {
        self.state = .fulfilled(value)
        self.queue = queue
    }

    public init(error: Error, queue: DispatchQueue = .main) {
        self.state = .rejected(error)
        self.queue = queue
    }

    public convenience init(_ work: @escaping Work, on queue: DispatchQueue = .main) {

        self.init(queue: queue)

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
                               _ reject: @escaping Failure) {

        let callback = Callback(fulfill: fulfill, reject: reject)

        switch self.state {
        case .pending(let callbacks):
            self.state = .pending(callbacks + [callback])
        case .fulfilled(let value):
            self.enqueue { callback.fulfill(value) }
        case .rejected(let error):
            self.enqueue { callback.reject(error) }
        }
    }
}

private extension Promise {

    func updateState(_ newState: State<Value>) {
        guard case .pending(let callbacks) = self.state else { return }
        self.state = newState
        self.fireIfCompleted(callbacks: callbacks)
    }

    func fireIfCompleted(callbacks: [Callback<Value>]) {
        switch self.state {
        case .pending: break
        case .fulfilled(let value): self.enqueue { callbacks.forEach { $0.fulfill(value) } }
        case .rejected(let error): self.enqueue { callbacks.forEach { $0.reject(error) } }
        }
    }

    func enqueue(_ block: @escaping () -> Void) {
        self.queue.async { block() }
    }
}
