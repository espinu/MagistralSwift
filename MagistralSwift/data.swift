//
//  data.swift
//  ios
//
//  Created by rizarse on 02/08/16.
//  Copyright © 2016 magistral.io. All rights reserved.
//

import Foundation

public extension io.magistral.client.data {
    
    public struct History {
        
        fileprivate var _messages: [Message];
        
        init(messages : [Message]) {
            self._messages = messages;
        }
        
        func getMessages() -> [Message] {
            return self._messages;
        }
    }
    
    typealias Callback = (History, MagistralException?) -> Void

}
