import RxSwift
import CoreGraphics

protocol EditStateService
{
    var isEditingObservable : Observable<Bool> { get }
    
    var beganEditingObservable : Observable<(CGPoint, TimelineItem)> { get }
    
    func notifyEditingBegan(point: CGPoint, timelineItem: TimelineItem)
    
    func notifyEditingEnded()
}
