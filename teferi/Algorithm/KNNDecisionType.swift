import Foundation

enum KNNDecisionType<ItemType, LabelType> where LabelType: Hashable
{
    case maxVote
    case maxAvarageScore
    case maxScoreSum
    
    private typealias InstanceAndParameters = (count: Int, scoreSum: Double, instance: ItemType)
    
    func chooseInstance(from neighbors: [(instance: ItemType, distance: Double)], with labelAction: (ItemType) -> LabelType) -> ItemType
    {
        switch self {
        case .maxVote:
            return groupedByLabel(items: neighbors, labelAction: labelAction)
                .sorted(by: { $0.value.count > $1.value.count })
                .first!
                .value
                .instance
        case .maxAvarageScore:
            return groupedByLabel(items: neighbors, labelAction: labelAction)
                .sorted(by: { $0.value.scoreSum / Double($0.value.count) > Double($1.value.scoreSum) / Double($1.value.count) })
                .first!
                .value
                .instance
        case .maxScoreSum:
            return groupedByLabel(items: neighbors, labelAction: labelAction)
                .sorted(by: { $0.value.scoreSum > Double($1.value.scoreSum) })
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
            
            let countAndDistanceSum = itemsWithSameLabel.reduce((count: 0, scoreSum: 0.0), { (result, element) in
                return (count: result.count + 1, scoreSum: result.scoreSum + (1 - element.distance))
            })
            
            let firstInstance = itemsWithSameLabel.first!.instance
            
            dictToReturn[getLabel(firstInstance)] = (count: countAndDistanceSum.count, scoreSum: countAndDistanceSum.scoreSum, instance: firstInstance)
        }
        
        return dictToReturn
    }
}
