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

- Error catching

``` swift
let promise = Promise<Int>()
promise.fulfill(1)

promise
    .thenMap { _ in throw SomeError.foo }
    .catch { _ in /* handle SomeError.foo */ }
```


## Usage
See `/Tests` for usage examples
