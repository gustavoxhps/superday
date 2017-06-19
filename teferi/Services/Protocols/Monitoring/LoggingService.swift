///Service that creates a log
protocol LoggingService
{
    //MARK: Methods
    
    /**
     Appends a message to the log file.
     
     - Parameter logLevel: Relevance of the information being logged
     - Parameter message: Message to be logged
     */
    func log(withLogLevel logLevel: LogLevel, message: String)
    
    /**
     Appends a message to the log file.
     
     - Parameter logLevel: Relevance of the information being logged
     - Parameter message: Object whose string conversion will be logged
     */
    func log(withLogLevel logLevel: LogLevel, message: CustomStringConvertible)
}
