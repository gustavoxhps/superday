import UIKit
import RxSwift
import Foundation
import CoreLocation
import UserNotifications

@UIApplicationMain
class AppDelegate : UIResponder, UIApplicationDelegate
{   
    //MARK: Fields
    fileprivate var didReceiveCategoryNotification = false
    private let disposeBag = DisposeBag()
    private let notificationAuthorizedSubject = PublishSubject<Void>()
    
    private let pipeline : Pipeline
    private let timeService : TimeService
    private let metricsService : MetricsService
    private let loggingService : LoggingService
    private let feedbackService : FeedbackService
    private let locationService : LocationService
    private let settingsService : SettingsService
    private let timeSlotService : TimeSlotService
    private let editStateService : EditStateService
    private let healthKitService : HealthKitService
    private let smartGuessService : SmartGuessService
    private let trackEventService : TrackEventService
    private let appLifecycleService : AppLifecycleService
    private let notificationService : NotificationService
    private let selectedDateService : DefaultSelectedDateService
    private let notificationSchedulingService : NotificationSchedulingService
    
    private let coreDataStack : CoreDataStack
    
    //MARK: Properties
    var window: UIWindow?
    
    //Initializers
    override init()
    {
        timeService = DefaultTimeService()
        metricsService = FabricMetricsService()
        settingsService = DefaultSettingsService(timeService: timeService)
        loggingService = SwiftyBeaverLoggingService()
        appLifecycleService = DefaultAppLifecycleService()
        editStateService = DefaultEditStateService(timeService: timeService)
        locationService = DefaultLocationService(loggingService: loggingService)
        healthKitService = DefaultHealthKitService(settingsService: settingsService, loggingService: loggingService)
        selectedDateService = DefaultSelectedDateService(timeService: timeService)
        feedbackService = MailFeedbackService(recipients: ["support@toggl.com"], subject: "Supertoday feedback", body: "")
        
        coreDataStack = CoreDataStack(loggingService: loggingService)
        let timeSlotPersistencyService = CoreDataPersistencyService(loggingService: loggingService, modelAdapter: TimeSlotModelAdapter(), managedObjectContext: coreDataStack.managedObjectContext)
        let locationPersistencyService = CoreDataPersistencyService(loggingService: loggingService, modelAdapter: LocationModelAdapter(), managedObjectContext: coreDataStack.managedObjectContext)
        let smartGuessPersistencyService = CoreDataPersistencyService(loggingService: loggingService, modelAdapter: SmartGuessModelAdapter(), managedObjectContext: coreDataStack.managedObjectContext)
        let healthSamplePersistencyService = CoreDataPersistencyService(loggingService: loggingService, modelAdapter: HealthSampleModelAdapter(), managedObjectContext: coreDataStack.managedObjectContext)
        
        smartGuessService = DefaultSmartGuessService(timeService: timeService,
                                                          loggingService: loggingService,
                                                          settingsService: settingsService,
                                                          persistencyService: smartGuessPersistencyService)
        
        timeSlotService = DefaultTimeSlotService(timeService: timeService,
                                                      loggingService: loggingService,
                                                      locationService: locationService,
                                                      persistencyService: timeSlotPersistencyService)
        
        if #available(iOS 10.0, *)
        {
            notificationService = PostiOSTenNotificationService(timeService: timeService,
                                                                     loggingService: loggingService,
                                                                     settingsService: settingsService,
                                                                     timeSlotService: timeSlotService)
        }
        else
        {
            notificationService = PreiOSTenNotificationService(loggingService: loggingService,
                                                                    notificationAuthorizedSubject.asObservable())
        }
        
        let trackEventServicePersistency = TrackEventPersistencyService(loggingService: loggingService,
                                                                        locationPersistencyService: locationPersistencyService,
                                                                        healthSamplePersistencyService: healthSamplePersistencyService)
        
        trackEventService = DefaultTrackEventService(loggingService: loggingService,
                                                          persistencyService: trackEventServicePersistency,
                                                          withEventSources: locationService, healthKitService)
        
        let locationPump = LocationPump(trackEventService: trackEventService,
                                        settingsService: settingsService,
                                        smartGuessService: smartGuessService,
                                        timeSlotService: timeSlotService,
                                        loggingService: loggingService,
                                        timeService: timeService)
        
        let healthKitPump = HealthKitPump(trackEventService: trackEventService, loggingService: loggingService)
        
        pipeline = Pipeline.with(loggingService: loggingService, pumps: locationPump, healthKitPump)
                                .pipe(to: MergePipe())
                                .pipe(to: MergeMiniCommuteTimeSlotsPipe(timeService: timeService))
                                .pipe(to: FirstTimeSlotOfDayPipe(timeService: timeService, timeSlotService: timeSlotService))
                                .sink(PersistencySink(settingsService: settingsService,
                                                      timeSlotService: timeSlotService,
                                                      smartGuessService: smartGuessService,
                                                      trackEventService: trackEventService,
                                                      timeService: timeService))

        notificationSchedulingService = NotificationSchedulingService(timeService: timeService,
                                                                           settingsService: settingsService,
                                                                           locationService: locationService,
                                                                           smartGuessService: smartGuessService,
                                                                           notificationService: notificationService)
    }
    
