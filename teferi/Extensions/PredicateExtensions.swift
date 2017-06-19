import CoreData

extension Predicate
{
    func convertToNSPredicate() -> NSPredicate
    {
        let predicate = NSPredicate(format: format, argumentArray: parameters)
        return predicate
    }
}
