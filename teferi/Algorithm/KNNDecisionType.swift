import Foundation

enum KNNDecisionType<ItemType, LabelType> where LabelType: Hashable
{
    case maxVote
    case minAvarageDistance
    
    private typealias InstanceAndParameters = (count: Int, distanceSum: Double, instance: ItemType)
    
    func chooseInstance(from neighbors: [(instance: ItemType, distance: Double)], with labelAction: (ItemType) -> LabelType) -> ItemType
    {
        switch self {
        case .maxVote:
            return groupedByLabel(items: neighbors, labelAction: labelAction)
                .sorted(by: { $0.value.0 > $1.value.0 })
                .first!
                .value
                .instance
        case .minAvarageDistance:
            return groupedByLabel(items: neighbors, labelAction: labelAction)
                .sorted(by: { $0.value.distanceSum / Double($0.value.count) < Double($1.value.distanceSum) / Double($1.value.count) })
                .first!
                .value
                .instance
        }
    }
    
    private func groupedByLabel(items: [(instance: ItemType, distance: Double)], labelAction getLabel: (ItemType) -> LabelType) -> [LabelType: InstanceAndParameters]
    {
        let groupedItemsByLabel = items.groupBy { (instance, _) -> LabelType in
            return getLabel(instance)
        }
        
        var dictToReturn = [LabelType: InstanceAndParameters]()
        
        groupedItemsByLabel.forEach { (itemsWithSameLabel) in
            
            let countAndDistanceSum = itemsWithSameLabel.reduce((count: 0, distanceSum: 0.0), { (result, element) in
                return (distanceSum: result.distanceSum + element.distance, count: result.count + 1)
            })
            
            let firstInstance = itemsWithSameLabel.first!.instance
            
            dictToReturn[getLabel(firstInstance)] = (count: countAndDistanceSum.count, distanceSum: countAndDistanceSum.distanceSum, instance: firstInstance)
        }
        
        return dictToReturn
    }
}
