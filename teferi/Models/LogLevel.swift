import Foundation

/** Indicates the relevance of the information being logged
 
 - verbose: Something that's not so important.
 - debug: Relevant for debugging purposes.
 - info: Just info. Seriously.
 - warning: Something might go wrong if you ignore this.
 - error: Something went wrong. Possibly because you ignored a warning.
 */
enum LogLevel : String
{
    case verbose
    case debug
    case info
    case warning
    case error
    
    func errorDomain(with message: String) -> String
    {
        return self.rawValue.capitalized + ": " + message
    }
}
