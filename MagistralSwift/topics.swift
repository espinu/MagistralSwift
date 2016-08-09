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
        
        private var _topic: String;
        private var _channels: Set<Int>;
        
        init(topic : String, channels : Set<Int>) {
            self._topic = topic;
            self._channels = channels;
        }
        
        func topic() -> String {
            return self._topic;
        }
        
        func channels() -> Set<Int> {
            return self._channels;
        }
    }
    
    typealias Callback = ([io.magistral.client.topics.TopicMeta], MagistralException?) -> Void
}