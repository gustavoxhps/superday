import Foundation

class KNN
{
    private typealias InstanceAndDistance = (instance: KNNInstance, distance: Double)
    private typealias customDistance = (KNNInstance, KNNInstance) -> Double
    
    class func prediction(for testInstance: KNNInstance, usingK k: Int, with dataset: [KNNInstance], customDistance distance: customDistance) -> KNNInstance?
    {
        guard k > 0 else { return nil }
        
        guard dataset.count > 0 else { return nil }
        
        let neighbors = getNeighbors(in: dataset, for: testInstance, withK: k, customDistance: distance)
        let result = getResponse(neighbors: neighbors)
        
        return result
    }
    
    private class func getNeighbors(in trainingSet: [KNNInstance], for testInstance: KNNInstance, withK k: Int, customDistance distance: customDistance) -> [KNNInstance]
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
    
    private class func getResponse(neighbors: [KNNInstance]) -> KNNInstance
    {
        return neighbors
            .reduce([String: (Int, KNNInstance)](), { (result, instance) in
                var newResult = result
                let newVote : Int = (result[instance.label]?.0 ?? 0) + 1
                newResult[instance.label] = (newVote, instance)
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
    
    private class func getAccuracy(testSet: [KNNInstance], predictions: [KNNInstance]) -> Double
    {
        var correct = 0.0
        for (index, instance) in testSet.enumerated()
        {
            correct += (instance.label == predictions[index].label) ? 1 : 0
        }
        return ( correct / Double(testSet.count) ) * 100.0
    }
}
