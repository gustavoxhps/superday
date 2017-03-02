import UIKit

protocol FeedbackService
{
    //Location of the log file
    var logURL : URL? { get }
    
    //Feedback UI has been shown
    /**
     Begins the feedback process, showing a feedback UI
     
     - Parameter parentViewController: The viewcontroller that presents the feedback UI
     
     - Parameter completed: Called when feedback UI is dismissed
     */
    func composeFeedback()
}
