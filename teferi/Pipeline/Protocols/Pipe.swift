protocol CrossPipe
{
    func process(timeline: [[TemporaryTimeSlot]]) -> [TemporaryTimeSlot]
}

protocol Pipe
{
    func process(timeline: [TemporaryTimeSlot]) -> [TemporaryTimeSlot]
}
