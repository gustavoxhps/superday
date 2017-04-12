import RxSwift
import Foundation

protocol PermissionViewModel
{
    var showOverlayObservable : Observable<Void> { get }
    var hideOverlayObservable : Observable<Void> { get }
    var permissionGivenObservable : Observable<Void> { get }
    var remindMeLater : Bool { get }
    var titleText : String? { get }
    var descriptionText : String { get }
    var enableButtonTitle : String { get }
    var image : UIImage? { get }
    
    func getUserPermission()
    func permissionGiven()
    func permissionDeferred()
}
