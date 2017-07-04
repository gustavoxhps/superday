import RxTest

extension TestableObserver
{
    var values: [Element] {
        return events.flatMap { $0.value.element }
    }
}
