# ![](https://github.com/toggl/superday/blob/develop/teferi/Assets.xcassets/icSuperday.imageset/icSuperday.png) Superday
More time, more life.
Superday tracks your activities, you give the context.

# Contributors Guide

This is meant to help new contributors submit changes to the project.

## Getting started

Requirements:

- [Xcode](https://itunes.apple.com/us/app/xcode/id497799835)
- [CocoaPods](https://guides.cocoapods.org/using/getting-started.html#installation)

Downloading and starting development for Superday is supersimple™:

1. Fork this repository
2. Clone it locally
3. `$ cd` to location
4. Run `$ pod install` to fetch dependencies
5. Open `teferi.xworkspace` to start working
6. There is no step six

## Pull Request Etiquette

**Our goal as the developers of Superday is to create an app of the highest quality in terms of both the user experience and the code base.**

All code changes to Superday are added using GitHub's pull requests. To be able to merge a pull request, it has to be approved by at least one other developer and pass unit tests. Therefore it is of supreme importance that each pull request is as easy to review as possible. To facilitate this, follow these guidelines:

1. Pull requests should always result in a functional and bug-free app
2. Pull requests should be as small and straight forward as possible
    - Each pull request should make a single clearly defined change or addition
    - Change as many files as necessary, but as few as possible
    - Do not add unrelated changes - even minor code cleanup - to your pull request
        - Create a separate pull request instead
        - If possible, split larger pull requests into multiple ones
3. Pull requests should be presented well
    - Use a clear and succinct title
        - If this is not possible, the pull request is most likely too big
    - Add a description if needed
    - Add references to related issues/pull requests to the description
        - If the pull request closes an issue, [include `Closes #issue`](https://github.com/blog/1506-closing-issues-via-pull-requests)

It is the contributor's responsibility to make sure the merging branch is up to date with the base branch. If you would like feedback on a work-in-progress feature, feel free to create a pull request and mark it with the `wip` label. Make sure to comment on what kind of feedback you are looking for.

### Code review

Code review is one of the primary ways we ensure the quality of the app. **Code can only be merged into the main branches of the repository if it has been read, understood, analysed, and accepted as correct by at least one other developer.** For larger features feedback from multiple developers might be needed to ensure correctness.

Developers should be thorough and critical with both their own code, but especially when reviewing. Requested changes should only be implemented if the contributor agrees with them. Otherwise the change should be discussed.

A pull request should only be accepted after a full review and if the reviewer is confident of the code's correctness and conformity to our guidelines.

After a pull request has been approved it should not be changed except for bringing it up to date with the base branch, assuming the merge does not call into question the correctness of the pull request. Any other changes have to be explicitly agreed upon by reviewers though it is highly preferable to only accept the pull request once it is complete and up to date.

### Merging pull requests

Once a pull request is up to date with the base branch and approved, it should only be merged by the original contributor, unless they explicitly state that a reviewer is allowed to merge.

When merging, consider which type of merge supported by GitHub is the best choice. Most pull requests should be small enough to be squashed into a single commit that still follows the guidelines below. If this can not be done, prefer merging over rebasing to keep history intact.

### Swift style guide

Please refer to [this document](https://github.com/toggl/superday/blob/develop/docs/SwiftStyleGuide.md).

### Commits

- Keep commits small, clear and specific
- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move file to..." not "Moves file to...")
- Limit the first line to 72 characters or less
- Do not reference issues/pull requests in commit messages

#### Emoji Styleguide

Consider selecting the appropriate emoji for each of your commits (based on [Atom's emoji styleguide](https://github.com/atom/atom/blob/master/CONTRIBUTING.md#git-commit-messages)).

- :bug: `:bug:` - Bug fixes
- :memo: `:memo:` - Adding docs
- :fire: `:fire:` - Removing code
- :package: `:package:` - Adding new pods
- :green_heart: `:green_heart:` - Fixes CI Build
- :art: `:art:` - Adding UI components
- :white_check_mark: `:white_check_mark:` Adding tests
- :sparkles: `:sparkles:` - Adding a new feature
- :construction: `:construction:` - Work in Progress
- :racehorse: `:racehorse:` Improving performance
- :non-potable_water: `:non-potable_water:` Fixing memory leaks
- :lipstick: `:lipstick:` - Cosmetic changes to codestyle
- :triangular_ruler: `:triangular_ruler:` - Pixel perfect changes to UI
- :earth_americas: `:earth_americas:` - Changes to the location tracker
- :chart_with_upwards_trend: `:chart_with_upwards_trend:` - General improvements

### Branching and releasing

Superday uses an adapted version of GitFlow [by Vincent Driessen](http://nvie.com/posts/a-successful-git-branching-model/ "Original Blog post 'A successful Git branching model' by Vincent Driessen") called SuperFlow which is documented in [this document](https://github.com/toggl/superday/blob/develop/docs/SuperFlow.md "SuperFlow: Superday's branching work flow").