import Foundation
import UIKit
import RxSwift
import CoreLocation
import CoreMotion

class DefaultLocationService : NSObject, LocationService
{
    var eventObservable : Observable<TrackEvent> { return
        self.locationVariable
            .asObservable()
            .filterNil()
            .do(
                onNext: { [unowned self] location in
                    self.logLocationUpdate(location, "Received a valid location")
                }
            )
            .map(Location.init(fromCLLocation:))
            .map(Location.asTrackEvent)
    }
    
    private let loggingService : LoggingService
    private let timeoutScheduler : SchedulerType
    private let locationManager : CLLocationManager
    private var accurateLocationManager : CLLocationManager
    
    private let locationVariable = Variable<CLLocation?>(nil)
    
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
        
        accurateLocationManager.allowsBackgroundLocationUpdates = true
        
        dateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        loggingService.log(withLogLevel: .info, message: "DefaultLocationService Initialized")
        
        _ = locationManager.rx.didUpdateLocations
            .do(onNext: { [unowned self] locations in
                self.logLocationUpdate(locations.first!, "received SLC locations: \(locations.count)")
                self.startGPSTracking()
            })
            .flatMapLatest(improveWithGPS)
            .flatMap{ Observable.from($0) } // Transform the Observable<[CLLocation]> into Observable<CLLocation>
            .filter(filterLocations)
            .bindTo(locationVariable)
    }
    
    
    // MARK: Public Methods    
    func startLocationTracking()
    {
        loggingService.log(withLogLevel: .info, message: "Location Service started")
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func getLastKnownLocation() -> CLLocation?
    {
        return [locationManager.location, accurateLocationManager.location]
            .flatMap({$0})
            .max { lc1, lc2 in
                return lc1.horizontalAccuracy > lc2.horizontalAccuracy
        }
    }
    
    // MARK: Private Methods
    private func startGPSTracking()
    {
        loggingService.log(withLogLevel: .info, message: "Accurate Location Service started")
        accurateLocationManager.startUpdatingLocation()
    }
    
    private func stopGPSTracking()
    {
        loggingService.log(withLogLevel: .info, message: "Accurate Location Service stopped")
        accurateLocationManager.stopUpdatingLocation()
    }
    
    private func improveWithGPS(locations:[CLLocation]) -> Observable<[CLLocation]>
    {
        return getBestGPSLocation()
            .map { gpsLocation in
                
                guard let gpsLocation = gpsLocation else { return locations }
                guard let lastLocation = locations.last else { return [gpsLocation] }
                
                if lastLocation.isMoreAccurate(than: gpsLocation)
                {
                    return locations
                }
                
                return locations.dropLast() + [gpsLocation]
        }
    }
    
    private func getBestGPSLocation() -> Observable<CLLocation?>
    {
        return accurateLocationManager.rx.didUpdateLocations
            .completeAfter(locationsAccurateEnough)
            .take(Constants.maxGPSTime, scheduler: timeoutScheduler)
            .catchErrorJustReturn([])
            .do(
                onNext: { [unowned self] locations in
                    self.logLocationUpdate(locations.first!, "received GPS locations: \(locations.count)")
                },
                onCompleted: stopGPSTracking
            )
            .flatMap{ Observable.from($0) } // Transform the Observable<[CLLocation]> into Observable<CLLocation>
            .reduce(nil, accumulator: selectBest)
    }
    
    private func selectBest(previousLocation:CLLocation?, location: CLLocation) -> CLLocation?
    {
        guard let previousLocation = previousLocation else { return location }
        
        if previousLocation.horizontalAccuracy < location.horizontalAccuracy {
            return previousLocation
        }
        
        return location
    }
    
    private func locationsAccurateEnough(locations: [CLLocation]) -> Bool
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
            logLocationUpdate(location, "Filtered an invalid location")
            return false
        }
                
        //Location is accurate enough
        guard 0 ... Constants.significantLocationChangeAccuracy ~= location.horizontalAccuracy else
        {
            logLocationUpdate(location, "Filtered an inaccurate location")
            return false
        }
        
        return true
    }
    
    private func logLocationUpdate(_ location: CLLocation, _ message: String)
    {
        let text = "\(message) <\(location.coordinate.latitude),\(location.coordinate.longitude)>"
                 + " ~\(max(location.horizontalAccuracy, location.verticalAccuracy))m"
                 + " (speed: \(location.speed)m/s course: \(location.course))"
                 + " at \(dateTimeFormatter.string(from: location.timestamp))"
        
        loggingService.log(withLogLevel: .debug, message: text)
    }
}
