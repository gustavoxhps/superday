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
    
    func start()
    {
        let pumpData = pumps.map { $0.start() }
        var data = crossPipe.process(data: pumpData)
        
        for pipe in pipes
        {
            data = pipe.process(data: data)
        }
        
        self.sinks.forEach { sink in sink.execute(data: data) }
    }
    
    static func with(pumps: Pump...) -> Pipeline
    {
        return Pipeline(withPumps: pumps)
    }
}
