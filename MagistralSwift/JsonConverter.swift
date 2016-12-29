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
        
        let read = perm["read"].boolValue
        let write = perm["write"].boolValue
        
        var pdic = [Int : (Bool, Bool)]();
        
        if let channels = perm["channels"].array {
            for ch in channels {
                pdic[Int(ch.stringValue)!] = (read, write);
            }
        } else {
            pdic[Int(perm["channels"].stringValue)!] = (read, write);
        }
        
        return io.magistral.client.perm.PermMeta(topic: topic, perms: pdic);
    }
    
    func isValidJSON (data : Data) -> Bool {
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        return json != nil;
    }
    
    func mqtt2msg(t : String, c: Int, ts: UInt64, json : JSON) -> [Message] {
        
        var result : [Message] = []
        
        let messages = json["messages"];
        if json["messages"].exists() == false {
            return result;
        }
        
        for (_, subJson):(String, JSON) in messages {
            
            let offset = UInt64(subJson["offset"].stringValue);
            let b64 = subJson["body"].stringValue;
            
            if let decodedData = NSData(base64Encoded: b64, options: NSData.Base64DecodingOptions(rawValue: 0)) {
                let length = decodedData.length
                var payload = [UInt8](repeating: 0, count: length)
                decodedData.getBytes(&payload, length: length)
                result.append(Message(topic: t, channel: c, msg: payload, index: offset!, timestamp: ts))
            }
        }        
        return result;
    }
    
    func handle(json : JSON) throws -> [io.magistral.client.perm.PermMeta] {
        
        var ps : [io.magistral.client.perm.PermMeta] = []

        if let perms = json["permission"].array {
            
            for perm in perms {
                ps.append(handlePerm(perm: perm));
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
    
    private func convert2index(group: String, json : JSON) -> io.magistral.client.data.index.TopicChannelIndex {
        let t = json["topic"].stringValue
        let c = json["channel"].intValue
        let i = json["index"].uInt64Value
        return io.magistral.client.data.index.TopicChannelIndex(topic: t, channel: c, group: group, index: i)
    }
    
    func handleMessageEvent(json : JSON) throws -> [Message] {
        var messages : [Message] = [];
        
        if json == JSON.null {
            return messages;
        }
        
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
    
    func handleIndexes(group: String, json : JSON) throws -> io.magistral.client.data.index.TopicChannelIndex {
        
        var index : io.magistral.client.data.index.TopicChannelIndex
            = io.magistral.client.data.index.TopicChannelIndex(topic: "", channel: 0, group: group, index: 0);
        
        if json == JSON.null {
            return index;
        }
        
        if let msgs = json["indexes"].array {
            let count = msgs.count;
            
            for _ in 0 ... (count - 1) {
                index = convert2index(group: group, json: json)
                break;
            }
        } else if (json["topic"].string != nil) {
            index = convert2index(group: group, json: json)
        }
        
        return index;
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
