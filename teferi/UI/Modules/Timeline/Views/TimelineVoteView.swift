import UIKit
import RxSwift

class TimelineVoteView: UIView
{
    private(set) lazy var didVoteObservable : Observable<Bool> =
    {
        return self.didVoteSubject.asObservable()
    }()
    private let didVoteSubject = PublishSubject<Bool>()
    
    @IBOutlet private weak var actionView: UIView!
    
    class func fromNib() -> TimelineVoteView
    {
        return Bundle.main.loadNibNamed("TimelineVoteView", owner: nil, options: nil)![0] as! TimelineVoteView
    }
    
    @IBAction private func upVoteAction(_ sender: UIButton)
    {
        didVoteSubject.onNext(true)
        hideActionView()
    }
    
    @IBAction private func downVoteAction(_ sender: UIButton)
    {
        didVoteSubject.onNext(false)
        hideActionView()
    }
    
    private func hideActionView()
    {
        actionView.isUserInteractionEnabled = false
        
        UIView.animate({ self.actionView.alpha = 0.0 }, duration: 0.3)
    }
}
