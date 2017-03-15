import Foundation
import RxSwift
import RxCocoa
import CoreLocation

extension Reactive where Base: CLLocationManager
{
    
    public var delegate: DelegateProxy
    {
        return RxCLLocationManagerDelegateProxy.proxyForObject(base)
    }
    
    public var didUpdateLocations: Observable<[CLLocation]>
    {
        return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didUpdateLocations:)))
            .map { a in
                return try castOrThrow([CLLocation].self, a[1])
        }
    }
}


class RxCLLocationManagerDelegateProxy : DelegateProxy, CLLocationManagerDelegate, DelegateProxyType
{
    
    class func currentDelegateFor(_ object: AnyObject) -> AnyObject?
    {
        let locationManager: CLLocationManager = object as! CLLocationManager
        return locationManager.delegate
    }
    
    class func setCurrentDelegate(_ delegate: AnyObject?, toObject object: AnyObject)
    {
        let locationManager: CLLocationManager = object as! CLLocationManager
        locationManager.delegate = delegate as? CLLocationManagerDelegate
    }
}


fileprivate func castOrThrow<T>(_ resultType: T.Type, _ object: Any) throws -> T
{
    
    guard let returnValue = object as? T
        else {
            throw RxCocoaError.castingError(object: object, targetType: resultType)
    }
    
    return returnValue
}
