import Foundation
import UIKit
import RxSwift
import CoreLocation
import CoreMotion

class DefaultLocationService : NSObject, LocationService
{
    //MARK: Fields
    private let loggingService : LoggingService
    private let timeoutScheduler : SchedulerType
    private let locationManager : CLLocationManager
    private let accurateLocationManager : CLLocationManager
    private let locationSubject = PublishSubject<CLLocation>()
    
    private let dateTimeFormatter = DateFormatter()
    
    //MARK: Initializers
    init(loggingService: LoggingService,
         locationManager:CLLocationManager = CLLocationManager(),
         accurateLocationManager:CLLocationManager = CLLocationManager(),
         timeoutScheduler:SchedulerType = MainScheduler.instance)
    {
        self.loggingService = loggingService
        self.locationManager = locationManager
        self.accurateLocationManager = accurateLocationManager
        self.timeoutScheduler = timeoutScheduler
        
        super.init()
        
        self.accurateLocationManager.allowsBackgroundLocationUpdates = true
        
        self.dateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        self.loggingService.log(withLogLevel: .verbose, message: "DefaultLocationService Initialized")
    }
    
    // MARK: Methods
    private(set) lazy var eventObservable : Observable<TrackEvent> =
    {
        return self.locationSubject
                   .asObservable()
                   .filter(self.filterLocations)
                   .map(TrackEvent.toTrackEvent)
    }()
    
    func startLocationTracking()
    {
        self.loggingService.log(withLogLevel: .debug, message: "Accurate Location Service started")
        self.accurateLocationManager.startUpdatingLocation()
        
        _ = self.accurateLocationManager.rx.didUpdateLocations
            .completeAfter(locationsAccurateEnough)
            .take(Constants.maxGPSTime, scheduler: timeoutScheduler)
            .flatMap{ Observable.from($0) }
            .reduce(nil, accumulator: selectBestLocation)
            .filterNil()
            .map{ location in [location] }
            .subscribe(
                onNext: forwardLocations,
                onCompleted: startSignificaLocationChangeTracking
        )
    }
    
    func getLastKnownLocation() -> CLLocation?
    {
        return self.locationManager.location
    }
    
    //MARK: Methods
    private func selectBestLocation(old:CLLocation?, new:CLLocation) -> CLLocation
    {
        guard let old = old, old.horizontalAccuracy < new.horizontalAccuracy else {
            return new
        }
        return old
    }
    
    private func startSignificaLocationChangeTracking() {
        self.accurateLocationManager.stopUpdatingLocation()
        
        self.loggingService.log(withLogLevel: .debug, message: "DefaultLocationService started")
        self.locationManager.startMonitoringSignificantLocationChanges()
        
        _ = self.locationManager.rx.didUpdateLocations
            .subscribe(
                onNext:forwardLocations
        )
    }
    
    private func forwardLocations(_ locations:[CLLocation])
    {
        //Notifies new locations to listeners
        locations.forEach(self.locationSubject.onNext)
    }
    
    private func locationsAccurateEnough(locations:[CLLocation]) -> Bool
    {
        return locations.reduce(false, { isAccurate, location in
            return isAccurate || (location.horizontalAccuracy < Constants.gpsAccuracy)
        })
    }
    
    private func filterLocations(_ location: CLLocation) -> Bool
    {
        //Location is valid
        guard location.coordinate.latitude != 0.0 && location.coordinate.latitude != 0.0 else
        {
            self.logLocationUpdate(location, "Received an invalid location")
            return false
        }
                
        //Location is accurate enough
        guard 0 ... Constants.significantLocationChangeAccuracy ~= location.horizontalAccuracy else
        {
            self.logLocationUpdate(location, "Received an inaccurate location")
            return false
        }
        
        self.logLocationUpdate(location, "Received a valid location")
        return true
    }
    
    private func logLocationUpdate(_ location: CLLocation, _ message: String)
    {
        let text = "\(message) <\(location.coordinate.latitude),\(location.coordinate.longitude)>"
                 + " ~\(max(location.horizontalAccuracy, location.verticalAccuracy))m"
                 + " (speed: \(location.speed)m/s course: \(location.course))"
                 + " at \(dateTimeFormatter.string(from: location.timestamp))"
        
        self.loggingService.log(withLogLevel: .debug, message: text)
    }
}
