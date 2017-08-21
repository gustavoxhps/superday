import UIKit
import RxSwift

class TimelineVoteView: UIView
{
    private(set) lazy var setVoteObservable : Observable<Bool> =
    {
        return self.setVoteSubject.asObservable()
    }()
    private let setVoteSubject = PublishSubject<Bool>()
    
    @IBOutlet private weak var actionView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var thankYouLabel: UILabel!
    
    class func fromNib() -> TimelineVoteView
    {
        let voteView = Bundle.main.loadNibNamed("TimelineVoteView", owner: nil, options: nil)![0] as! TimelineVoteView
        voteView.titleLabel.text = L10n.votingUITitle
        voteView.messageLabel.text = L10n.votingUIMessage
        voteView.thankYouLabel.text = L10n.votingUIThankYou
        return voteView
    }
    
    @IBAction private func upVoteAction(_ sender: UIButton)
    {
        setVoteSubject.onNext(true)
        hideActionView()
    }
    
    @IBAction private func downVoteAction(_ sender: UIButton)
    {
        setVoteSubject.onNext(false)
        hideActionView()
    }
    
    private func hideActionView()
    {
        actionView.isUserInteractionEnabled = false
        
        UIView.animate({ self.actionView.alpha = 0.0 }, duration: 0.3)
    }
}
