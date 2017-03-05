//
//  topics.swift
//  MagistralSwift
//
//  Created by rizarse on 03/08/16.
//  Copyright © 2016 magistral.io. All rights reserved.
//

import Foundation

public extension io.magistral.client.topics {
    
    struct TopicMeta {
        
        fileprivate var _topic: String;
        fileprivate var _channels: Set<Int>;
        
        init(topic : String, channels : Set<Int>) {
            self._topic = topic;
            self._channels = channels;
        }
        
        public func topic() -> String {
            return self._topic;
        }
        
        public func channels() -> Set<Int> {
            return self._channels;
        }
    }
    
    typealias Callback = ([io.magistral.client.topics.TopicMeta], MagistralException?) -> Void
}
