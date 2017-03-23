protocol CrossPipe
{
    func process(data: [[TemporaryTimeSlot]]) -> [TemporaryTimeSlot]
}

protocol Pipe
{
    func process(data: [TemporaryTimeSlot]) -> [TemporaryTimeSlot]
}
