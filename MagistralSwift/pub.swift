//
//  PubMeta.swift
//  ios
//
//  Created by rizarse on 02/08/16.
//  Copyright © 2016 magistral.io. All rights reserved.
//

import Foundation

public extension io.magistral.client.pub {
    
   public struct PubMeta {
        
        fileprivate var _topic: String;
        fileprivate var _channel: Int;
        
        init(topic : String, channel : Int) {
            self._topic = topic;
            self._channel = channel;
        }
        
        func topic() -> String {
            return self._topic;
        }
        
        func channel() -> Int {
            return self._channel;
        }
    }
    
    typealias Callback = (PubMeta, MagistralException?) -> Void
}
