import XCTest
import Nimble
import HealthKit
@testable import teferi

class HealthKitPumpTests : XCTestCase
{
    private typealias TupleHKSample = (start: Double, end: Double, identifier: String, quantity: Double)
    private typealias TupleTempTimeSlot = (start: Double, category: teferi.Category)
    
    private let startData = Date().ignoreTimeComponents()
    
    private var loggingService: MockLoggingService!
    private var trackEventService : MockTrackEventService!
    private var healthKitPump : HealthKitPump!
    
    override func setUp()
    {
        loggingService = MockLoggingService()
        trackEventService = MockTrackEventService()
        healthKitPump = HealthKitPump(trackEventService: trackEventService,
                                           loggingService: loggingService)
    }
    
    func minutes(_ time: String) -> Double
    {
        let components = time.components(separatedBy: ":")
        return Double(components[0])! * 60 + Double(components[1])! + Double(components[2])!/60
    }
    
    func testNonInBedSleepSamplesAreFilteredOut()
    {
        let sampleTuples : [TupleHKSample] = [(start: 00, end: 7*60, identifier: HKCategoryTypeIdentifier.sleepAnalysis.rawValue, quantity: 0),
                                              (start: 10, end: 20, identifier: HKCategoryTypeIdentifier.sleepAnalysis.rawValue, quantity: 1),
                                              (start: 20, end: 30, identifier: HKCategoryTypeIdentifier.sleepAnalysis.rawValue, quantity: 1)]
        
        trackEventService.mockEvents = sampleTuples.map(toTrackEvent)
        
        let expectedResultTuples : [TupleTempTimeSlot] = [(start: 00, category: .unknown),
                                                          (start: 7*60, category: .unknown)]
        
        let expectedResult = expectedResultTuples.map(toTempTimeSlot)
        
        let generatedTimeslots = healthKitPump.run()
        
        expect(generatedTimeslots.count).to(equal(expectedResult.count))
        
        generatedTimeslots
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedResult[i]) }
    }
    
    func testWithRealDataFromLogs()
    {
        let sampleTuples : [TupleHKSample] = [(start: minutes("01:45:56"), end: minutes("01:47:06"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 56.5300000002608),
                                              (start: minutes("01:47:06"), end: minutes("01:47:26"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 9.75),
                                              
                                              (start: minutes("01:53:37"), end: minutes("02:02:47"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 158.549999999348),
                                              (start: minutes("13:07:32"), end: minutes("13:08:37"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 11.4899999997579),
                                              
                                              (start: minutes("13:08:37"), end: minutes("13:09:04"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 17.5300000002608),
                                              (start: minutes("13:10:45"), end: minutes("13:11:45"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 80.7700000004843),
                                              (start: minutes("13:11:45"), end: minutes("13:13:08"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 54.3000000002794),
                                              (start: minutes("13:15:53"), end: minutes("13:15:59"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 12.4199999999255),
                                              (start: minutes("13:32:41"), end: minutes("13:33:31"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 16.5699999998324),
                                              (start: minutes("13:39:36"), end: minutes("13:40:26"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 22.6499999999069),
                                              
                                              (start: minutes("14:10:06"), end: minutes("14:10:26"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 2.87000000011176),
                                              (start: minutes("14:16:06"), end: minutes("14:16:26"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 0.319999999832362),
                                              
                                              (start: minutes("14:19:36"), end: minutes("14:20:38"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 22.5699999998324),
                                              
                                              (start: minutes("14:20:38"), end: minutes("14:22:26"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 17.6000000000931),
                                              
                                              (start: minutes("14:22:26"), end: minutes("14:23:06"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 23.5699999998324),
                                              (start: minutes("14:27:39"), end: minutes("14:27:45"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 8.97000000020489),
                                              (start: minutes("14:35:56"), end: minutes("14:36:03"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 10.8300000000745),
                                              
                                              (start: minutes("14:42:47"), end: minutes("14:44:17"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 8.3699999996461),
                                              
                                              (start: minutes("14:44:17"), end: minutes("14:44:20"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 5.91999999992549),
                                              (start: minutes("14:52:35"), end: minutes("14:52:58"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 24.9799999999814),
                                              (start: minutes("14:58:51"), end: minutes("14:59:21"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 13.2299999999814),
                                              
                                              (start: minutes("15:29:08"), end: minutes("15:35:18"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 6.56999999983236),
                                              (start: minutes("16:33:42"), end: minutes("16:43:32"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 46.8199999998324),
                                              (start: minutes("16:54:08"), end: minutes("17:01:38"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 21.3500000000931),
                                              (start: minutes("17:33:40"), end: minutes("17:35:30"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 8.37999999988824),
                                              (start: minutes("17:35:30"), end: minutes("17:36:31"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 5.83999999985099),
                                              (start: minutes("17:36:31"), end: minutes("17:37:53"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 7.29999999981374),
                                              
                                              (start: minutes("17:37:53"), end: minutes("17:37:58"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 10.0499999998137),
                                              (start: minutes("17:44:04"), end: minutes("17:45:14"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 67.3600000003353),
                                              (start: minutes("17:45:14"), end: minutes("17:46:16"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 55.269999999553),
                                              (start: minutes("17:46:16"), end: minutes("17:47:18"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 41.0600000005215),
                                              (start: minutes("17:48:28"), end: minutes("17:49:38"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 35.9499999997206),
                                              
                                              (start: minutes("17:49:38"), end: minutes("17:50:58"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 8.6199999996461),
                                              
                                              (start: minutes("17:50:58"), end: minutes("17:52:08"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 56.730000000447),
                                              (start: minutes("17:52:08"), end: minutes("17:52:38"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 17.1300000003539),
                                              (start: minutes("17:56:46"), end: minutes("17:57:51"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 44.5600000000559),
                                              (start: minutes("17:57:51"), end: minutes("17:58:44"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 25.7599999997765),
                                              (start: minutes("18:11:22"), end: minutes("18:12:22"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 30.0099999997765),
                                              
                                              (start: minutes("18:12:22"), end: minutes("18:22:07"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 25.9500000001863),
                                              (start: minutes("19:36:01"), end: minutes("19:39:12"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 7.81000000005588),
                                              (start: minutes("19:39:12"), end: minutes("19:40:25"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 19.4399999999441),
                                              
                                              (start: minutes("19:40:25"), end: minutes("19:40:30"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 6.83999999985099),
                                              (start: minutes("21:27:26"), end: minutes("21:28:26"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 42.2200000002049),
                                              
                                              (start: minutes("21:43:02"), end: minutes("21:45:02"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 4.41999999992549),
                                              
                                              (start: minutes("21:45:02"), end: minutes("21:46:12"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 69.4800000009127),
                                              (start: minutes("21:46:12"), end: minutes("21:47:22"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 80.0),
                                              (start: minutes("21:47:22"), end: minutes("21:48:32"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 69.6400000001304),
                                              (start: minutes("21:48:32"), end: minutes("21:49:02"), identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 22.3799999998882)]
        
        trackEventService.mockEvents = sampleTuples.map(toTrackEvent)
        
        let expectedResultTuples : [TupleTempTimeSlot] = [(start: minutes("01:45:56"), category: .commute),
                                                          (start: minutes("02:02:47"), category: .unknown),
                                                          (start: minutes("13:08:37"), category: .commute),
                                                          (start: minutes("13:15:59"), category: .unknown),
                                                          (start: minutes("13:32:41"), category: .commute),
                                                          (start: minutes("13:40:26"), category: .unknown),
                                                          (start: minutes("14:19:36"), category: .commute),
                                                          (start: minutes("14:59:21"), category: .unknown),
                                                          (start: minutes("15:35:18"), category: .unknown),
                                                          (start: minutes("16:33:42"), category: .unknown),
                                                          (start: minutes("17:01:38"), category: .unknown),
                                                          (start: minutes("17:37:53"), category: .commute),
                                                          (start: minutes("18:22:07"), category: .unknown),
                                                          (start: minutes("19:40:25"), category: .commute),
                                                          (start: minutes("19:40:30"), category: .unknown),
                                                          (start: minutes("21:27:26"), category: .commute),
                                                          (start: minutes("21:49:02"), category: .unknown)]
        
        let expectedResult = expectedResultTuples.map(toTempTimeSlot)
        
        let generatedTimeslots = healthKitPump.run()
        
        expect(generatedTimeslots.count).to(equal(expectedResult.count))
        
        generatedTimeslots
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedResult[i]) }
    }
    
    func testExtraUnknownTemporaryTimeslotIsAddedInTheEnd()
    {
        trackEventService.mockEvents = [(start: 00, end: 10, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 0)].map(toTrackEvent)
        
        let expectedResult = [(start: 00, category: .commute),
                              (start: 10, category: .unknown)].map(toTempTimeSlot)
        
        let generatedTimeslots = healthKitPump.run()
        
        expect(generatedTimeslots.count).to(equal(expectedResult.count))
        
        generatedTimeslots
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedResult[i]) }
    }
    
    func testContinuousHealthSamplesFromSameTypeAreMergedIntoOneTemporaryTimeslot()
    {
        let sampleTuples : [TupleHKSample] = [(start: 00, end: 10, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 0),
                                              (start: 10, end: 20, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 0),
                                              (start: 20, end: 23, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 0),
                                              (start: 23, end: 25, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 0)]
        
        trackEventService.mockEvents = sampleTuples.map(toTrackEvent)
        
        let expectedResultTuples : [TupleTempTimeSlot] = [(start: 0, category: .commute),
                                                          (start: 25, category: .unknown)]
        
        let expectedResult = expectedResultTuples.map(toTempTimeSlot)
        
        let generatedTimeslots = healthKitPump.run()
        
        expect(generatedTimeslots.count).to(equal(expectedResult.count))

        generatedTimeslots
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedResult[i]) }
    }
    
    func testContinuousHealthSamplesFromDifferentTypesAreMergedIntoSeparateTemporaryTimeslot()
    {
        let sampleTuples : [TupleHKSample] = [(start: 00, end: 10, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 200),
                                              (start: 10, end: 20, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 200),
                                              (start: 20, end: 30, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 200),
                                              (start: 30, end: 40, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 200),
                                              (start: 40, end: 50, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 200),
                                              (start: 50, end: 60, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 200),
                                              (start: 60, end: 70, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 200),
                                              (start: 70, end: 80, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 200)]
        
        trackEventService.mockEvents = sampleTuples.map(toTrackEvent)
        
        let expectedResultTuples : [TupleTempTimeSlot] = [(start: 00, category: .commute),
                                                          (start: 80, category: .unknown)]
        
        let expectedResult = expectedResultTuples.map(toTempTimeSlot)
        
        let generatedTimeslots = healthKitPump.run()
        
        expect(generatedTimeslots.count).to(equal(expectedResult.count))
        
        generatedTimeslots
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedResult[i]) }
    }
    
    func testCommuteIsDetectedInsideContinuousWalkingAndRunningSamples()
    {
        let sampleTuples : [TupleHKSample] = [(start: 00, end: 10, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 100),
                                              (start: 10, end: 15, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 50),
                                              
                                              (start: 15, end: 20, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 200),
                                              (start: 20, end: 30, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 250),
                                              
                                              (start: 30, end: 40, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 2),
                                              
                                              (start: 40, end: 50, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 200),
                                              (start: 50, end: 60, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 200),
                                              
                                              (start: 60, end: 70, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 20),
                                              (start: 70, end: 80, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 50),
            
                                              (start: 80, end: 90, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 200),
                                              (start: 90, end: 100, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 200),
                                              
                                              (start: 100, end: 110, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 4),
                                              (start: 110, end: 120, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 5),
                                              (start: 120, end: 130, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 6)]
        
        trackEventService.mockEvents = sampleTuples.map(toTrackEvent)
        
        let expectedResultTuples : [TupleTempTimeSlot] = [(start: 00, category: .unknown),
                                                          (start: 15, category: .commute),
                                                          (start: 60, category: .unknown),
                                                          (start: 80, category: .commute),
                                                          (start: 100, category: .unknown),
                                                          (start: 130, category: .unknown)]
        
        let expectedResult = expectedResultTuples.map(toTempTimeSlot)
        
        let generatedTimeslots = healthKitPump.run()
        
        expect(generatedTimeslots.count).to(equal(expectedResult.count))
        
        generatedTimeslots
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedResult[i]) }
    }
    
    func testContinuousSleepSamplesAreConvertedToSeparateTimeslots()
    {
        let sampleTuples : [TupleHKSample] = [(start: 00, end: 2*60, identifier: HKCategoryTypeIdentifier.sleepAnalysis.rawValue, quantity: 0),
                                              (start: 2*60, end: 3*60, identifier: HKCategoryTypeIdentifier.sleepAnalysis.rawValue, quantity: 0),
                                              (start: 3*60, end: 4*60, identifier: HKCategoryTypeIdentifier.sleepAnalysis.rawValue, quantity: 0),
                                              (start: 4*60, end: 11*60, identifier: HKCategoryTypeIdentifier.sleepAnalysis.rawValue, quantity: 0),
                                              (start: 11*60, end: 12*60, identifier: HKCategoryTypeIdentifier.sleepAnalysis.rawValue, quantity: 0)]
        
        trackEventService.mockEvents = sampleTuples.map(toTrackEvent)
        
        let expectedResultTuples : [TupleTempTimeSlot] = [(start: 00, category: .unknown),
                                                          (start: 2*60, category: .unknown),
                                                          (start: 3*60, category: .unknown),
                                                          (start: 4*60, category: .unknown),
                                                          (start: 11*60, category: .unknown),
                                                          (start: 12*60, category: .unknown)]
        
        let expectedResult = expectedResultTuples.map(toTempTimeSlot)
        
        let generatedTimeslots = healthKitPump.run()

        expect(generatedTimeslots.count).to(equal(expectedResult.count))
        
        generatedTimeslots
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedResult[i]) }
    }
    
    func testNonContinuousHealthSamplesFromSameTypeAreConvertedToSeparateTimeslotsWithUnknownTimeSlotInBetween()
    {
        let sampleTuples : [TupleHKSample] = [(start: 00, end: 10, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 0),
                                              (start: 10, end: 20, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 0),
                                              (start: 100, end: 110, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 0),
                                              (start: 110, end: 120, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 0)]
        
        trackEventService.mockEvents = sampleTuples.map(toTrackEvent)
        
        let expectedResultTuples : [TupleTempTimeSlot] = [(start: 0, category: .commute),
                                                          (start: 20, category: .unknown),
                                                          (start: 100, category: .commute),
                                                          (start: 120, category: .unknown)]
        
        let expectedResult = expectedResultTuples.map(toTempTimeSlot)
        
        let generatedTimeslots = healthKitPump.run()
        
        expect(generatedTimeslots.count).to(equal(expectedResult.count))
        
        generatedTimeslots
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedResult[i]) }
    }
    
    // MARK: - Helper
    private func toTempTimeSlot(tuple: TupleTempTimeSlot) -> TemporaryTimeSlot
    {
        return TemporaryTimeSlot(start: date(tuple.start), end: nil, smartGuess: nil, category: tuple.category, location: nil)
    }
    
    private func toTrackEvent(tuple: TupleHKSample) -> TrackEvent
    {
        var healthSample : HealthSample?
        
        switch tuple.identifier {
        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, HKQuantityTypeIdentifier.distanceCycling.rawValue:
            healthSample = HealthSample(withIdentifier: tuple.identifier, startTime: date(tuple.start), endTime: date(tuple.end), value: HKQuantity(unit: HKUnit.meter(), doubleValue: Double(tuple.quantity)))
        case HKCategoryTypeIdentifier.sleepAnalysis.rawValue:
            healthSample = HealthSample(withIdentifier: tuple.identifier, startTime: date(tuple.start), endTime: date(tuple.end), value: HKCategoryValue.init(rawValue: Int(tuple.quantity)))
        default:
            break
        }
        
        return TrackEvent.newHealthSample(sample: healthSample!)
    }
    
    private func date(_ timeInterval: TimeInterval) -> Date
    {
        return startData.addingTimeInterval(timeInterval * 60)
    }
    
    private func compare(timeSlot actualTimeSlot: TemporaryTimeSlot, to expectedTimeSlot: TemporaryTimeSlot)
    {
        expect(actualTimeSlot.start).to(equal(expectedTimeSlot.start))
        expect(actualTimeSlot.category).to(equal(expectedTimeSlot.category))
    }
}
