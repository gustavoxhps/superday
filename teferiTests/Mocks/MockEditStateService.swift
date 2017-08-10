import RxSwift
@testable import teferi

class MockEditStateService : EditStateService
{
    //MARK: Fields
    private let isEditingSubject = PublishSubject<Bool>()
    private let beganEditingSubject = PublishSubject<(CGPoint, TimelineItem)>()
    
    //MARK: Initializers
    init()
    {
        isEditingObservable = isEditingSubject.asObservable()
        beganEditingObservable = beganEditingSubject.asObservable()
    }
    
    //MARK: EditStateService implementation
    let isEditingObservable : Observable<Bool>
    let beganEditingObservable : Observable<(CGPoint, TimelineItem)>
    
    func notifyEditingBegan(point: CGPoint, timelineItem: TimelineItem)
    {
        isEditingSubject.on(.next(true))
        beganEditingSubject.on(.next((point, timelineItem)))
    }
    
    func notifyEditingEnded()
    {
        isEditingSubject.on(.next(false))
    }
}
