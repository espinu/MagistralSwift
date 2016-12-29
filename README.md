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

- iOS 9.0+
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
platform :ios, '9.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'MagistralSwift', '~> 0.6.2'
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

Thus, to get notification when connection is ready you provide additional [callback](http://en.wikipedia.org/wiki/Callback_%28computer_programming%29)
parameter. It contains connection status and reference to the Magistral instance: 

```swift
import MagistralSwift

let magistral = Magistral(pubKey: {pub_key}, subKey: {sub_key}, secretKey: {secret_key},
    connected: { connected, magistral in
      ...
    }
);
```
### Topics

To discover all available topics and channels you can call:
```swift
try magistral.topics { meta, err in
    for mi in meta {
        let topic = mi.topic()
        let channels = mi.channels();
//      Do something with topic and channels
    }
}
```

In case you know the topic name and want to see information about channels:
```swift
try magistral.topic("topic", callback: { meta, err in
    for mi in meta {
        let topic = mi.topic()
        let channels = mi.channels();
//      Do something with topic and channels
    }
});
```

### Publish

You can send data message to Magistral in this way:
```swift
let topic = "topic"
let channel = 0

try magistral.publish(topic, channel: channel, msg: Array("Hello from Swift SDK!".utf8), callback: { ack, error in
    print("✔︎ Published to " + ack.topic() + ":" + String(ack.channel()))
});
```
### Subscribe

This is an example how to subscribe and handle incoming data messages:
```swift
let topic = "topic"
let group = "leader"

try magistral.subscribe(topic, group: group, listener: { message, error in
        print("✔︎ Message received : " + String(message.channel()) + " : " 
                                      + String(message.index()) + " : " + String(message.timestamp()))
    }, callback: { subMeta, error in
        if error == nil {
            print("✔︎ Subscribed!")
        }
    }
);
```
### History

Magistral allows you to replay data  sent via some specific topic and channel. This feature called **History**.
To see last n-messages in the channel:
```swift
let topic = "topic"
let channel = 0
let count = 100

try magistral.history(topic, channel: channel, count: count, callback: { history, err in
    let messages = history.getMessages();    
    for msg in messages {
        print(String(msg.channel()) + " : " + String(msg.index()) + " : " + String(msg.timestamp()))
    }
});
```

You can also provide timestamp to start looking messages from:
```swift
let topic = "topic"
let channel = 0
let count = 100
let start = Date().timeIntervalSince1970.subtracting(6 * 60 * 60 * 1000);

try magistral.history(topic, channel: channel, start: UInt64(start), count: count, callback: { history, err in
    let messages = history.getMessages();    
    for msg in messages {
        print(String(msg.channel()) + " : " + String(msg.index()) + " : " + String(msg.timestamp()))
    }
});
```
### History for Time Interval

Historical data in Magistral can be obtained also for some period of time. You need to specify start and end date:
```swift
let topic = "topic"
let channel = 0

let start = Date().timeIntervalSince1970.subtracting(6 * 60 * 60 * 1000);
let end = Date().timeIntervalSince1970.subtracting(4 * 60 * 60 * 1000);

try magistral.history(topic, channel: channel, start: UInt64(start), end: UInt64(end), callback: { history, err in
    let messages = history.getMessages();    
    for msg in messages {
        print(String(msg.channel()) + " : " + String(msg.index()) + " : " + String(msg.timestamp()))
    }
});
```

### Permissions

This is a part of Access Control functionality. First of all, to see the full list of permissions:

```swift
try magistral.permissions({ meta, err in
    for mi in meta {
        for ch in mi.channels() {
            print(mi.topic() + ":" + String(ch) + " -> (r:w) .. " + String(mi.readable(ch)) + ":" + String(mi.writable(ch)));
        }
    }
});
```

Or if you are interested to get permissions for some specific topic:

```swift
try magistral.permissions("topic", callback: { meta, err in
    for mi in meta {
        for ch in mi.channels() {
            print(mi.topic() + ":" + String(ch) + " -> (r:w) .. " + String(mi.readable(ch)) + ":" + String(mi.writable(ch)));
        }
    }
});
```

### Grant permissions

You can also grant permissions for other users:
```swift
let user = "user"
let topic = "topic"
let channel = 0
let r = true
let w = true
                        
try magistral.grant(user, topic: topic, read: r, channel: channel, write: w, callback: { meta, error in
    if error == nil {
//      Permissions has been successfully granted
    }
});
```
> You must have super user priveleges to execute this function.

### Revoke permissions

In similar way you can revoke user permissions:
```swift
let user = "user"
let topic = "topic"
let channel = 0

try magistral.revoke(user, topic: topic, channel: channel, callback: { meta, err in
    if err == nil {
//      Permissions have been succefully revoked
    }
})
```
> You must have super user priveleges to execute this function.

## License
Magistral is released under the MIT license. See LICENSE for details.
