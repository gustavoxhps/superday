import RxSwift
import CoreGraphics

protocol EditStateService
{
    var isEditingObservable : Observable<Bool> { get }
    
    var beganEditingObservable : Observable<(CGPoint, TimeSlot)> { get }
    
    func notifyEditingBegan(point: CGPoint, timeSlot: TimeSlot)
    
    func notifyEditingEnded()
}
