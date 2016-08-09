//
//  perm.swift
//  MagistralSwift
//
//  Created by rizarse on 03/08/16.
//  Copyright © 2016 magistral.io. All rights reserved.
//

import Foundation

public extension io.magistral.client.perm {
    
    public struct PermMeta {
        
        private var _topic: String;
        private var _permissions: [Int : (Bool, Bool)];
        
        init(topic : String, perms : [Int : (Bool, Bool)]) {
            self._topic = topic;
            self._permissions = perms;
        }
        
        func topic() -> String {
            return self._topic;
        }
        
        func channels() -> Set<Int> {
            var chs : Set<Int> = Set<Int>();
            for c in self._permissions.keys {
                chs.insert(c);
            }
            return chs;
        }
        
        func readable(ch : Int) -> Bool {
            if let val = self._permissions[ch] {
                let readable : Bool = val.0;
                return readable;
            } else {
                return false;
            }
        }
        
        func writable(ch : Int) -> Bool {
            if let val = self._permissions[ch] {
                let writable : Bool = val.1;
                return writable;
            } else {
                return false;
            }
        }
    }
    
    typealias Callback = ([io.magistral.client.perm.PermMeta], MagistralException?) -> Void
}