//
//  sub.swift
//  ios
//
//  Created by rizarse on 02/08/16.
//  Copyright © 2016 magistral.io. All rights reserved.
//

import Foundation

public extension io.magistral.client.sub {
    
    public struct SubMeta {
        
        private var _endPoints: [ String ]
        private var _group: String;
        private var _topic: String;
        private var _channel: Int;
        
        init(topic : String, channel : Int, group: String, endPoints: [String]) {
            self._topic = topic;
            self._channel = channel;
            
            self._group = group;
            self._endPoints = endPoints;
        }
        
        func endPoints() -> [ String ] {
            return self._endPoints;
        }
        
        func group() -> String {
            return self._group;
        }
        
        func topic() -> String {
            return self._topic;
        }
        
        func channel() -> Int {
            return self._channel;
        }
    }
    
    typealias Callback = (io.magistral.client.sub.SubMeta, MagistralException?) -> Void
    
    typealias NetworkListener = (Message, MagistralException?) -> Void
//    typealias NetworkListener = (MessageEvent, Connected?, Disconnected?, Reconnect?, MagistralException?) -> Void
}