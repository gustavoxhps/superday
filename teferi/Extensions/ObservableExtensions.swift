import Foundation
import RxSwift

/**
This code is originally from the RxOptional library, but it's better having it here rather than importing the entire lib and not using most of it
https://github.com/RxSwiftCommunity/RxOptional/blob/68e893aaa849c585ab2dbae3116cb41104091397/Source/Observable%2BOptional.swift#L14-L21
 **/

extension ObservableType where E: OptionalType
{
    public func filterNil() -> Observable<E.Wrapped>
    {
        return self.flatMap { element -> Observable<E.Wrapped> in
            
            guard let value = element.value else { return Observable<E.Wrapped>.empty() }
            return Observable<E.Wrapped>.just(value)
        }
    }
}

public protocol OptionalType
{
    associatedtype Wrapped
    var value: Wrapped? { get }
}

extension Optional: OptionalType
{
    /// Cast `Optional<Wrapped>` to `Wrapped?`
    public var value: Wrapped? { return self }
}

extension ObservableType
{
    public func completeAfter(_ predicate: @escaping (Self.E) throws -> Bool) -> Observable<Self.E>
    {
        return Observable<Self.E>.create { observer in
            return self.subscribe { event in
                switch event {
                case .next(let element):
                    do {
                        observer.onNext(element)
                        if try predicate(element) {
                            observer.onCompleted()
                        }
                    } catch let err {
                        observer.onError(err)
                    }
                case .error(let err):
                    observer.onError(err)
                case .completed:
                    observer.onCompleted()
                }
            }
        }
    }
    
    public func mapTo<R>(_ value: R) -> Observable<R>
    {
        return map {_ in value}
    }
}
