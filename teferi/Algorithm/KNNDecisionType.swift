import Foundation

enum KNNDecisionType<ItemType, LabelType> where LabelType: Hashable
{
    case maxVote
    case minAvarageDistance
    
    private typealias CountAndInstance = (count: Int, distanceSum: Double, instance: ItemType)
    
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
    
    private func groupedByLabel(items: [(instance: ItemType, distance: Double)], labelAction getLabel: (ItemType) -> LabelType) -> [LabelType: CountAndInstance]
    {
        return items
            .reduce([LabelType: CountAndInstance](), { (result, item) in
                var newResult = result
                let newCount : Int = (result[getLabel(item.instance)]?.count ?? 0) + 1
                let newDistanceSum : Double = (result[getLabel(item.instance)]?.distanceSum ?? 0.0) + item.distance
                newResult[getLabel(item.instance)] = (count: newCount, distanceSum: newDistanceSum, instance: result[getLabel(item.instance)]?.instance ?? item.instance)
                return newResult
            })
    }
}
