import Foundation

class KNN<ItemType, LabelType> where LabelType: Hashable
{
    private typealias InstanceAndDistance = (instance: ItemType, distance: Double)
    private typealias customDistance = (ItemType, ItemType) -> Double
    private typealias getLabelActionType = (ItemType) -> LabelType
    
    class func prediction(
        for testInstance: ItemType,
        usingK k: Int,
        with dataset: [ItemType],
        customDistance distance: customDistance,
        labelAction getLabel: getLabelActionType) -> ItemType?
    {
        guard k > 0 else { return nil }
        
        guard dataset.count > 0 else { return nil }
        
        let neighbors = getNeighbors(in: dataset, for: testInstance, withK: k, customDistance: distance)
        let result = getResponse(neighbors: neighbors, labelAction: getLabel)
        
        return result
    }
    
    private class func getNeighbors(
        in trainingSet: [ItemType],
        for testInstance: ItemType,
        withK k: Int,
        customDistance distance: customDistance) -> [ItemType]
    {
        var distances = [InstanceAndDistance]()
        
        trainingSet.forEach { (trainingInstance) in
            let dist = distance(testInstance, trainingInstance)
            distances.append((trainingInstance, dist))
        }
        
        return distances
            .sorted(by: { $0.distance < $1.distance } )
            .prefix(k)
            .map({ $0.instance })
    }
    
    private class func getResponse(
        neighbors: [ItemType],
        labelAction getLabel: getLabelActionType) -> ItemType
    {
        return neighbors
            .reduce([LabelType: (Int, ItemType)](), { (result, instance) in
                var newResult = result
                let newVote : Int = (result[getLabel(instance)]?.0 ?? 0) + 1
                newResult[getLabel(instance)] = (newVote, instance)
                return newResult
            })
            .map { (element) in
                return (key: element.key, value: element.value)
            }
            .sorted(by: { $0.value.0 > $1.value.0 })
            .first!
            .value
            .1
    }
    
//    private class func getAccuracy(testSet: [ItemType], predictions: [ItemType]) -> Double
//    {
//        var correct = 0.0
//        for (index, instance) in testSet.enumerated()
//        {
//            correct += (instance.label == predictions[index].label) ? 1 : 0
//        }
//        return ( correct / Double(testSet.count) ) * 100.0
//    }
}
