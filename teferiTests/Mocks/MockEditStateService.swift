import RxSwift
@testable import teferi

class MockEditStateService : EditStateService
{
    //MARK: Fields
    private let isEditingSubject = PublishSubject<Bool>()
    private let beganEditingSubject = PublishSubject<(CGPoint, TimeSlot)>()
    
    //MARK: Initializers
    init()
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
