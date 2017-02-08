import Foundation
import RxSwift

///ViewModel for the MainViewController.
class MainViewModel
{
    // MARK: Fields
    private let timeService : TimeService
    private let metricsService : MetricsService
    private let timeSlotService : TimeSlotService
    private let locationService : LocationService
    private let editStateService : EditStateService
    private let smartGuessService : SmartGuessService
    
    init(timeService: TimeService,
         metricsService: MetricsService,
         timeSlotService: TimeSlotService,
         locationService : LocationService,
         editStateService: EditStateService,
         smartGuessService : SmartGuessService,
         selectedDateService : SelectedDateService)
    {
        self.timeService = timeService
        self.metricsService = metricsService
        self.timeSlotService = timeSlotService
        self.locationService = locationService
        self.editStateService = editStateService
        self.smartGuessService = smartGuessService
        
        self.isEditingObservable = self.editStateService.isEditingObservable
        self.dateObservable = selectedDateService.currentlySelectedDateObservable
        self.beganEditingObservable = self.editStateService.beganEditingObservable
        
        let shouldCreateLeisureTimeSlot = self.timeSlotService.getLast() == nil
        if shouldCreateLeisureTimeSlot
        {
            self.addNewSlot(withCategory: .leisure)
        }
    }
    
    // MARK: Properties
    let dateObservable : Observable<Date>
    let isEditingObservable : Observable<Bool>
    let beganEditingObservable : Observable<(CGPoint, TimeSlot)>
    
    // MARK: Properties
    var currentDate : Date { return self.timeService.now }
    
    //MARK: Methods
    
    /**
     Adds and persists a new TimeSlot to this Timeline.
     
     - Parameter category: Category of the newly created TimeSlot.
     */
    func addNewSlot(withCategory category: Category)
    {
        let currentLocation = self.locationService.getLastKnownLocation()
        
        let newSlot = TimeSlot(withStartTime: self.timeService.now,
                               category: category,
                               location: currentLocation,
                               categoryWasSetByUser: true)
        
        if let location = currentLocation
        {
            self.smartGuessService.add(withCategory: category, location: location)
        }
        
        self.timeSlotService.add(timeSlot: newSlot)
        self.metricsService.log(event: .timeSlotManualCreation)
    }
    
    /**
     Updates a TimeSlot's category.
     
     - Parameter timeSlot: TimeSlot to be updated.
     - Parameter category: Category of the newly created TimeSlot.
     */
    func updateTimeSlot(_ timeSlot: TimeSlot, withCategory category: Category)
    {
        let categoryWasOriginallySetByUser = timeSlot.categoryWasSetByUser

        self.timeSlotService.update(timeSlot: timeSlot, withCategory: category, setByUser: true)
        self.metricsService.log(event: .timeSlotEditing)
        
        let smartGuessId = timeSlot.smartGuessId
        if !categoryWasOriginallySetByUser && smartGuessId != nil
        {
            //Strike the smart guess if it was wrong
            self.smartGuessService.strike(withId: smartGuessId!)
        }
        else if smartGuessId == nil, let location = timeSlot.location
        {
            self.smartGuessService.add(withCategory: category, location: location)
        }
        
        timeSlot.category = category
        timeSlot.categoryWasSetByUser = true
        
        self.editStateService.notifyEditingEnded()
    }
    
    func notifyEditingEnded() { self.editStateService.notifyEditingEnded() }
}
