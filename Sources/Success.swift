//
//  File.swift
//  
//
//  Created by Черепянко Валентин Александрович on 27/03/2020.
//

import Foundation

public struct Success {
    public init() { }
}

public extension Promise where Value == Success {

    func fulfill() {
        self.fulfill(Success())
    }

    @discardableResult
    func then(_ fulfill: @escaping () -> Void) -> Self {
        self.addCallbacks({ _ in fulfill() }, { _ in })
        return self
    }

    @discardableResult
    func thenFlatMap<NewValue>(_ onFulfill: @escaping () throws -> Promise<NewValue>) -> Promise<NewValue> {
        return Promise<NewValue>(work: { fulfill, reject in
            self.addCallbacks({ value in
                do {
                    try onFulfill().then(fulfill, reject)
                } catch let error {
                    reject(error)
                }
            }, reject)
        })
    }

    @discardableResult
    func thenMap<NewValue>(_ onFullfill: @escaping () throws -> NewValue) -> Promise<NewValue> {
        return self.thenFlatMap { (value) -> Promise<NewValue> in
            do {
                return Promise<NewValue>(value: try onFullfill())
            } catch let error {
                return Promise<NewValue>(error: error)
            }
        }
    }
}
