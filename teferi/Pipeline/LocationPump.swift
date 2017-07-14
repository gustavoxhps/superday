import Foundation
import RxSwift
import CoreLocation

class LocationPump : Pump
{
    private let trackEventService:TrackEventService
    private let settingsService:SettingsService
    private let timeSlotService:TimeSlotService
    private let loggingService : LoggingService
    private let timeService : TimeService
    
    private var lastSavedTimeSlot:TimeSlot!
    
    // MARK: Initializers
    init(trackEventService:TrackEventService,
         settingsService:SettingsService,
         timeSlotService:TimeSlotService,
         loggingService: LoggingService,
         timeService: TimeService
        )
    {
        self.trackEventService = trackEventService
        self.settingsService = settingsService
        self.timeSlotService = timeSlotService
        self.loggingService = loggingService
        self.timeService = timeService
    }
    
    // MARK: Pump implementation
    func run() -> [TemporaryTimeSlot]
    {
        guard let lastTimeSlot = timeSlotService.getLast() else { return [] }
        lastSavedTimeSlot = lastTimeSlot

        var locations = trackEventService.getEventData(ofType: Location.self)
        
        guard locations.count > 0 else { return [] }
        
        var lastLocation:Location
        if let storedLastLocation = settingsService.lastLocation {
            lastLocation = Location(fromCLLocation:storedLastLocation)
        } else {
            lastLocation = locations.remove(at: 0)
        }
                
        var temporaryTimeSlotsToReturn = locations
            .reduce([]) { (timeSlots, location) -> [TemporaryTimeSlot] in
                defer {
                    lastLocation = replaceIfNeeded(lastLocation, with:location)
                }
                
                guard isValid(location, previousLocation: lastLocation) else { return timeSlots }
                
                return toTemporaryTimeSlots(
                    location: location,
                    previousLocation:lastLocation,
                    timeSlots:timeSlots
                )
        }

        temporaryTimeSlotsToReturn = endLastTimeSlotIfNeeded(temporaryTimeSlots: temporaryTimeSlotsToReturn, lastLocation: lastLocation)
        
        loggingService.log(withLogLevel: .info, message: "Location pump temporary timeline:")
        temporaryTimeSlotsToReturn.forEach { (slot) in
            self.loggingService.log(withLogLevel: .debug, message: "LocationSlot start: \(slot.start) category: \(slot.category.rawValue)")
        }
        
        return temporaryTimeSlotsToReturn.withEndSetToStartOfNext()
    }
    
    // MARK: Private Methods
    private func replaceIfNeeded(_ lastLocation:Location, with location:Location) -> Location
    {
        guard location.timestamp > lastLocation.timestamp else { return lastLocation }
        
        if location.isSignificantlyDifferent(fromLocation: lastLocation) {
            return location
        } else {
            if location.isMoreAccurate(than: lastLocation) {
                return location
            }
        }
        
        return lastLocation
    }
    
    private func isValid(_ location:Location, previousLocation:Location) -> Bool
    {
        let clLocation = location.toCLLocation()
        let previousCLLocation = previousLocation.toCLLocation()
        
        guard location.timestamp > previousLocation.timestamp else { return false }
        
        guard clLocation.isSignificantlyDifferent(fromLocation: previousCLLocation) else
        {
            return false
        }

        return true
    }
    
    private func endLastTimeSlotIfNeeded(temporaryTimeSlots:[TemporaryTimeSlot], lastLocation:Location) -> [TemporaryTimeSlot]
    {
        let now = timeService.now
        if let lastTTS = temporaryTimeSlots.last, lastTTS.category == .commute, now.timeIntervalSince(lastLocation.timestamp) > Constants.commuteDetectionLimit {
            return temporaryTimeSlots + [TemporaryTimeSlot(location: lastLocation, category: .unknown)]
        }
        
        return temporaryTimeSlots
    }
    
    private func toTemporaryTimeSlots(location:Location, previousLocation:Location, timeSlots:[TemporaryTimeSlot]) -> [TemporaryTimeSlot]
    {
        let lastCategory = timeSlots.last?.category ?? lastSavedTimeSlot.category
        let lastStartTime = timeSlots.last?.start ?? lastSavedTimeSlot.startTime
        
        if location.isCommute(fromLocation: previousLocation)
        {
            if lastStartTime == previousLocation.timestamp
            {
                if let lastTemporaryTimeSlot = timeSlots.last {
                    return timeSlots.dropLast() + [ lastTemporaryTimeSlot.with(category: .commute) ]
                }
            }
            else if lastCategory != .commute
            {
                return timeSlots + [ TemporaryTimeSlot(location: previousLocation, category: .commute) ]
            }
        }
        else
        {
            var timeSlotForLastLocation:TemporaryTimeSlot?
            if lastStartTime < previousLocation.timestamp
            {
                timeSlotForLastLocation = TemporaryTimeSlot(location: previousLocation, category: .unknown)
            }
            
            return timeSlots + [ timeSlotForLastLocation, TemporaryTimeSlot(location: location, category: .unknown) ].flatMap({$0})
        }

        return timeSlots
    }
}
