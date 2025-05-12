# [SwiftShift.app](https://swiftshift.app) [![Github all releases](https://img.shields.io/github/downloads/pablopunk/swiftshift/total.svg)](https://GitHub.com/pablopunk/swiftshift/releases/)

> Sweet window management for macOS

https://github.com/pablopunk/SwiftShift/assets/4324982/8f0566b9-d18e-462e-8d74-52bcf6c95f52


## Installation

There are several ways:

* Buy it at [swiftshift.app](https://swiftshift.app)
* Install it with homebrew `brew install --cask pablopunk/brew/swift-shift`
* Download the [latest release on Github](https://github.com/pablopunk/SwiftShift/releases)
* Clone it and build it yourself

## Features

<img src="https://github.com/pablopunk/SwiftShift/assets/4324982/58373dcf-217f-4b11-b734-dd0c1ee31063" width="380" />


* Launch at login
* Hide menubar icon
* Focus on window
* Smart resizing with quadrants
* Ignore custom apps

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
