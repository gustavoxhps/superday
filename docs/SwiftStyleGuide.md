# ![](https://github.com/toggl/superday/blob/develop/teferi/Assets.xcassets/icSuperday.imageset/icSuperday.png) Superday's Swift Style Guide
##### AKA "The Dos And Don'ts Of This Codebase"

____________________

##### Classes use PascalCase
```swift
//Do
class Foo { }

//Don't
class bar { }
```

##### Fields, methods, properties and variables use camelCase
```swift
//Do
func foo(bar: Int) -> Int
{
    let baz = bar + 1
    return baz
}

//Don't
func Foo(Bar: Int) -> Int
{
    let Baz = Bar + 1
    return Baz
}
```

##### Use spaces over tabs and indent using 4 spaces
```swift
//Do
func foo()
{
    //Something
}

//Don't (use tabs)
func bar()
{
	//Something
}

//Don't (use less than four spaces)
func baz()
{
  //Something
}
```

##### Open braces on a new line

```swift
//Do
func foo()
{
}

//Don't
func bar() {
}
```

##### Prefer `let` over `var` unless `var` is need

```swift
//Do
func foo(bar: Int) -> Int
{
    let maxVal = 10
    return min(maxVal, bar)
}

//Don't
func foo(bar: Int) -> Int
{
    var maxVal = 10
    return min(maxVal, bar)
}
```

#####  Use `self.` whenever refering to a property/method of the class you're using

```swift
class Foo
{
    private let bar = 0

    //Do
    func baz() -> Int
    {
        return self.bar + 1
    }

    //Don't
    func qux() -> Int
    {
        return bar + 1
    }
}
```

##### Use the guard statement for early returning and property unwrapping

```swift

//Do
func boo(bar: String?)
{
    guard let unwrapped = bar else { return }
    //Magic goes here
}

//Don't

func boo(bar: String?)
{
    if bar != nil { return }
    let unwrapped = bar!
    //Magic goes here
}
```

##### Prefer early returning over nesting

```swift
//Do
func foo(bar: Int)
{
    guard bar > 0 else { return }

    let someValue = self.calculateSomething(bar)

    guard someValue > 0 else { return }

    // Magic goes here
}

//Don't
func foo(bar: Int)
{
    if bar > 0
    {
        let someValue = self.calculateSomething(bar)
        if someValue > 0
        {
            //Magic goes here
        }
    }
}
```

##### Use constraints (via .storyboard/.xib files or via [SnapKit](http://snapkit.io/)) and not hardcoded frames

```swift

//Do
func setupButton()
{
    let customView = MyCustomView()
    self.view.addSubview(customView)

    customView.snp.makeConstraints { make in make.edges.equalTo(self.view) }
}

//Don't
func setupButton()
{
    let customView = MyCustomView(frame: self.view.frame)
    self.view.addSubview(customView)
}

```

##### On functions

- Functions should be small. Generally more than 20 lines of code is too much.
- Every function should do one thing and one thing only.
- Naming is crucial; what the function does should be evident by reading its name and signature.
- Functions should be pure when possible (no side effects).
- Functions should only handle one level of abstraction, delegating to other functions for lower abstractions.
- Functions should generally be ordered from higher level to lower level, so they call functions below themselves, not above.

For example, this method...

```swift
func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
   {
       let toController = transitionContext.viewController(forKey: .to)!
       let fromController = transitionContext.viewController(forKey: .from)!
       let animationDuration = transitionDuration(using: transitionContext)

       if presenting
       {

           transitionContext.containerView.addSubview(toController.view)

           let finalFrame = transitionContext.finalFrame(for: toController)
           toController.view.frame = finalFrame.offsetBy(dx: 0, dy: transitionContext.containerView.frame.height)
           toController.view.alpha = 0.5

           UIView.animate(
               {
                   toController.view.frame = finalFrame
                   toController.view.alpha = 1.0
               },
               duration: animationDuration,
               delay: 0,
               options: [],
               withControlPoints: 0.175, 0.885, 0.32, 1.14,
               completion: {
                   transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
               }
           )
       }
       else
       {
           let initialFrame = transitionContext.initialFrame(for: fromController)
           let finalFrame = initialFrame.offsetBy(dx: 0, dy: transitionContext.containerView.frame.height)

           if transitionContext.isInteractive
           {
               UIView.animate(
                   withDuration: animationDuration,
                   animations: {
                       fromController.view.frame = finalFrame
                   },
                   completion: { p in
                       transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                   }
               )
           }
           else
           {
               UIView.animate(
                   {
                       fromController.view.frame = finalFrame
                       fromController.view.alpha = 0.5
                   },
                   duration: animationDuration,
                   delay: 0,
                   options: [],
                   withControlPoints: 0.4, 0.0, 0.6, 1,
                   completion: {
                       transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                   }
               )
           }
       }
   }
```

Would be much better this way:
```swift
func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        if presenting
        {
            presentModal(transitionContext: transitionContext)
        }
        else
        {
            if transitionContext.isInteractive
            {
                dismissModalInteractively(transitionContext: transitionContext)
            }
            else
            {
                dismissModal(transitionContext: transitionContext)
            }
        }
    }

    private func presentModal(transitionContext: UIViewControllerContextTransitioning)
    {
        let toController = transitionContext.viewController(forKey: .to)!
        let animationDuration = transitionDuration(using: transitionContext)

        transitionContext.containerView.addSubview(toController.view)

        let finalFrame = transitionContext.finalFrame(for: toController)
        toController.view.frame = finalFrame.offsetBy(dx: 0, dy: transitionContext.containerView.frame.height)
        toController.view.alpha = 0.5

        UIView.animate(
            {
                toController.view.frame = finalFrame
                toController.view.alpha = 1.0
        },
            duration: animationDuration,
            delay: 0,
            options: [],
            withControlPoints: 0.175, 0.885, 0.32, 1.14,
            completion: {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }

    private func dismissModal(transitionContext: UIViewControllerContextTransitioning)
    {
        let fromController = transitionContext.viewController(forKey: .from)!
        let animationDuration = transitionDuration(using: transitionContext)
        let initialFrame = transitionContext.initialFrame(for: fromController)
        let finalFrame = initialFrame.offsetBy(dx: 0, dy: transitionContext.containerView.frame.height)

        UIView.animate(
            {
                fromController.view.frame = finalFrame
                fromController.view.alpha = 0.5
        },
            duration: animationDuration,
            delay: 0,
            options: [],
            withControlPoints: 0.4, 0.0, 0.6, 1,
            completion: {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }

    private func dismissModalInteractively(transitionContext: UIViewControllerContextTransitioning)
    {
        let fromController = transitionContext.viewController(forKey: .from)!
        let animationDuration = transitionDuration(using: transitionContext)
        let initialFrame = transitionContext.initialFrame(for: fromController)
        let finalFrame = initialFrame.offsetBy(dx: 0, dy: transitionContext.containerView.frame.height)

        UIView.animate(
            withDuration: animationDuration,
            animations: {
                fromController.view.frame = finalFrame
        },
            completion: { p in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }

```

Is a good idea to run tools like [this one](https://github.com/yopeso/Taylor) which help you find long functions and many other code metrics.
