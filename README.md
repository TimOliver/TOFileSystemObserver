# TOFileSystemObserver

<img src="https://raw.githubusercontent.com/TimOliver/TOFileSystemObserver/master/screenshot.jpg" width="880" alt="TOFileSystemObserver" />

[![CI](https://github.com/TimOliver/TOFileSystemObserver/workflows/CI/badge.svg)](https://github.com/TimOliver/TOFileSystemObserver/actions?query=workflow%3ACI)
[![Version](https://img.shields.io/cocoapods/v/TOFileSystemObserver.svg?style=flat)](http://cocoadocs.org/docsets/TOFileSystemObserver)
[![Platform](https://img.shields.io/cocoapods/p/TOFileSystemObserver.svg?style=flat)](http://cocoadocs.org/docsets/TOFileSystemObserver)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/TimOliver/TOFileSystemObserver/master/LICENSE)
[![PayPal](https://img.shields.io/badge/paypal-donate-blue.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=M4RKULAVKV7K8)
[![Twitch](https://img.shields.io/badge/twitch-timXD-6441a5.svg)](http://twitch.tv/timXD)

`TOFileSystemObserver` is a bullet-proof mechanism (hopefully) for detecting any user-initiated changes made to the contents of an iOS / iPadOS app's sandbox while the app is open.

Since iOS 11, the Files app has given the option to allow apps to expose the contents of their Documents directories to the users, letting them manipulate the files, either while the app is closed, suspended, or even running side-by-side with iPad multitasking.

For document-based apps that display a list of available files from the Documents library, this library aims to let you detect and respond to all file events that your app will need to adjust its UI and caches for.

# Features
* A single class that runs for the duration of the app session, and processes file events from the system.
* Can detect file changes on *any* subdirectory level.
* Can detect when the user imports a new file, and is able to detect when large files have finished copying.
* Can detect when the user moves a file, including between directory levels.
* Can detect when a user deletes a file, either from the Files app, or directly via iTunes.
* Can detect when a user renames a file.
* Can detect when a user duplicates the same file via the Files app.
* Provides "live" objects representing the contents of directories, and files which will update in conjunction with the file system.

# Example

```objc
#import "TOFileSystemObserver.h"

// Create a new instance (Targets the Documents directory by default)
TOFileSystemObserver *observer = [[TOFileSystemObserver alloc] init];

// Start observing the target directory.
[observer start];

// Register a notification token to receive events from the observer
TOFileSystemNotificationToken *observerToken = [self.observer addNotificationBlock:
				^(TOFileSystemObserver *observer, 
					TOFileSystemObserverNotificationType type, 
					TOFileSystemChanges *changes) 
{
	// At the start of the session, the observer will perform a full system scan. 
	// This event will give observers a chance to set up before the scan.
	if (type == TOFileSystemObserverNotificationTypeWillBeginFullScan) {
		NSLog(@"Scan Will Start!");
	  return;
	}
	        
	// At the start of the session, the observer will perform a full system scan. 
	// This event will give observers a chance to clean up after the scan.
	if (type == TOFileSystemObserverNotificationTypeDidCompleteFullScan) {
		NSLog(@"Scan Complete!");
		return;
	}
        
  NSLog(@"%@", changes);
}];
```

Please check the sample app for more examples on the features of this library.

# Requirements

`TOFileSystemObserver` will work with iOS 9 and above. While it's been written in Objective-C, it will also work with Swift (But the Swift interface may need some more work.)

## Manual Installation

Copy the contents of the `TOFileSystemObserver` folder to your app project.

## CocoaPods

```
pod 'TOFileSystemObserver'
```

## Carthage and SPM

I only need CocoaPods for my current plans with this library, so Carthage and SPM are low priority for now. If you would like Carthage or SPM support, please submit a PR.

# How Does it Work?

Observing files on the file system consists of a variety of problems that each need to be solved to work.

### Receiving System Events for File Changes

Historically, [Apple staff have recommended](https://forums.developer.apple.com/thread/90531) using `DispatchSource` for detecting file changes. However, since this doesn't support subdirectories, it wasn't suitable here. Instead, `TOFileSystemObserver` uses [`NSFilePresenter`](https://developer.apple.com/documentation/foundation/nsfilepresenter) a component of coordinated file access to detect when a file has changed.

### Tracking Files Uniquely on Disk

Since it's very easy for file names to change, and there's no guarantee they'll be unique (eg, multiple `Chapter1.zip`  files in different folders), it was necessary to assign each file an ID that the user cannot easily modify and would be unique.

To that end, `TOFileSystemObserver` uses the [Extended File Attributes](https://nshipster.com/extended-file-attributes/) feature of APFS to attach a unique UUID string to each file it tracks. The observer then keeps an in-memory graph of every file's UUID and the URL of their last location, in order to determine when a file is moved or renamed.

### Determining When a File is Copying

`NSFilePresenter` will trigger 2 times for a file being copied in: once at the start, and again at the end. Since most file imports need to happen only when the file has finished copying, a way to check that the file has finished copying was necessary. I sadly lost the original Stack Overflow post, but an extremely bright person discovered that when a file is still copying, its reported modification date will be equal to the current date. In this way, we can check if the file is still copying or not.

# Credits

`TOFileSystemObserver` was created by [Tim Oliver](http://twitter.com/TimOliverAU) as a component of [iComics](http://icomics.co).

A huge thank you to [Jeffrey Bergier](https://twitter.com/jeffburg) whose [`JSBFileSystem`](https://github.com/jeffreybergier/JSBFilesystem) served as the base inspiration for this library, and for his help in letting me bounce ideas off him (such as eschewing having an on-disk store) during the start of this project.

iOS device mockup art by [Pixeden](http://pixeden.com).

# License

`TOFileSystemObserver` is available under the MIT license. Please see the [LICENSE](LICENSE) file for more information. ![analytics](https://ga-beacon.appspot.com/UA-5643664-16/TOFileSystemObserver/README.md?pixel)
