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
    private var timeSlotService : MockTimeSlotService!
    private var notificationService : PostiOSTenNotificationService!
    
    override func setUp()
    {
        self.timeService = MockTimeService()
        self.loggingService = MockLoggingService()
        self.locationService = MockLocationService()
        self.timeSlotService = MockTimeSlotService(timeService: self.timeService,
                                                   locationService: self.locationService)
        
        self.notificationService = PostiOSTenNotificationService(timeService: self.timeService,
                                                                 loggingService: self.loggingService,
                                                                 timeSlotService: self.timeSlotService)
    }
    
    func testFakeTimeSlotIsInsertedInNotification()
    {
        self.timeSlotService.addTimeSlot(withStartTime: Date(), category: .work, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        self.notificationService.scheduleNotification(date: Date().addingTimeInterval(20 * 60), title: "", message: "", possibleFutureSlotStart: Date())
        
        waitUntil { done in
            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (requests) in
                let category = (requests.last?.content.userInfo["timeSlots"] as! [[String : String]]).last?["category"]
                expect(category).to(beNil())
                done()
            })
        }
    }
    
    func testFakeTimeSlotIsNotInsertionInNotification()
    {
        self.timeSlotService.addTimeSlot(withStartTime: Date(), category: .work, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        
        print(timeSlotService.getTimeSlots(forDay: Date()))
        
        self.notificationService.scheduleNotification(date: Date().addingTimeInterval(20 * 60), title: "", message: "", possibleFutureSlotStart: nil)
        
        waitUntil { done in
            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (requests) in
                let category = (requests.last?.content.userInfo["timeSlots"] as! [[String : String]]).last?["category"]
                expect(category).toNot(beNil())
                done()
            })
        }
    }
}
