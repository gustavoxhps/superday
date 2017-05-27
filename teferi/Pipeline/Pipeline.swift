import Foundation

class Pipeline
{
    private let pumps : [Pump]
    private var pipes = [Pipe]()
    private var sinks = [Sink]()
    private var crossPipe : CrossPipe!
    private let loggingService : LoggingService
    
    private init(withPumps pumps: [Pump], loggingService: LoggingService)
    {
        self.loggingService = loggingService
        self.pumps = pumps
    }
    
    func pipe(to crossPipe: CrossPipe) -> Pipeline
    {
        guard self.crossPipe == nil else { fatalError("You can only add one crossPipe") }
        
        self.crossPipe = crossPipe
        return self
    }
    
    func pipe(to pipe: Pipe) -> Pipeline
    {
        pipes.append(pipe)
        return self
    }
    
    func sink(_ sink: Sink) -> Pipeline
    {
        sinks.append(sink)
        return self
    }
    
    func run()
    {
        let pipelineStartTime = Date()
        loggingService.log(withLogLevel: .info, message: "Pipeline started running")
        
        let pumpData = self.pumps.map { $0.run() }
        let timeline = pipes.reduce(crossPipe.process(timeline: pumpData)) { timeline, pipe in
            return pipe.process(timeline: timeline)
        }
        
        loggingService.log(withLogLevel: .info, message: "Merge temporary timeline:")
        timeline.forEach { (slot) in
            self.loggingService.log(withLogLevel: .info, message: "MergedSlot start: \(slot.start) category: \(slot.category.rawValue)")
        }
        
        sinks.forEach { sink in sink.execute(timeline: timeline) }
        
        loggingService.log(withLogLevel: .info, message: "Pipeline ended running (execution time: \(Date().timeIntervalSince(pipelineStartTime)))")
    }
    
    static func with(loggingService: LoggingService, pumps: Pump...) -> Pipeline
    {
        return Pipeline(withPumps: pumps, loggingService: loggingService)
    }
}
