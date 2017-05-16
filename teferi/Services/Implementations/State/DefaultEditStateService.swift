import RxSwift

class DefaultEditStateService : EditStateService
{
    //MARK: Fields
    private let isEditingSubject = PublishSubject<Bool>()
    private let beganEditingSubject = PublishSubject<(CGPoint, TimeSlot)>()
    
    //MARK: Initializers
    init(timeService: TimeService)
    {
        self.isEditingObservable = self.isEditingSubject.asObservable()
        self.beganEditingObservable = self.beganEditingSubject.asObservable()
    }
    
    //MARK: EditStateService implementation
    let isEditingObservable : Observable<Bool>
    let beganEditingObservable : Observable<(CGPoint, TimeSlot)>
    
    func notifyEditingBegan(point: CGPoint, timeSlot: TimeSlot)
    {
        self.isEditingSubject.on(.next(true))
        self.beganEditingSubject.on(.next((point, timeSlot)))
    }
    
    func notifyEditingEnded()
    {
        self.isEditingSubject.on(.next(false))
    }
}
