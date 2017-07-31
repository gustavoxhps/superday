import RxSwift

class DefaultEditStateService : EditStateService
{
    let isEditingObservable : Observable<Bool>
    let beganEditingObservable : Observable<(CGPoint, TimelineItem)>

    private let isEditingSubject = PublishSubject<Bool>()
    private let beganEditingSubject = PublishSubject<(CGPoint, TimelineItem)>()
    
    //MARK: Initializers
    init(timeService: TimeService)
    {
        isEditingObservable = isEditingSubject.asObservable()
        beganEditingObservable = beganEditingSubject.asObservable()
    }
    
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
