import SwiftyBeaver
import Crashlytics

/// Implementation of LoggingService that depends on the SwiftyBeaver library
class SwiftyBeaverLoggingService : LoggingService
{
    //MARK: Fields
    private let swiftBeaver = SwiftyBeaver.self

    //MARK: Initializers
    init()
    {
        let file = FileDestination()
        file.format = "$Dyyyy-MM-dd HH:mm:ss.fff:$d $L => $M"
        swiftBeaver.addDestination(file)
    }
    
    //MARK: LoggingService implementation
    func log(withLogLevel logLevel: LogLevel, message: String)
    {
        switch logLevel
        {
            case .debug:
                swiftBeaver.debug(message)
            case .info:
                swiftBeaver.info(message)
            case .warning:
                swiftBeaver.warning(message)
            case .error:
                swiftBeaver.error(message)
        }
        
        #if !DEBUG
            guard logLevel == .error || logLevel == .warning else { return }
            
            logToCrashlytics(withLogLevel: logLevel, message: message)
        #endif
    }
    
    private func logToCrashlytics(withLogLevel logLevel: LogLevel, message: String)
    {
        let error = NSError(domain: logLevel.errorDomain(with: message), code: 0, userInfo: nil)
        Crashlytics.sharedInstance().recordError(error)
    }
    
    func log(withLogLevel logLevel: LogLevel, message: CustomStringConvertible)
    {
        log(withLogLevel: logLevel, message: message.description)
    }
}