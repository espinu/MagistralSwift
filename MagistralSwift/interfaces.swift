//
//  imagistral.swift
//  ios
//
//  Created by rizarse on 22/07/16.
//  Copyright © 2016 magistral.io. All rights reserved.
//

import Foundation

public protocol IMagistral : IAccessControl, IHistory {
    
    func subscribe(topic : String, listener : io.magistral.client.sub.NetworkListener, callback : io.magistral.client.sub.Callback?) throws;
    func subscribe(topic : String, channel : Int, listener : io.magistral.client.sub.NetworkListener, callback : io.magistral.client.sub.Callback?) throws;
    
    func subscribe(topic : String, group : String, listener : io.magistral.client.sub.NetworkListener, callback : io.magistral.client.sub.Callback?) throws;
    func subscribe(topic : String, group : String, channel : Int, listener : io.magistral.client.sub.NetworkListener, callback : io.magistral.client.sub.Callback?) throws;
    
    func unsubscribe(topic : String, callback : io.magistral.client.sub.Callback?) throws;
    func unsubscribe(topic : String, channel : Int, callback : io.magistral.client.sub.Callback?) throws;

    func publish(topic : String, msg : [UInt8], callback : io.magistral.client.pub.Callback?) throws;
    func publish(topic : String, channel : Int, msg : [UInt8], callback : io.magistral.client.pub.Callback?) throws;
    
    func topic(topic : String, callback : io.magistral.client.topics.Callback) throws;
    func topics(callback : io.magistral.client.topics.Callback) throws;
    
    func close();
}

public protocol IAccessControl {
    
    func permissions(callback : io.magistral.client.perm.Callback) throws;
    func permissions(topic: String, callback : io.magistral.client.perm.Callback) throws;
    
    func grant(user: String, topic: String, read: Bool, write: Bool, callback : io.magistral.client.perm.Callback?) throws;
    func grant(user: String, topic: String, read: Bool, write: Bool, ttl: Int, callback : io.magistral.client.perm.Callback?) throws;
    func grant(user: String, topic: String, channel: Int, read: Bool, write: Bool, callback : io.magistral.client.perm.Callback?) throws;
    func grant(user: String, topic: String, channel: Int, read: Bool, write: Bool, ttl: Int, callback : io.magistral.client.perm.Callback?) throws;
    
    func revoke(user: String, topic: String, callback : io.magistral.client.perm.Callback?) throws;
    func revoke(user: String, topic: String, channel: Int, callback : io.magistral.client.perm.Callback?) throws;
}

public protocol IHistory {
    func history(topic: String, channel: Int, count: Int, callback : io.magistral.client.data.Callback) throws;
    func history(topic: String, channel: Int, start: UInt64, count: Int, callback : io.magistral.client.data.Callback) throws;
    func history(topic: String, channel: Int, start: UInt64, end: UInt64, callback : io.magistral.client.data.Callback) throws;
}