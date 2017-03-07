import Foundation

class KNN<ItemType, LabelType> where LabelType: Hashable
{
    private typealias InstanceAndDistance = (instance: ItemType, distance: Double)
    
    typealias CustomDistance = (ItemType, ItemType) -> Double
    typealias GetLabelAction = (ItemType) -> LabelType
    
    static func prediction(
        for testInstance: ItemType,
        usingK k: Int,
        with dataset: [ItemType],
        decisionType: KNNDecisionType<ItemType, LabelType>,
        customDistance distance: @escaping CustomDistance,
        labelAction: GetLabelAction) -> ItemType?
    {
        guard k > 0 else { fatalError("k needs to be >0") }
        
        guard dataset.count >= k else { fatalError("k is smaller than the array count") }
        
        let neighbors = getNeighbors(in: dataset, for: testInstance, withK: k, customDistance: distance)
        let result = decisionType.chooseInstance(from: neighbors, with: labelAction)
        
        return result
    }
    
    private static func getNeighbors(
        in dataSet: [ItemType],
        for testInstance: ItemType,
        withK k: Int,
        customDistance distance: @escaping CustomDistance) -> [InstanceAndDistance]
    {
        let distances = dataSet.map({ (instance: $0, distance: distance(testInstance, $0)) })
        let topKNeighbors = distances
            .sorted(by: { $0.distance < $1.distance } )
            .prefix(k)
        
        return Array(topKNeighbors)
    }
}