    //MARK: UIApplicationDelegate lifecycle
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        setVersionInSettings()
        setAppearance()
        
        let isInBackground = launchOptions?[UIApplicationLaunchOptionsKey.location] != nil
        
        logAppStartup(isInBackground)

        if settingsService.hasHealthKitPermission
        {
            healthKitService.startHealthKitTracking()
        }
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        } else {
            if let notification = launchOptions?[UIApplicationLaunchOptionsKey.localNotification] as? UILocalNotification {
                didReceiveCategoryNotification = isCategorySelectionNotification(notification)
            }
        }
        
        
        appLifecycleService.publish(isInBackground ? .movedToBackground : .movedToForeground(fromNotification:didReceiveCategoryNotification))

        
        //Faster startup when the app wakes up for location updates
        if isInBackground
        {
            locationService.startLocationTracking()
            return true
        }
        
        initializeWindowIfNeeded()
        smartGuessService.purgeEntries(olderThan: timeService.now.add(days: -30))
        
        return true
    }

    private func setVersionInSettings()
    {
        let appVersionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let buildNumber: String = Bundle.main.object(forInfoDictionaryKey:"CFBundleVersion") as! String
        UserDefaults.standard.set("\(appVersionString) (\(buildNumber))", forKey: "version_string")
    }
    
    private func setAppearance()
    {
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().tintColor = UIColor.white
    }
    
    private func logAppStartup(_ isInBackground: Bool)
    {
        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        let startedOn = isInBackground ? "background" : "foreground"
        let message = "Application started on \(startedOn). App Version: \(versionNumber) Build: \(buildNumber)"

        loggingService.log(withLogLevel: .debug, message: message)
    }
    
    private func initializeWindowIfNeeded()
    {
        guard window == nil else { return }
        
        metricsService.initialize()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let viewModelLocator = DefaultViewModelLocator(timeService: timeService,
                                                       metricsService: metricsService,
                                                       feedbackService: feedbackService,
                                                       locationService: locationService,
                                                       settingsService: settingsService,
                                                       timeSlotService: timeSlotService,
                                                       editStateService: editStateService,
                                                       smartGuessService : smartGuessService,
                                                       appLifecycleService: appLifecycleService,
                                                       selectedDateService: selectedDateService,
                                                       loggingService: loggingService,
                                                       healthKitService: healthKitService,
                                                       notificationService: notificationService)
        
        if settingsService.installDate == nil
        {
            notificationService.scheduleNormalNotification(date: Date().addingTimeInterval(Constants.timeToWaitBeforeShowingHealthKitPermissions), title: "", message: L10n.notificationHealthKitAccessBody)
        }
        
        window!.rootViewController = IntroPresenter.create(with: viewModelLocator)
        window!.makeKeyAndVisible()
    }
    
    func applicationWillResignActive(_ application: UIApplication)
    {
        appLifecycleService.publish(.movedToBackground)
    }

    func applicationDidEnterBackground(_ application: UIApplication)
    {
        locationService.startLocationTracking()
    }

    func applicationDidBecomeActive(_ application: UIApplication)
    {
        pipeline.run()
        
        initializeWindowIfNeeded()
     
        notificationService.unscheduleAllNotifications(ofTypes: .categorySelection)
        
        appLifecycleService.publish(.movedToForeground(fromNotification:didReceiveCategoryNotification))
        didReceiveCategoryNotification = false
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings)
    {
        notificationAuthorizedSubject.on(.next(()))
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification)
    {
        didReceiveCategoryNotification = isCategorySelectionNotification(notification)
    }
    
    private func isCategorySelectionNotification(_ notification:UILocalNotification) -> Bool
    {
        guard
            let identifier = notification.userInfo?["id"] as? String,
            identifier == NotificationType.categorySelection.rawValue
            else { return false }
        
        return true
    }
    
    @available(iOS 10.0, *)
    fileprivate func isCategorySelectionNotification(_ notification:UNNotification) -> Bool
    {
        guard
            let identifier = notification.request.content.userInfo["id"] as? String,
            identifier == NotificationType.categorySelection.rawValue
            else { return false }
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication)
    {
        coreDataStack.saveContext()
    }
}

@available(iOS 10.0, *)
extension AppDelegate:UNUserNotificationCenterDelegate
{
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        didReceiveCategoryNotification = isCategorySelectionNotification(response.notification)
        completionHandler()
    }
}
