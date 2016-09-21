//
//  imagistral.swift
//  ios
//
//  Created by rizarse on 22/07/16.
//  Copyright © 2016 magistral.io. All rights reserved.
//

import Foundation

public protocol IMagistral : IAccessControl, IHistory {
    
    func subscribe(_ topic : String, listener : @escaping io.magistral.client.sub.NetworkListener, callback : io.magistral.client.sub.Callback?) throws;
    func subscribe(_ topic : String, channel : Int, listener : @escaping io.magistral.client.sub.NetworkListener, callback : io.magistral.client.sub.Callback?) throws;
    
    func subscribe(_ topic : String, group : String, listener : @escaping io.magistral.client.sub.NetworkListener, callback : io.magistral.client.sub.Callback?) throws;
    func subscribe(_ topic : String, group : String, channel : Int, listener : @escaping io.magistral.client.sub.NetworkListener, callback : io.magistral.client.sub.Callback?) throws;
    
    func unsubscribe(_ topic : String, callback : io.magistral.client.sub.Callback?) throws;
    func unsubscribe(_ topic : String, channel : Int, callback : io.magistral.client.sub.Callback?) throws;

    func publish(_ topic : String, msg : [UInt8], callback : io.magistral.client.pub.Callback?) throws;
    func publish(_ topic : String, channel : Int, msg : [UInt8], callback : io.magistral.client.pub.Callback?) throws;
    
    func topic(_ topic : String, callback : @escaping io.magistral.client.topics.Callback) throws;
    func topics(_ callback : @escaping io.magistral.client.topics.Callback) throws;
    
    func close();
}

public protocol IAccessControl {
    
    func permissions(_ callback : @escaping io.magistral.client.perm.Callback) throws;
    func permissions(_ topic: String, callback : @escaping io.magistral.client.perm.Callback) throws;
    
    func grant(_ user: String, topic: String, read: Bool, write: Bool, callback : io.magistral.client.perm.Callback?) throws;
    func grant(_ user: String, topic: String, read: Bool, write: Bool, ttl: Int, callback : io.magistral.client.perm.Callback?) throws;
    func grant(_ user: String, topic: String, channel: Int, read: Bool, write: Bool, callback : io.magistral.client.perm.Callback?) throws;
    func grant(_ user: String, topic: String, channel: Int, read: Bool, write: Bool, ttl: Int, callback : io.magistral.client.perm.Callback?) throws;
    
    func revoke(_ user: String, topic: String, callback : io.magistral.client.perm.Callback?) throws;
    func revoke(_ user: String, topic: String, channel: Int, callback : io.magistral.client.perm.Callback?) throws;
}

public protocol IHistory {
    func history(_ topic: String, channel: Int, count: Int, callback : @escaping io.magistral.client.data.Callback) throws;
    func history(_ topic: String, channel: Int, start: UInt64, count: Int, callback : @escaping io.magistral.client.data.Callback) throws;
    func history(_ topic: String, channel: Int, start: UInt64, end: UInt64, callback : @escaping io.magistral.client.data.Callback) throws;
}
