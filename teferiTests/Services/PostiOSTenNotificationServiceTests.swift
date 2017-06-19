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
        timeService = MockTimeService()
        loggingService = MockLoggingService()
        locationService = MockLocationService()
        settingsService = MockSettingsService()
        timeSlotService = MockTimeSlotService(timeService: timeService,
                                                   locationService: locationService)
        
        settingsService.setInstallDate(timeService.now.add(days: -8))
        
        notificationService = PostiOSTenNotificationService(timeService: timeService,
                                                                 loggingService: loggingService,
                                                                 settingsService: settingsService,
                                                                 timeSlotService: timeSlotService)
    }
    
    func testASimpleNotificationIsShownIfTheAppIsBeingUsedForLessThanAWeek()
    {
        
        settingsService.setInstallDate(timeService.now)
        notificationService = PostiOSTenNotificationService(timeService: timeService,
                                                                 loggingService: loggingService,
                                                                 settingsService: settingsService,
                                                                 timeSlotService: timeSlotService)
        
        
        notificationService.scheduleCategorySelectionNotification(date: Date().addingTimeInterval(20 * 60), title: "", message: "", possibleFutureSlotStart: nil)
        
        waitUntil { done in
            self.currentNotificationCenter.getPendingNotificationRequests(completionHandler: { (requests) in
                
                let notificationType = NotificationType(rawValue: requests.last!.content.userInfo["id"]! as! String)
                
                expect(notificationType).to(equal(NotificationType.categorySelection))
                done()
            })
        }
    }
    
    func testTheFourMostCommonCategoriesAreUsedInTheSuggestions()
    {
        [ .friends, .friends, .friends, .family, .family, .hobby, .hobby, .fitness, .fitness, .household ].forEach { category in
            self.timeSlotService.addTimeSlot(withStartTime: Date(), category: category, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        }
        
        notificationService.scheduleCategorySelectionNotification(date: Date().addingTimeInterval(20 * 60), title: "", message: "", possibleFutureSlotStart: nil)
        notificationService.setUserNotificationActions()
        
        let expectedCategories : [ teferi.Category ] = [ .friends, .family, .hobby, .fitness ]
        verifyNotificationCategories(expectedCategories)
    }
    
    func testTheFourSelectedCategoriesShouldNeverContainDuplicates()
    {
        timeSlotService.addTimeSlot(withStartTime: timeService.now, category: .work, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        timeSlotService.addTimeSlot(withStartTime: timeService.now, category: .food, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        timeSlotService.addTimeSlot(withStartTime: timeService.now, category: .hobby, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        
        notificationService.scheduleCategorySelectionNotification(date: Date().addingTimeInterval(20 * 60), title: "", message: "", possibleFutureSlotStart: nil)
        notificationService.setUserNotificationActions()
        
        let expectedCategories : [ teferi.Category ] = [ .work, .food, .hobby, .leisure ]
        verifyNotificationCategories(expectedCategories)
    }
    
    func testIfLessThanFourCategoriesAreFoundTheBlanksAreFillesWithTheDefaultCategories()
    {
        timeSlotService.addTimeSlot(withStartTime: timeService.now, category: .friends, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        timeSlotService.addTimeSlot(withStartTime: timeService.now, category: .family, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        
        notificationService.scheduleCategorySelectionNotification(date: Date().addingTimeInterval(20 * 60), title: "", message: "", possibleFutureSlotStart: nil)
        notificationService.setUserNotificationActions()
        
        let expectedCategories : [ teferi.Category ] = [ .friends, .family, .work, .food ]
        verifyNotificationCategories(expectedCategories)
    }
    
    func testFakeTimeSlotIsInsertedInNotification()
    {
        timeSlotService.addTimeSlot(withStartTime: timeService.now, category: .work, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        notificationService.scheduleCategorySelectionNotification(date: Date().addingTimeInterval(20 * 60), title: "", message: "", possibleFutureSlotStart: Date())
        
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
        timeSlotService.addTimeSlot(withStartTime: timeService.now, category: .work, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        
        notificationService.scheduleCategorySelectionNotification(date: Date().addingTimeInterval(20 * 60), title: "", message: "", possibleFutureSlotStart: nil)
        
        waitUntil { done in
            self.currentNotificationCenter.getPendingNotificationRequests(completionHandler: { (requests) in
                let category = (requests.last?.content.userInfo["timeSlots"] as! [[String : String]]).last?["category"]
                expect(category).toNot(beNil())
                done()
            })
        }
    }
    
    func testCategorySelectionNotificationDoNotHaveCategoryIdentifierSet()
    {
        notificationService.scheduleCategorySelectionNotification(date: Date().addingTimeInterval(20 * 60), title: "", message: "", possibleFutureSlotStart: nil)
        
        waitUntil { done in
            self.currentNotificationCenter.getPendingNotificationRequests(completionHandler: { (requests) in
                
                let notificationCategory = requests.last!.content.categoryIdentifier
                
                expect(notificationCategory).to(equal(""))
                done()
            })
        }
    }
    
    func testNormalNotificationDoNotHaveCategoryIdentifierSet()
    {
        notificationService.scheduleNormalNotification(date: Date().addingTimeInterval(20 * 60), title: "", message: "")
        
        waitUntil { done in
            self.currentNotificationCenter.getPendingNotificationRequests(completionHandler: { (requests) in
                
                let notificationCategory = requests.last!.content.categoryIdentifier
                
                expect(notificationCategory).to(equal(""))
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
