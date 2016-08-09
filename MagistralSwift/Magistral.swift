//
//  magistral.swift
//  ios
//
//  Created by rizarse on 22/07/16.
//  Copyright © 2016 magistral.io. All rights reserved.
//

import Foundation

import CocoaMQTT
import SwiftyJSON

public class Magistral : IMagistral {
    
    private var pubKey : String, subKey : String, secretKey : String, cipher : String?;
    private var ssl : Bool?;
    
    private var host : String = "app.magistral.io";
    
    private var mqtt : MqttClient?;
    
    private var settings : [String : [[String : String]]] = [ : ];
    
    convenience init(pubKey : String, subKey : String, secretKey : String) {
        self.init(pubKey : pubKey, subKey : subKey, secretKey : secretKey, ssl : false, cipher : "");
    }
    
    convenience init(pubKey : String, subKey : String, secretKey : String, ssl : Bool) {
        self.init(pubKey : pubKey, subKey : subKey, secretKey : secretKey, ssl : ssl, cipher : "");
    }
    
    convenience init(pubKey : String, subKey : String, secretKey : String, cipher : String) {
        self.init(pubKey : pubKey, subKey : subKey, secretKey : secretKey, ssl : false, cipher : cipher);
    }
    
    public func setHost(host : String) {
        self.host = host;
    }
    
    public func setCipher(cipher: String) {
        self.cipher = cipher;
    }
    
    public required init(pubKey : String, subKey : String, secretKey : String, ssl : Bool, cipher : String) {
        
        self.pubKey = pubKey;
        self.subKey = subKey;
        self.secretKey = secretKey;
        
        if (cipher != "") { self.cipher = cipher; }
        self.ssl = ssl;
        
        self.connectionPoints({ token, settings in
            self.settings = settings;
            self.initMqtt(token);
        });
    }
    
    private func bytes2long(bytes: [UInt8]) -> UInt64 {
        var value : UInt64 = 0
        let data = NSData(bytes: bytes, length: 8)
        data.getBytes(&value, length: 8)
        value = UInt64(bigEndian: value)
        return value;
    }
    
    
    private func initMqtt(token : String) {
        
        mqtt = MqttClient(clientId: "magistral.mqtt.gw." + token, host: self.host, port: 8883);
        
        mqtt?.username = self.pubKey + "|" + self.subKey;
        mqtt?.password = self.secretKey
        
        mqtt?.secureMQTT = true;
        mqtt?.keepAlive = 30
        mqtt?.delegate = mqtt;

        mqtt?.willMessage = CocoaMQTTWill(topic: "presence/" + self.pubKey + "/" + token, message: "\u{0000}");
        
        mqtt?.addMessageListener({ ref, message, msg_id in
            
            let str = message.topic;
            
            let index = self.bytes2long(message.payload);
            
            print("index = " + String(index)) // 14
            
            let tch = str.substringFromIndex(str.startIndex.advancedBy(41));
            
            let needle: Character = "/"
            if let idx = tch.characters.indexOf(needle) {
                let pos = tch.startIndex.distanceTo(idx)
                let unhtopic = tch.substringToIndex(str.startIndex.advancedBy(pos));
                
                let topic = unhtopic.stringByReplacingOccurrencesOfString("-", withString: ".")
                let sch = tch.substringFromIndex(tch.startIndex.advancedBy(pos + 1))
                
                if let myNumber = NSNumberFormatter().numberFromString(sch) {
                    let ch = myNumber.integerValue
                    
                    if let groupListeners = self.lstMap[topic] {
                        for (group, listener) in groupListeners {
                            
                            let baseURL = "https://" + self.host + "/api/magistral/data/read"
                            
                            let user = self.pubKey + "|" + self.subKey;
                           
                            var params = [String : AnyObject]()
                            params["group"] = group;
                            params["topic"] = topic;
                            params["channel"] = ch;
                            
                            params["index"] = String(index);
                            
                            RestApiManager.sharedInstance.makeHTTPGetRequest(baseURL, parameters: params, user: user, password : self.secretKey, onCompletion: { json, err in
                                do {
                                    let messages = try JsonConverter.sharedInstance.handleMessageEvent(json);
                                    for m in messages {
                                        listener(m, nil)
                                    }
                                } catch {
                                    let eve = Message(topic: "null", channel: 0, msg: [], index: 0, timestamp: 0)
                                    listener(eve, MagistralException.ConversionError)
                                }
                            })
                        }
                    }
                }
            }            
            
        })
        
        mqtt?.addConnectionListener { (ref, connected, host, por, err) in
            if (connected) {
                self.mqtt?.subscribe("exceptions");
                self.mqtt?.publish(CocoaMQTTMessage(topic: "presence/" + self.pubKey + "/" + token, payload: [ 1 ], qos: CocoaMQTTQOS.QOS2, retained: true, dup: false));
            }
        }
       
        mqtt?.connect();
    }
    
