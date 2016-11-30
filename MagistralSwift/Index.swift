//
//  Index.swift
//  MagistralSwift
//
//  Created by rizarse on 27/11/2016.
//  Copyright © 2016 magistral.io. All rights reserved.
//

import Foundation

public struct Index {
    
    fileprivate var _topic : String;
    fileprivate var _channel : Int;
    fileprivate var _index : UInt64;
    
    init(topic: String, channel: Int, index: UInt64) {
        self._topic = topic;
        self._channel = channel;
        self._index = index;
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
}
