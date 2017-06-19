import CoreMotion

protocol MotionService
{
    /**
     Called when a new Motion Event happens.
     
     - Parameter activity: Contains the motion activity information.
     */
    func onNewMotion(_ activity: CMMotionActivity)
}