    private func connectionPoints(callback : (token : String, settings : [ String : [[String : String]] ]) -> Void) {
        
        let baseURL = "https://" + self.host + "/api/magistral/net/connectionPoints"
        
        let user = self.pubKey + "|" + self.subKey;
        
        RestApiManager.sharedInstance.makeHTTPGetRequest(baseURL, parameters: [:], user: user, password : self.secretKey, onCompletion: { json, err in
            let cps : (String, [ String : [[String : String]] ]) = JsonConverter.sharedInstance.connectionPoints(json);
            callback(token: cps.0, settings: cps.1)
        })
    }
    
//  PUBLISH
    
    public func publish(topic : String, msg : [UInt8], callback : io.magistral.client.pub.Callback?) throws {
        try self.publish(topic, channel: -1, msg: msg, callback: callback);
    }
    
    public func publish(topic : String, channel : Int, msg : [UInt8], callback : io.magistral.client.pub.Callback?) throws {
        mqtt?.publish(topic, channel: channel, msg: msg, callback: callback!)
    }

//  SUBSCRIBE
    
    private var lstMap : [ String : [String : io.magistral.client.sub.NetworkListener]] = [ : ];
    
    public func subscribe(topic : String, listener : io.magistral.client.sub.NetworkListener, callback : io.magistral.client.sub.Callback?) throws {
        try self.subscribe(topic, group : "default", channel : -1, listener : listener, callback: callback);
    }
    
    public func subscribe(topic : String, channel : Int, listener : io.magistral.client.sub.NetworkListener, callback : io.magistral.client.sub.Callback?) throws {
         try self.subscribe(topic, group : "default", channel : channel, listener : listener, callback: callback);
    }
    
    public func subscribe(topic : String, group : String, listener : io.magistral.client.sub.NetworkListener, callback : io.magistral.client.sub.Callback?) throws {
        try self.subscribe(topic, group : group, channel : -1, listener : listener, callback: callback);
    }
    
    public func subscribe(topic : String, group : String, channel : Int, listener : io.magistral.client.sub.NetworkListener, callback : io.magistral.client.sub.Callback?) throws {

        let ch = (channel < -1) ? -1 : channel;
        
        self.mqtt?.subscribe(topic, channel: ch, group: group, qos: CocoaMQTTQOS.QOS1, callback : { meta, err in
            callback?(meta, err)
        })
        
        if let listenerGroups = self.lstMap[topic] {
            if listenerGroups[group] == nil {
                self.lstMap[topic]![group] = listener;
            }
        } else {
            self.lstMap[topic] = [ group : listener ]
        }
    }
    
    public func unsubscribe(topic : String, callback : io.magistral.client.sub.Callback?) throws {
        self.mqtt?.unsubscribe(topic, callback: { meta, err in
            callback?(io.magistral.client.sub.SubMeta(topic: meta.topic(), channel: meta.channel(), group: meta.group(), endPoints: meta.endPoints()), err);
        })
    }
    
    public func unsubscribe(topic : String, channel : Int, callback : io.magistral.client.sub.Callback?) throws {
        self.mqtt?.unsubscribe(topic, callback: { meta, err in
            callback?(io.magistral.client.sub.SubMeta(topic: meta.topic(), channel: meta.channel(), group: meta.group(), endPoints: meta.endPoints()), err);
        })
    }
    
//  TOPICS
    
