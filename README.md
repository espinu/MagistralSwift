# MagistralSwift
Magistral is a messaging library written in Swift 3.

Features
Requirements
Usage

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
  - **Intro -** [Prerequisites](#prerequisites), [Key-based access](#key-based-access) 
  - **Connecting -** [Connecting](#connecting), [Connection Callback](#connection-callback)
  - **Resources -** [Topics](#topics)
  - **Publish / Subscribe -** [Publish](#publish), [Subscribe](#subscribe)
  - **History -** [History](#history), [History for Time Interval](#history-for-time-interval)
  - **Access Control -** [Permissions](#permissions), [Grant permissions](#grant-permissions), [Revoke permissions](#revoke-permissions)
  
## Features

- [x] Send / receive data messages
- [x] Replay (Historical data) 
- [x] Resource discovery
- [x] Access Control
- [x] TLS-encrypted communication
- [ ] Client-side AES-encryption

## Requirements

- iOS 10.0+
- Xcode 8.0+
- Swift 3.0+

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.1.0+ is required to build MagistralSwift SDK

To integrate Magistral into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'MagistralSwift', '~> 0.5.1'
end
```

Then, run the following command:

```bash
$ pod install
```
### Manually

If you prefer not to use either of the aforementioned dependency managers, you can integrate MagistralSwift into your project manually.

---

## Usage

### Prerequisites

First of all, to stream data over Magistral Network you need to have an Application created.
If you don't have any of them yet, you can easily create one from [Customer Management Panel](https://app.magistral.io) 
(via start page or in [Application Management](https://app.magistral.io/#/apps) section).

Also, you need to have at least one topic created, that you can do from [Topic Management](https://app.magistral.io/#/topics) panel.

### Key-based access

Access to the Magistral Network is key-based. There are three keys required to establish connection:
  - **Publish Key** - Application-specific key to publish messages.
  - **Subscribe Key** - Application-specific key to read messages.
  - **Secret Key** - User-specific key to identify user and his permissions.

You can find both **Publish Key** and **Subscribe Key** in [Application Management](https://app.magistral.io/#/apps) section.
Select your App in the list and click Clipboard icons in App panel header to copy these keys into the Clipboard. 

**Secret Key** - can be found among user permissions in [User Management](https://app.magistral.io/#/usermanagement/) section.
You can copy secret key linked to user permissions into the Clipboard, just clicking right button in the permission list.

### Connecting
To establish connection with Magistral Network you need to create Magistral instance and provide **pub**, **sub** and **secret** keys.

```swift
import MagistralSwift

let magistral = Magistral(
    pubKey: "pub-xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    subKey: "sub-xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    secretKey: "s-xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx");
```

### Connection Callback
It usually takes milliseconds to establish connection to the Network and be able to use Magistral functions.

Thus, to get notified when connection is ready you provide additional [callback](http://en.wikipedia.org/wiki/Callback_%28computer_programming%29)
parameter. It contains connection status  and reference to Magistral instance: 

```swift
import MagistralSwift

let magistral = Magistral(pubKey: {pub_key}, subKey: {sub_key}, secretKey: {secret_key},
    connected: { connected, magistral in
      ...
    });
```
### Topics

### Publish

### Subscribe

### History

### History for Time Interval

### Permissions

### Grant permissions

### Revoke permissions
