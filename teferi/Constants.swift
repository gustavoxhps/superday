import CoreGraphics

///Contains the app's constants.
class Constants
{
    ///All possible categories
    static let categories : [Category] =  [ .commute, .food, .friends, .work, .leisure, .unknown ]
    
    ///Minimum size of the cosmetic line that appears on a TimeSlot cell.
    static let minLineSize = 12
    
    ///Key used for the preference that indicates whether the user is currently traveling or not.
    static let isTravelingKey = "isTravelingKey"
    
    ///Name of the file that stores information regarding the first location detected since the user's last travel.
    static let firstLocationFile = "firstLocationFile"
    
    ///Duration of the fade in/out edit animation
    static let editAnimationDuration = 0.08
    
    //Notification category identifier
    static let notificationTimeSlotCategorySelectionIdentifier = "notificationTimeSlotCategorySelectionIdentifier"
}
