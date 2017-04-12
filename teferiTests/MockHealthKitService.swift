@testable import teferi
import RxSwift

class MockHealthKitService : HealthKitService
{
    // MARK: Fields
    private let publishSubject = PublishSubject<TrackEvent>()

    // MARK: Properties
    var started = false
    
    private(set) lazy var eventObservable : Observable<TrackEvent> =
    {
        return self.publishSubject.asObservable()
    }()
    
    // MARK: Methods
    func startHealthKitTracking()
    {
        started = true
    }
    
    func stopHealthKitTracking()
    {
        started = false
    }
    
    func requestAuthorization(completion: ((Bool)->())?)
    {
        completion?(true)
    }
    
    func sendNewTrackEvent(_ sample: HealthSample)
    {
        self.publishSubject.onNext(.newHealthSample(sample: sample))
    }
}
