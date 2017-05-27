import RxSwift

class DefaultEditStateService : EditStateService
{
    //MARK: Fields
    private let isEditingSubject = PublishSubject<Bool>()
    private let beganEditingSubject = PublishSubject<(CGPoint, TimeSlot)>()
    
    //MARK: Initializers
    init(timeService: TimeService)
    {
        isEditingObservable = isEditingSubject.asObservable()
        beganEditingObservable = beganEditingSubject.asObservable()
    }
    
    //MARK: EditStateService implementation
    let isEditingObservable : Observable<Bool>
    let beganEditingObservable : Observable<(CGPoint, TimeSlot)>
    
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
