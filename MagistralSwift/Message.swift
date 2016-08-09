//
//  Message.swift
//  ios
//
//  Created by rizarse on 02/08/16.
//  Copyright © 2016 magistral.io. All rights reserved.
//

import Foundation

public struct Message {
    
    private var _topic : String;
    private var _channel : Int;
    private var _body : [UInt8];
    private var _index : UInt64;
    private var _timestamp : UInt64;
    
    init(topic: String, channel: Int, msg: [UInt8], index: UInt64, timestamp: UInt64) {
        self._topic = topic;
        self._channel = channel;
        self._index = index;
        self._body = msg;
        self._timestamp = timestamp;
    }
    
    public func index() -> UInt64 {
        return self._index;
    }
    
    public func topic() -> String {
        return self._topic;
    }
    
    public func channel() -> Int {
        return self._channel;
    }
    
    public func body() -> [UInt8] {
        return self._body;
    }
    
    public func timestamp() -> UInt64 {
        return self._timestamp;
    }
}