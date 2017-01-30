import Foundation

protocol KNNInstance
{
    var attributes : [KNNAttributeType: AnyObject] { get }
    var label : String { get }
}