    public func topics(callback : io.magistral.client.topics.Callback) throws {
        _ = try permissions({ perms, err in
            var topics : [io.magistral.client.topics.TopicMeta] = []
            
            for p in perms {
                topics.append(io.magistral.client.topics.TopicMeta(topic: p.topic(), channels: p.channels()))
            }
            
            callback(topics, err == nil ? nil : MagistralException.FetchTopicsError);
        });
    }
    
    public func topic(topic : String, callback : io.magistral.client.topics.Callback) throws {
        _ = try permissions(topic, callback: { perms, err in
            var topics : [io.magistral.client.topics.TopicMeta] = [];
            
            for p in perms {
                topics.append(io.magistral.client.topics.TopicMeta(topic: p.topic(), channels: p.channels()))
            }
            
            callback(topics, err == nil ? nil : MagistralException.FetchTopicsError);
        });
    }
    
    // ACCESS CONTROL
    
    public func permissions(callback : io.magistral.client.perm.Callback) throws {
        let baseURL = "https://" + self.host + "/api/magistral/net/permissions"
        
        let user = self.pubKey + "|" + self.subKey;
        
        RestApiManager.sharedInstance.makeHTTPGetRequest(baseURL, parameters: [:], user: user, password : self.secretKey, onCompletion: { json, err in
            do {
                let permissions : [io.magistral.client.perm.PermMeta] = try JsonConverter.sharedInstance.handle(json);
                callback(permissions, err == nil ? nil : MagistralException.HistoryInvocationError);
            } catch MagistralException.HistoryInvocationError {
                
            } catch {
                
            }
        })
    }
    
    public func permissions(topic: String, callback : io.magistral.client.perm.Callback) throws {
        let baseURL = "https://" + self.host + "/api/magistral/net/permissions"
        
        var params = [String : AnyObject]()
        params["topic"] = topic;
        
        let user = self.pubKey + "|" + self.subKey;
        
        RestApiManager.sharedInstance.makeHTTPGetRequest(baseURL, parameters: params, user: user, password : self.secretKey, onCompletion: { json, err in
            do {
                let permissions : [io.magistral.client.perm.PermMeta] = try JsonConverter.sharedInstance.handle(json);
                callback(permissions, err == nil ? nil : MagistralException.PermissionFetchError);
            } catch {
            
            }
        })
    }
    
    // PERMISSIONS - GRANT
    
    public func grant(user: String, topic: String, read: Bool, write: Bool, callback : io.magistral.client.perm.Callback?) throws {
        try self.grant(user, topic: topic, channel: -1, read: read, write: write, ttl: -1, callback: callback);
    }
    
    public func grant(user: String, topic: String, read: Bool, write: Bool, ttl: Int, callback : io.magistral.client.perm.Callback?) throws {
        try self.grant(user, topic: topic, channel: -1, read: read, write: write, ttl: ttl, callback: callback);
    }
    
    public func grant(user: String, topic: String, channel: Int, read: Bool, write: Bool, callback : io.magistral.client.perm.Callback?) throws {
        try self.grant(user, topic: topic, channel: channel, read: read, write: write, ttl: -1, callback: callback);
    }
    
    public func grant(user: String, topic: String, channel: Int, read: Bool, write: Bool, ttl: Int, callback : io.magistral.client.perm.Callback?) throws {
        
        let baseURL = "https://" + self.host + "/api/magistral/net/grant"
        
        var params = [String : AnyObject]()
        params["user"] = user;
        params["topic"] = topic;
        
        if (channel > -1) {
            params["channel"] = channel;
        }
        
        params["read"] = String(read);
        params["write"] = String(write);
        
        if (ttl > -1) {
            params["ttl"] = ttl;
        }
        
        let auth = self.pubKey + "|" + self.subKey;
        
        RestApiManager.sharedInstance.makeHTTPPutRequestText(baseURL, parameters: params, user: auth, password : self.secretKey, onCompletion: { text, err in
            if (callback != nil && err == nil) {
                
                let baseURL = "https://" + self.host + "/api/magistral/net/user_permissions"
                
                RestApiManager.sharedInstance.makeHTTPGetRequest(baseURL, parameters: [ "userName" : user], user: auth, password : self.secretKey, onCompletion: { json, err in
                    do {
                        let permissions : [io.magistral.client.perm.PermMeta] = try JsonConverter.sharedInstance.handle(json);
                        callback?(permissions, err == nil ? nil : MagistralException.PermissionFetchError);
                    } catch {
                    }
                })
            }
        })
    }
    
