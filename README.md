# [SwiftShift.app](https://swiftshift.app)

> Sweet window management for macOS

https://github.com/pablopunk/SwiftShift/assets/4324982/5f27ae84-1584-4682-bf82-13d34b4c7fde


## Installation

There are 3 possible ways:

* Get it at [swiftshift.app](https://swiftshift.app)
* Download the latest release on Github
* Clone it and build it yourself

## Features


<img src="https://github.com/pablopunk/SwiftShift/assets/4324982/3b8937aa-6dce-4129-a5a4-9ca49f3ca157" width="380" />

* Launch at login
* Hide menubar icon
* Focus on window
* Smart resizing with quadrants

### Quadrants

https://github.com/pablopunk/SwiftShift/assets/4324982/5aac5bab-ad87-43c1-b2fe-fd55077f56f6


## Contributing

You can either use Xcode ([be careful with signing](https://github.com/pablopunk/SwiftShift/issues/52#issuecomment-2160423351)) or build it
directly from the command line:

### Build and run from the command line

```bash
make run
```

### Accessibility permissions running locally

Make sure you don't have Swift Shift running already. If you have 2 versions of Swift Shift, only one will get
Accessibility permissions. To fix it:

* Quit all Swift Shift instances
* Remove Swift Shift from the System Preferences > Security & Privacy > Accessibility
* Run the app you want to test
* Enable Accessibility permissions

I'm open to PRs and requests. If you are looking for something to do, take a look at the issues marked as [`help wanted`](https://github.com/pablopunk/SwiftShift/issues?q=is:issue+is:open+label:%22help+wanted%22).

![header](https://github.com/pablopunk/swiftshift.app/blob/main/public/header-dark-extended.png?raw=true#gh-dark-mode-only)
![header](https://github.com/pablopunk/swiftshift.app/blob/main/public/header-light-extended.png?raw=true#gh-light-mode-only)
