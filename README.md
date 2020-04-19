# VCPromises
A basic implementation of the Promise pattern in Swift

## Installation
Install with SPM 📦

## Features
- `then`, `catch`, `finally`, `thenMap`, `thenFlatMap`, `zip`
- `flatten()` global function for promises of the same type
- Queuing

``` swift
// you can define your work on some queue
// and then handle result on main
let work: Promise<Int>.Work = { fulfill, _ in
    do {
        let result = try someWork()
        fulfill(result)
    } catch {
        reject($0)
    }
}

Promise(work, on: .global(qos: .userInitiated))
.then(on: .main) { _ in }
```

- Internal error handling

``` swift
let promise = Promise<Int>()
promise.fulfill(1)

promise
    // all actions that you submit to then and map can throw
    .thenMap { _ in throw SomeError.foo }
    .catch { /* handle SomeError.foo */ }
```

- Smart error catch

``` swift
enum Complex: Error, Equatable {

    enum Reason {
        case parsingFailed
        case serviceError
    }

    case httpError(Int)
    case otherError(Reason)
}

let promise = Promise<Void>(error: ComplexError.httpError(500))

promise
    .catch(ComplexError.httpError(500)) { /* executes on .http(500) */ }
    .catch(ComplexError.other(.serviceError)) { /* executes on .other(.serviceError) */ }
    .catch(ComplexError.self) { /* executes on all Complex errors */ }
    .catch{ error in /* executes on all errors */ }
```

## Usage
See `/Tests` for usage examples
