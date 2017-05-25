import Foundation
import RxSwift

///ViewModel for the MainViewController.
class MainViewModel : RxViewModel
{
    // MARK: Fields
    private let timeService : TimeService
    private let metricsService : MetricsService
    private let timeSlotService : TimeSlotService
    private let editStateService : EditStateService
    private let smartGuessService : SmartGuessService
    private let settingsService : SettingsService
    private let appLifecycleService : AppLifecycleService
    
    init(timeService: TimeService,
         metricsService: MetricsService,
         timeSlotService: TimeSlotService,
         editStateService: EditStateService,
         smartGuessService : SmartGuessService,
         selectedDateService : SelectedDateService,
         settingsService : SettingsService,
         appLifecycleService: AppLifecycleService)
    {
        self.timeService = timeService
        self.metricsService = metricsService
        self.timeSlotService = timeSlotService
        self.editStateService = editStateService
        self.smartGuessService = smartGuessService
        self.settingsService = settingsService
        self.appLifecycleService = appLifecycleService
        
        self.isEditingObservable = self.editStateService.isEditingObservable
        self.dateObservable = selectedDateService.currentlySelectedDateObservable
        self.beganEditingObservable = self.editStateService.beganEditingObservable
        
        self.categoryProvider = DefaultCategoryProvider(timeSlotService: timeSlotService)

    }
    
    // MARK: Properties
    let dateObservable : Observable<Date>
    let isEditingObservable : Observable<Bool>
    let beganEditingObservable : Observable<(CGPoint, TimeSlot)>
    let categoryProvider : CategoryProvider
    
    // MARK: Properties
    var currentDate : Date { return self.timeService.now }
    
    var showPermissionControllerObservable : Observable<PermissionRequestType>
    {
        return Observable.of(
            self.appLifecycleService.movedToForegroundObservable,
            self.didBecomeActive)
            .merge()
            .map { [unowned self] () -> PermissionRequestType? in
                if self.shouldShowLocationPermissionRequest() {
                    return PermissionRequestType.location
                } else if self.shouldShowHealthKitPermissionRequest() {
                    return PermissionRequestType.health
                }
                
                return nil
            }
            .filterNil()
    }
    
    //MARK: Methods
    
    /**
     Adds and persists a new TimeSlot to this Timeline.
     
     - Parameter category: Category of the newly created TimeSlot.
     */
    func addNewSlot(withCategory category: Category)
    {
        guard let timeSlot =
            self.timeSlotService.addTimeSlot(withStartTime: self.timeService.now,
                                             category: category,
                                             categoryWasSetByUser: true,
                                             tryUsingLatestLocation: true)
            else { return }
        
        if let location = timeSlot.location
        {
            self.smartGuessService.add(withCategory: timeSlot.category, location: location)
        }
        
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
    
    private func shouldShowLocationPermissionRequest() -> Bool
    {
        if self.settingsService.hasLocationPermission { return false }
        
        //If user doesn't have permissions and we never showed the overlay, do it
        guard let lastRequestedDate = self.settingsService.lastAskedForLocationPermission else { return true }
        
        let minimumRequestDate = lastRequestedDate.addingTimeInterval(Constants.timeToWaitBeforeShowingLocationPermissionsAgain)
        
        //If we previously showed the overlay, we must only do it again after timeToWaitBeforeShowingLocationPermissionsAgain
        return minimumRequestDate < self.timeService.now
    }
    
    private func shouldShowHealthKitPermissionRequest() -> Bool
    {
        guard let installDate = settingsService.installDate else { return false }
        
        return !settingsService.hasHealthKitPermission && installDate.addingTimeInterval(Constants.timeToWaitBeforeShowingHealthKitPermissions - 5) < self.timeService.now
    }
}
