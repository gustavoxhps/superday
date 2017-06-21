import CoreGraphics
import Foundation

///Contains the app's constants.
class Constants
{
    ///Minimum and maxium size of the TimeSlot cell line.
    static let minLineHeight: CGFloat = 20
    static let maxLineHeight: CGFloat = 72
    
    ///Minimum and maxium represenable time intervals for the TimeSlot cell line.
    static let minTimelineInterval: CGFloat = 10 * 60
    static let maxTimelineInterval: CGFloat = 60 * 60
    
    ///Timeline height slope to calculate the Timeslot cell line height.
    static let timelineSlope = (Constants.maxLineHeight - Constants.minLineHeight) / (Constants.maxTimelineInterval - Constants.minTimelineInterval)

    ///Key used for the preference that indicates whether the user is currently traveling or not.
    static let isTravelingKey = "isTravelingKey"
    
    ///Name of the file that stores information regarding the first location detected since the user's last travel.
    static let firstLocationFile = "firstLocationFile"
    
    ///Duration of the fade in/out edit animation
    static let editAnimationDuration = 0.09
    
    //Notification category identifier
    static let notificationCategoryId = "notificationTimeSlotCategorySelectionIdentifier"
    
    //Mark: Location Service Constants
    static let maxGPSTime:Double = 5.0
    static let gpsAccuracy:Double = 50.0 //meters
    static let significantLocationChangeAccuracy:Double = 2000.0 //meters
    static let significantDistanceThreshold:Double = 100.0
    static let commuteDetectionLimit = TimeInterval(25 * 60)
    static let timeToWaitBeforeShowingHealthKitPermissions : Double = 30*60 //30 min
    static let timeToWaitBeforeShowingLocationPermissionsAgain : Double = 60*60*24 //1 day

}
