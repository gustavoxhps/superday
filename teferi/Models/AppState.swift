enum LifecycleEvent:Equatable
{
    case movedToForeground
    case movedToBackground
}

func == (lhs:LifecycleEvent, rhs:LifecycleEvent) -> Bool
{
    switch (lhs, rhs) {
    case (.movedToForeground, .movedToForeground):
        return true
    case (.movedToBackground, .movedToBackground):
        return true
    default:
        return false
    }
}
