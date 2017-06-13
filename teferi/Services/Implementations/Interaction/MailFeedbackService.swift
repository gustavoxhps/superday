import Foundation
import UIKit
import MessageUI

class MailFeedbackService: NSObject, FeedbackService, MFMailComposeViewControllerDelegate
{
    //MARK: Public Properties
    var logURL : URL?
    {
        let fileManager = FileManager.default
        var logURL : URL?
        if let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        {
            logURL = cacheDir.appendingPathComponent("swiftybeaver.log")
        }
        
        return logURL
    }
    
    //MARK: Private Properties
    private let recipients : [String]
    private let subject : String
    private let body : String
    private var completionHandler: () -> ()
    private var parentViewController : UIViewController!
    
    //MARK: Initializers
    init(recipients: [String], subject: String, body: String)
    {
        self.recipients = recipients
        self.subject = subject
        self.body = body
        self.completionHandler = { }
        
        super.init()
    }
    
    //MARK: Public Methods
    func with(viewController: UIViewController) -> FeedbackService
    {
        parentViewController = viewController
        return self
    }
    
    func composeFeedback()
    {
        //Check if email is set up in iOS Mail app
        guard MFMailComposeViewController.canSendMail() else
        {
            let alert = UIAlertController(title: "Oops! Seems like your email account is not set up.", message: "Go to “Settings > Mail > Add Account” to set up an email account or send us your feedback to support@toggl.com", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            alert.addAction(okAction)
            parentViewController.present(alert, animated: true, completion: nil)
            return
        }
        
        //Set email fields
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        composeVC.setToRecipients(recipients)
        composeVC.setSubject(subject)
        composeVC.setMessageBody(body, isHTML: false)
        
        //Attach log file, if it exists
        if let logURL = logURL, let data = try? Data(contentsOf: logURL)
        {
            composeVC.addAttachmentData(data, mimeType: "text/xml", fileName: "supertoday.log")
        }
        
        parentViewController.present(composeVC, animated: true)
    }

    // MARK: - MFMailComposeViewControllerDelegate
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        //Handle network errors
        if error != nil
        {
            let alertTitle = "Sorry. Can’t send email."
            let alertMessage = "You’re offline. Please connect to the internet and try again."
            let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            alert.addAction(okAction)
            
            controller.present(alert, animated: true)
        }
        
        completionHandler()
        controller.dismiss(animated: true)
    }
}
