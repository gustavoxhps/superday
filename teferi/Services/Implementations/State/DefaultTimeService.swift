import Foundation

class DefaultTimeService : TimeService
{
    var now : Date { return Date() }
}
