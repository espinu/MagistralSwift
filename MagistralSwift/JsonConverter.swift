//
//  SwiftConverter.swift
//  ios
//
//  Created by rizarse on 02/08/16.
//  Copyright © 2016 magistral.io. All rights reserved.
//

import Foundation
import SwiftyJSON

public class JsonConverter {
    
    static let sharedInstance = JsonConverter();
    
    func handle(json : JSON) throws -> io.magistral.client.data.History {
        
        var history : io.magistral.client.data.History;
        
        if let messages = json["message"].array {
            
            let dumb = Message(topic: "", channel: 0, msg: [UInt8](), index: 0, timestamp: 0)
            
            let count = messages.count;
            var msgL = [Message](repeating: dumb, count : count);
            
            for i in 0 ... (count - 1) {
                msgL[i] = convert2msg(json: messages[i]);
            }
            
            history = io.magistral.client.data.History(messages: msgL);
        } else if (json["message"]["topic"].string != nil) {            
            history = io.magistral.client.data.History(messages: [ convert2msg(json: json["message"]) ]);
        } else {
            throw MagistralException.historyInvocationError
        }        
        return history;
    }
    
    private func handlePerm(perm : JSON) -> io.magistral.client.perm.PermMeta {
        let topic = perm["topic"].stringValue
        
        let read = perm["index"].boolValue
        let write = perm["timestamp"].boolValue
        
        var pdic = [Int : (Bool, Bool)]();
        if let channels = perm["channels"].array {
            for ch in 0 ... (channels.count - 1) {
                pdic[ch] = (read, write);
            }
        }
        
        return io.magistral.client.perm.PermMeta(topic: topic, perms: pdic);
    }
    
    func handle(json : JSON) throws -> [io.magistral.client.perm.PermMeta] {
        
        var ps : [io.magistral.client.perm.PermMeta] = []

        if let perms = json["permission"].array {
            let count = perms.count;
            
            for i in 0 ... (count - 1) {
                ps.append(handlePerm(perm: perms[i]));
            }
            
        } else if (json["permission"]["topic"].string != nil) {
            ps.append(handlePerm(perm: json["permission"]))
        }
        
        return ps;
    }
    
    private func convert2msg(json : JSON) -> Message {
        let sb = json["body"].stringValue
        let t = json["topic"].stringValue
        let c = json["channel"].intValue
        let index = json["index"].uInt64Value
        let ts = json["timestamp"].uInt64Value
        
        let nsdata = NSData(base64Encoded: sb, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters)!
        var bytes : [UInt8] = [UInt8](repeating: 0, count: nsdata.length)
        
        nsdata.getBytes(&bytes, length: nsdata.length)
        
        return Message(topic: t, channel: c, msg: bytes, index: index, timestamp: ts)
    }
    
    func handleMessageEvent(json : JSON) throws -> [Message] {
        var messages : [Message] = [];
        
        print(json)
        
        if let msgs = json["message"].array {
            let count = msgs.count;
            
            for i in 0 ... (count - 1) {
                messages.append(convert2msg(json: msgs[i]));
            }
        } else if (json["message"]["topic"].string != nil) {
            messages.append(convert2msg(json: json["message"]));
        }
        
        return messages;
    }
    
    func connectionPoints(json : JSON) -> (String, [ String : [[String : String]] ]) {
        var config : [ String : [[String : String]] ] = [ : ];
        
        let token : String = json[0]["token"].stringValue;
        
        let metaMap = [ "token" : token ];
        
        var pubCnf = [String : String]()
        var subCnf = [String : String]()
        
        if (json.array != nil) {}
        if (json.array != nil) {}
        
//        print(json);
        
        if (json.array != nil) {
            print("token = " + json[0]["token"].stringValue)
            
            if (json[0]["consumer"]).boolValue { subCnf["bootstrap.servers"] = json[0]["consumer"].stringValue }
            if (json[0]["producer"]).boolValue { pubCnf["bootstrap.servers"] = json[0]["producer"].stringValue }
            
            if (json[0]["consumer-ssl"]).boolValue { subCnf["bootstrap.servers.ssl"] = json[0]["consumer-ssl"].stringValue }
            if (json[0]["producer-ssl"]).boolValue { pubCnf["bootstrap.servers.ssl"] = json[0]["producer-ssl"].stringValue }
        }
        
        config["pub"]  = [pubCnf];
        config["sub"]  = [subCnf];
        config["meta"] = [metaMap];
        
        return (token, config);
    }
    
}
