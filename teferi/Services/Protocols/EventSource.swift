import Foundation
import RxSwift

protocol EventSource
{
    var eventObservable : Observable<TrackEvent> { get }
}
