import XCTest
import UserNotifications
import Nimble
@testable import teferi

@available(iOS 10.0, *)
class PostiOSTenNotificationServiceTests : XCTestCase
{
    private var timeService : MockTimeService!
    private var loggingService : LoggingService!
    private var locationService : MockLocationService!
    private var settingsService : MockSettingsService!
    private var timeSlotService : MockTimeSlotService!
    private var notificationService : PostiOSTenNotificationService!
    
    private var currentNotificationCenter : UNUserNotificationCenter
    {
        return UNUserNotificationCenter.current()
    }
    
    override func setUp()
    {
        self.timeService = MockTimeService()
        self.loggingService = MockLoggingService()
        self.locationService = MockLocationService()
        self.settingsService = MockSettingsService()
        self.timeSlotService = MockTimeSlotService(timeService: self.timeService,
                                                   locationService: self.locationService)
        
        self.settingsService.setInstallDate(self.timeService.now.add(days: -8))
        
        self.notificationService = PostiOSTenNotificationService(timeService: self.timeService,
                                                                 loggingService: self.loggingService,
                                                                 settingsService: self.settingsService,
                                                                 timeSlotService: self.timeSlotService)
    }
    
    func testASimpleNotificationIsShownIfTheAppIsBeingUsedForLessThanAWeek()
    {
        self.settingsService.setInstallDate(self.timeService.now)
        self.notificationService = PostiOSTenNotificationService(timeService: self.timeService,
                                                                 loggingService: self.loggingService,
                                                                 settingsService: self.settingsService,
                                                                 timeSlotService: self.timeSlotService)
        
        
        self.notificationService.scheduleCategorySelectionNotification(date: Date().addingTimeInterval(20 * 60), title: "", message: "", possibleFutureSlotStart: nil)
        
        waitUntil { done in
            self.currentNotificationCenter.getPendingNotificationRequests(completionHandler: { (requests) in
                
                let userInfo = requests.last!.content.userInfo
                expect(userInfo.count).to(equal(0))
                done()
            })
        }
    }
    
    func testTheFourMostCommonCategoriesAreUsedInTheSuggestions()
    {
        [ .friends, .friends, .friends, .family, .family, .hobby, .hobby, .fitness, .fitness, .household ].forEach { category in
            self.timeSlotService.addTimeSlot(withStartTime: Date(), category: category, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        }
        
        self.notificationService.scheduleCategorySelectionNotification(date: Date().addingTimeInterval(20 * 60), title: "", message: "", possibleFutureSlotStart: nil)
        self.notificationService.setUserNotificationActions()
        
        let expectedCategories : [ teferi.Category ] = [ .friends, .family, .hobby, .fitness ]
        self.verifyNotificationCategories(expectedCategories)
    }
    
    func testTheFourSelectedCategoriesShouldNeverContainDuplicates()
    {
        self.timeSlotService.addTimeSlot(withStartTime: timeService.now, category: .work, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        self.timeSlotService.addTimeSlot(withStartTime: timeService.now, category: .food, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        self.timeSlotService.addTimeSlot(withStartTime: timeService.now, category: .hobby, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        
        self.notificationService.scheduleCategorySelectionNotification(date: Date().addingTimeInterval(20 * 60), title: "", message: "", possibleFutureSlotStart: nil)
        self.notificationService.setUserNotificationActions()
        
        let expectedCategories : [ teferi.Category ] = [ .work, .food, .hobby, .leisure ]
        self.verifyNotificationCategories(expectedCategories)
    }
    
    func testIfLessThanFourCategoriesAreFoundTheBlanksAreFillesWithTheDefaultCategories()
    {
        self.timeSlotService.addTimeSlot(withStartTime: timeService.now, category: .friends, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        self.timeSlotService.addTimeSlot(withStartTime: timeService.now, category: .family, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        
        self.notificationService.scheduleCategorySelectionNotification(date: Date().addingTimeInterval(20 * 60), title: "", message: "", possibleFutureSlotStart: nil)
        self.notificationService.setUserNotificationActions()
        
        let expectedCategories : [ teferi.Category ] = [ .friends, .family, .work, .food ]
        self.verifyNotificationCategories(expectedCategories)
    }
    
    func testFakeTimeSlotIsInsertedInNotification()
    {
        self.timeSlotService.addTimeSlot(withStartTime: timeService.now, category: .work, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        self.notificationService.scheduleCategorySelectionNotification(date: Date().addingTimeInterval(20 * 60), title: "", message: "", possibleFutureSlotStart: Date())
        
        waitUntil { done in
            self.currentNotificationCenter.getPendingNotificationRequests(completionHandler: { (requests) in
                
                let category = (requests.last?.content.userInfo["timeSlots"] as! [[String : String]]).last?["category"]
                expect(category).to(beNil())
                done()
            })
        }
    }
    
    func testFakeTimeSlotIsNotInsertionInNotification()
    {
        self.timeSlotService.addTimeSlot(withStartTime: timeService.now, category: .work, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        
        self.notificationService.scheduleCategorySelectionNotification(date: Date().addingTimeInterval(20 * 60), title: "", message: "", possibleFutureSlotStart: nil)
        
        waitUntil { done in
            self.currentNotificationCenter.getPendingNotificationRequests(completionHandler: { (requests) in
                let category = (requests.last?.content.userInfo["timeSlots"] as! [[String : String]]).last?["category"]
                expect(category).toNot(beNil())
                done()
            })
        }
    }
    
    private func verifyNotificationCategories(_ expectedCategories: [teferi.Category])
    {
        waitUntil { done in
            self.currentNotificationCenter.getNotificationCategories(completionHandler: { (categories) in
                
                Array(categories).last!.actions.forEach { action in
                    
                    let category = teferi.Category(rawValue: action.identifier)!
                    
                    expect(expectedCategories.contains(category)).to(beTrue())
                }
                
                done()
            })
        }
    }
}
