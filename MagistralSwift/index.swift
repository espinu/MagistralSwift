//
//  index.swift
//  MagistralSwift
//
//  Created by rizarse on 29/12/2016.
//  Copyright © 2016 magistral.io. All rights reserved.
//

import Foundation
//
//  index.swift
//  MagistralSwift
//
//  Created by rizarse on 29/12/2016.
//  Copyright © 2016 magistral.io. All rights reserved.
//

import Foundation

public extension io.magistral.client.data.index {
    
    public struct TopicChannelIndex {
        
        fileprivate var _topic: String;
        fileprivate var _group: String;
        fileprivate var _channel: Int;
        fileprivate var _index: UInt64;
        
        init(topic : String, channel : Int, group : String, index : UInt64) {
            self._topic = topic;
            self._channel = channel;
            self._group = group;
            self._index = index;
        }
        
        public func topic() -> String {
            return self._topic;
        }
        
        public func channel() -> Int {
            return self._channel;
        }
        
        public func group() -> String {
            return self._group;
        }
        
        public func index() -> UInt64 {
            return self._index;
        }
    }
    
    typealias Callback = (TopicChannelIndex, MagistralException?) -> Void
}
