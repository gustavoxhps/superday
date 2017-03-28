class Pipeline
{
    private let pumps : [Pump]
    private var pipes = [Pipe]()
    private var sinks = [Sink]()
    private var crossPipe : CrossPipe!
    
    private init(withPumps pumps: [Pump])
    {
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
        let pumpData = pumps.map { $0.run() }
        var timeline = crossPipe.process(timeline: pumpData)
        
        for pipe in pipes
        {
            timeline = pipe.process(timeline: timeline)
        }
        
        self.sinks.forEach { sink in sink.execute(timeline: timeline) }
    }
    
    static func with(pumps: Pump...) -> Pipeline
    {
        return Pipeline(withPumps: pumps)
    }
}
