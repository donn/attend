# attend for iOS
This is the iOS version of attend. It is currently maintained by [@skyus](https://github.com/skyus).

# Requirements
The app itself requires iOS 9 or later.

The code base was tested and confirmed working on Xcode 8.2.1.

## Dependencies
The codebase comes with all the dependencies it needs, including:

* Alamofire
* SwiftyJSON
* KDCircularProgress
* QRCodeReader.swift (Heavily Modified)

As long as you do not use a version with an updated API, it should be safe to update any of these dependencies to their latest versions, save for QRCodeReader.swift.

This version of QRCodeReader.swift is essentially an earlier fork that was customized for this app, adding features that were not then present such as embeddability and the ability to hide some buttons (some of this functionality has been added upstream since). It is not recommended to update it to a later upstream version unless you know exactly what you are doing.

Also, git submoduling is a bad idea, as Alamofire does not keep a "stable" branch.