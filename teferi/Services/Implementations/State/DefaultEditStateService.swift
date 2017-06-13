import RxSwift

class DefaultEditStateService : EditStateService
{
    let isEditingObservable : Observable<Bool>
    let beganEditingObservable : Observable<(CGPoint, TimeSlot)>

    private let isEditingSubject = PublishSubject<Bool>()
    private let beganEditingSubject = PublishSubject<(CGPoint, TimeSlot)>()
    
    //MARK: Initializers
    init(timeService: TimeService)
    {
        isEditingObservable = isEditingSubject.asObservable()
        beganEditingObservable = beganEditingSubject.asObservable()
    }
    
    func notifyEditingBegan(point: CGPoint, timeSlot: TimeSlot)
    {
        isEditingSubject.on(.next(true))
        beganEditingSubject.on(.next((point, timeSlot)))
    }
    
    func notifyEditingEnded()
    {
        isEditingSubject.on(.next(false))
    }
}