    // PERMISSIONS - REVOKE
    
    public func revoke(user: String, topic: String, callback : io.magistral.client.perm.Callback?) throws {
        try revoke(user, topic: topic, channel: -1, callback: callback);
    }

    public func revoke(user: String, topic: String, channel: Int, callback : io.magistral.client.perm.Callback?) throws {
        let baseURL = "https://" + self.host + "/api/magistral/net/revoke"
        
        var params = [String : AnyObject]()
        params["user"] = user;
        params["topic"] = topic;
        
        if (channel > -1) {
            params["channel"] = channel;
        }
        
        let auth = self.pubKey + "|" + self.subKey;
        
        RestApiManager.sharedInstance.makeHTTPDeleteRequestText(baseURL, parameters: params, user: auth, password: self.secretKey) { text, err in
            if (callback != nil && err == nil) {
                
                let baseURL = "https://" + self.host + "/api/magistral/net/user_permissions"
                
                RestApiManager.sharedInstance.makeHTTPGetRequest(baseURL, parameters: [ "userName" : user], user: auth, password : self.secretKey, onCompletion: { json, err in
                    do {
                        let permissions : [io.magistral.client.perm.PermMeta] = try JsonConverter.sharedInstance.handle(json);
                        callback?(permissions, err == nil ? nil : MagistralException.PermissionFetchError);
                    } catch {
                    }
                })
            }
        }
    }
    
    // HISTORY
    
    public func history(topic: String, channel: Int, count: Int, callback : io.magistral.client.data.Callback) throws {
        try self.history(topic, channel: channel, start: 0, count: count, callback: callback)
    }
    
    public func history(topic: String, channel: Int, start: UInt64, count: Int, callback : io.magistral.client.data.Callback) throws {
        let baseURL = "https://" + self.host + "/api/magistral/data/history"
        
        var params = [String : AnyObject]()
        
        params["topic"] = topic;
        params["channel"] = channel;
        params["count"] = count;
        
        if (start > 0) {
            params["start"] = NSNumber(unsignedLongLong: start)
        }
        
        let user = self.pubKey + "|" + self.subKey;
        
        RestApiManager.sharedInstance.makeHTTPGetRequest(baseURL, parameters: params, user: user, password : self.secretKey, onCompletion: { json, err in
            do {
                let history : io.magistral.client.data.History = try JsonConverter.sharedInstance.handle(json);
                callback(history, err == nil ? nil : MagistralException.HistoryInvocationError);
            } catch MagistralException.HistoryInvocationError {
                let history = io.magistral.client.data.History(messages: [Message]());
                callback(history, MagistralException.HistoryInvocationError)
            } catch {
                
            }
        })
    }
    
    public func history(topic: String, channel: Int, start: UInt64, end: UInt64, callback : io.magistral.client.data.Callback) throws {
        let baseURL = "https://" + self.host + "/api/magistral/data/historyForPeriod"
        
        var params = [String : AnyObject]()
        
        params["topic"] = topic;
        params["channel"] = channel;
        
        params["start"] = NSNumber(unsignedLongLong: start)
        params["end"] = NSNumber(unsignedLongLong: end)
        
        let user = self.pubKey + "|" + self.subKey;
        
        RestApiManager.sharedInstance.makeHTTPGetRequest(baseURL, parameters: params, user: user, password : self.secretKey, onCompletion: { json, err in
            do {
                let history : io.magistral.client.data.History = try JsonConverter.sharedInstance.handle(json);
                callback(history, err == nil ? nil : MagistralException.HistoryInvocationError);
            } catch MagistralException.HistoryInvocationError {
                let history = io.magistral.client.data.History(messages: [Message]());
                callback(history, MagistralException.HistoryInvocationError)
            } catch {
                
            }
        })
    }
    
    public func close() {        
        mqtt?.disconnect();
    }
}