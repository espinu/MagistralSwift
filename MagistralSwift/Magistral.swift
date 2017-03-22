    //
//  magistral.swift
//  ios
//
//  Created by rizarse on 22/07/16.
//  Copyright © 2016 magistral.io. All rights reserved.
//

import Foundation

import SwiftMQTT
import SwiftyJSON
import Alamofire

public class Magistral : IMagistral {
    
    private var pubKey : String, subKey : String, secretKey : String, cipher : String?;
    private var ssl : Bool?;
    
    private var active = false;
    
    private var host : String = "app.magistral.io";
    
    private var mqtt : MqttClient?;
    
    private var subscription : [String : [String : [Int]]] = [ : ];

    private var init_indexes : [String : [String : [Int : UInt64]]]  = [ : ];
    private var settings : [String : [[String : String]]] = [ : ];
    
    public typealias Connected = (Bool, Magistral) -> Void
    
    convenience init(pubKey : String, subKey : String, secretKey : String, connected : Connected?) {
        self.init(pubKey : pubKey, subKey : subKey, secretKey : secretKey, cipher : "", connected : connected);
    }
    
    private var commitTimer: Timer!
    
    public func setHost(host : String) {
        self.host = host;
    }
    
    public func setCipher(cipher: String) {
        self.cipher = cipher;
    }
    
    public required init(pubKey : String, subKey : String, secretKey : String, cipher : String, connected : Connected? ) {
        
        self.pubKey = pubKey;
        self.subKey = subKey;
        self.secretKey = secretKey;
        
        if (cipher != "") { self.cipher = cipher; }
        
        self.connectionPoints(callback: { [weak self] token, settings in
            self?.settings = settings;
            
            self?.initMqtt(token: token, connected: { status, magistral in
                connected?(status, magistral);
            })
        });
        
        self.commitTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(commitOffsets), userInfo: nil, repeats: true)
    }
    
    private var shift : [String : [String : [String : String]]] = [ : ];
    @objc private func commitOffsets() {        
        if self.shift.isEmpty { return }
        
        for (group, offsets) in self.shift {
            var parameters: Parameters = [ : ]
            parameters["group"] = group;
            parameters["offsets"] = offsets;
            commit(parameters: parameters);
        }
        
        self.shift.removeAll();
    }
    
    private func commit(parameters : Parameters) {
        let baseURL = "https://" + self.host + "/api/magistral/data/commit"
        RestApiManager.sharedInstance.makeHTTPPostRequest(baseURL, body: parameters, onCompletion: { _,_ in })
    }
    
    public func index(_ topic: String, channel: Int, group: String, callback: @escaping io.magistral.client.data.index.Callback) throws {
        
        let baseURL = "https://" + self.host + "/api/magistral/data/index"
        
        var params : Parameters = [ : ]
        params["topic"] = topic;
        params["channel"] = channel;
        params["group"] = group;
        
        let user = self.pubKey + "|" + self.subKey;
        
        RestApiManager.sharedInstance.makeHTTPGetRequest(path: baseURL, parameters: params, user: user, password : self.secretKey, onCompletion: { json, err in
            do {
                let index : io.magistral.client.data.index.TopicChannelIndex = try JsonConverter.sharedInstance.handleIndexes(group : group, json: json);
                callback(index, err == nil ? nil : MagistralException.indexFetchError);
            } catch {
                let eve = io.magistral.client.data.index.TopicChannelIndex(topic: topic, channel: channel, group: group, index: 0)
                callback(eve, MagistralException.indexFetchError)
            }
        })
    }
    
    private func read(_ topic : String, group : String, channels : [Int], listener : @escaping io.magistral.client.sub.NetworkListener, callback: @escaping () -> Void) {
        let baseURL = "https://" + self.host + "/api/magistral/data/read"
        
        let user = self.pubKey + "|" + self.subKey;
        
        let params: Parameters = [
            "group": group,
            "topic": topic,
            "channel": channels
        ]
        
        RestApiManager.sharedInstance.makeHTTPGetRequest(path: baseURL, parameters: params, user: user, password : self.secretKey, onCompletion: { [weak self] json, err in
            do {
                var messages = try JsonConverter.sharedInstance.handleMessageEvent(json: json);
                
                for m in messages {
                    if let grinxs = self?.init_indexes[group] {
                        
                        if let chixs = grinxs[m.topic()] {
                            if let ixs = chixs[m.channel()] {
                                if m.index() > ixs {
                                    self?.triggerGroupListener(group: group, listener: listener, message: m);
                                    self?.init_indexes[group]?[m.topic()]?[m.channel()] = m.index()
                                }
                            } else {
                                self?.triggerGroupListener(group: group, listener: listener, message: m);
                                self?.init_indexes[group]?[m.topic()]?[m.channel()] = m.index()
                            }
                        } else {
                            self?.triggerGroupListener(group: group, listener: listener, message: m);
                            self?.init_indexes[group]?[m.topic()] = [ : ]
                            self?.init_indexes[group]?[m.topic()]?[m.channel()] = m.index()
                        }
                        
                    } else {
                        self?.init_indexes[group] = [ : ]
                        self?.init_indexes[group]?[m.topic()] = [ : ]
                        self?.init_indexes[group]?[m.topic()]?[m.channel()] = m.index()
                    }
                }
                messages.removeAll();
                
                callback();
            } catch {
                let eve = Message(topic: "null", channel: 0, msg: [], index: 0, timestamp: 0)
                listener(eve, MagistralException.conversionError)
                callback();
            }
        })
    }
    
    private func notifyListeners(topic: String, channel : Int, messages : [Message]) {
        
        if let groupListeners = self.lstMap[topic] {
            for (group, listener) in groupListeners {
                
                for m in messages {
                    
                    if let _ = self.shift[group] {
                        if let _ = self.shift[group]?[m.topic()] {
                            self.shift[group]?[m.topic()]?[String(m.channel())] = String(m.index())
                        } else {
                            self.shift[group]?[m.topic()] = [ : ]
                            self.shift[group]?[m.topic()]?[String(m.channel())] = String(m.index())
                        }
                    } else {
                        self.shift[group] = [ : ]
                        self.shift[group]?[m.topic()] = [ : ]
                        self.shift[group]?[m.topic()]?[String(m.channel())] = String(m.index())
                    }
                    
                    if let grinxs = self.init_indexes[group] {
                        
                        if let chixs = grinxs[m.topic()] {
                            if let ixs = chixs[m.channel()] {
                                if m.index() > ixs {
                                    self.triggerGroupListener(group: group, listener: listener, message: m);
                                    self.init_indexes[group]?[m.topic()]?[m.channel()] = m.index()
                                }
                            } else {
                                self.triggerGroupListener(group: group, listener: listener, message: m);
                                self.init_indexes[group]?[m.topic()]?[m.channel()] = m.index()
                            }
                        } else {
                            self.triggerGroupListener(group: group, listener: listener, message: m);
                            self.init_indexes[group]?[m.topic()] = [ : ]
                            self.init_indexes[group]?[m.topic()]?[m.channel()] = m.index()
                        }
                        
                    } else {
                        self.init_indexes[group] = [ : ]
                        self.init_indexes[group]?[m.topic()] = [ : ]
                        self.init_indexes[group]?[m.topic()]?[m.channel()] = m.index()
                    }
                }
            }
        }
    }
    
    private func triggerGroupListener(group : String, listener : io.magistral.client.sub.NetworkListener, message : Message) {        
        if let groupSub = self.subscription[group] {
            if let topicSub = groupSub[message.topic()] {
                if topicSub.contains(message.channel()) {                    
                    listener(message, nil)
                }
            }
        }
    }
    
    private func handleMqttMessage(m : Message) {
        
        let msg = String(bytes: m.body(), encoding: String.Encoding.utf8);
        
        if let dataFromString = msg?.data(using: .utf8, allowLossyConversion: true) {
            
            if JsonConverter.sharedInstance.isValidJSON(data: dataFromString) {
                
                let json = JSON(data: dataFromString)
                let messages = JsonConverter.sharedInstance.mqtt2msg(t: m.topic(), c: m.channel(), ts : m.timestamp(), json: json);
                
                notifyListeners(topic: m.topic(), channel: m.channel(), messages: messages)
            }
        }
    }
    
    private func initMqtt(token : String, connected : Connected?) {
        
        mqtt = MqttClient(host: self.host, port: 8883, clientID: "magistral.mqtt.gw." + token, cleanSession: true, keepAlive: 30, useSSL: true)
        
        mqtt?.username = self.pubKey + "|" + self.subKey;
        mqtt?.password = self.secretKey
        
        mqtt?.lastWillMessage = MQTTPubMsg(topic: "presence/" + self.pubKey + "/" + token, payload: Data(bytes: [0]), retain: true, QoS: MQTTQoS.atLeastOnce);
        mqtt?.delegate = mqtt;
        
        mqtt?.addMessageListener({ [weak self] ref, message in
            self?.handleMqttMessage(m: message);
        });
        
        mqtt?.connect(completion: { [weak self] mqtt_connected, error in
            self?.handleMqttConnection(succeed: mqtt_connected, error: error,token : token, connected : connected)
        }, disconnect: { [weak self] session in
            self?.handleMqttDisconnect(session: session, token: token, connected: connected)
        }, socketerr: { [weak self] session in
            self?.handleMqttSocketError()
        })
        
    }
    
    private func handleMqttDisconnect(session: SwiftMQTT.MQTTSession, token : String, connected : Connected?) {
        if (self.active) {
            print("Connection dropped -> reconnection in 5 sec.")
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
                session.connect(completion: { [weak self] mqtt_connected, error in
                    self?.handleMqttConnection(succeed: mqtt_connected, error: error, token: token, connected: connected)
                });
            }
        }
    }
    
    private func handleMqttSocketError() {
        if (self.active) {
            print("Socket error")
        }
    }
    
    private func handleMqttConnection(succeed: Bool, error: Error, token : String, connected : Connected?) {
        if (succeed) {
            self.mqtt?.subscribe(to: "exceptions", delivering: .atLeastOnce, completion: nil)
            self.mqtt?.publish(Data([1]), in: "presence/" + self.pubKey + "/" + token, delivering: .atLeastOnce, retain: true, completion: nil)
            self.active = true
            
            for (group, topicSubscription) in self.subscription {
                for (t, channelsSubscription) in topicSubscription {
                    if let listenerGroups = self.lstMap[t] {
                        if let groupListener = listenerGroups[group] {
                            self.read(t, group: group, channels: channelsSubscription, listener: groupListener, callback: {});
                        }
                    }
                    
                    for ch in channelsSubscription {
                        self.mqtt?.subscribe(t, channel: ch, group: group, qos: .atLeastOnce, callback : { meta, err in });
                    }
                }
            }
            
            connected!(self.active, self);
        }
    }
    
    private func connectionPoints(callback : @escaping (_ token : String, _ settings : [ String : [[String : String]] ]) -> Void) {
        let baseURL = "https://" + self.host + "/api/magistral/net/connectionPoints"
        
        let user = self.pubKey + "|" + self.subKey;
        
        RestApiManager.sharedInstance.makeHTTPGetRequest(path: baseURL, parameters: [:], user: user, password : self.secretKey, onCompletion: { json, err in
            let cps : (String, [ String : [[String : String]] ]) = JsonConverter.sharedInstance.connectionPoints(json: json);
            callback(cps.0, cps.1)
        })
    }
    
//  PUBLISH
    
    public func publish(_ topic : String, msg : [UInt8], callback : io.magistral.client.pub.Callback?) throws {
        try self.publish(topic, channel: -1, msg: msg, callback: callback);
    }
    
    public func publish(_ topic : String, channel : Int, msg : [UInt8], callback : io.magistral.client.pub.Callback?) throws {
        mqtt?.publish(topic, channel: channel, msg: msg, callback: { ack, error in
            callback?(ack, error);
        })
    }

//  SUBSCRIBE
    
    private var lstMap : [ String : [String : io.magistral.client.sub.NetworkListener]] = [ : ];
    
    public func subscribe(_ topic : String, listener : @escaping io.magistral.client.sub.NetworkListener, callback : io.magistral.client.sub.Callback?) throws {
        try self.subscribe(topic, group : "default", channel : -1, listener : listener, callback: callback);
    }
    
    public func subscribe(_ topic : String, channel : Int, listener : @escaping io.magistral.client.sub.NetworkListener, callback : io.magistral.client.sub.Callback?) throws {
         try self.subscribe(topic, group : "default", channel : channel, listener : listener, callback: callback);
    }
    
    public func subscribe(_ topic : String, group : String, listener : @escaping io.magistral.client.sub.NetworkListener, callback : io.magistral.client.sub.Callback?) throws {
        try self.subscribe(topic, group : group, channel : -1, listener : listener, callback: callback);
    }
    
    public func subscribe(_ topic : String, group : String, channel : Int, listener : @escaping io.magistral.client.sub.NetworkListener, callback : io.magistral.client.sub.Callback?) throws {
        
        let subMeta : io.magistral.client.sub.SubMeta = io.magistral.client.sub.SubMeta(topic: topic, channel: channel, group: group, endPoints: []);

        let ch = (channel < -1) ? -1 : channel;
        
        try self.topics { [weak self] smeta, error in
            
            if error != nil {
                callback?(subMeta, error);
            }
            
            for meta in smeta {
                
                if topic != meta.topic() { continue; }
                
                if channel == -1 && meta.channels().count == 0 {
                    callback?(subMeta, MagistralException.noPermissionsError);
                    return;
                } else if channel >= 0 && !meta.channels().contains(channel) {
                    callback?(subMeta, MagistralException.noPermissionsError);
                    return;
                } else {
                    
                    var allChannels : [Int] = []
                    for _ch in meta.channels() {
                        allChannels.append(_ch)
                    }
                    
                    if let groupSub = self?.subscription[group] {
                        if let topicSub = groupSub[topic] {
                            if ch == -1 {
                                for tch in allChannels {
                                    if topicSub.contains(tch) {
                                        callback?(subMeta, MagistralException.groupAlreadySubscribedOnChannel)
                                        return;
                                    }
                                }
                            } else {
                                if topicSub.contains(channel) {
                                    callback?(subMeta, MagistralException.groupAlreadySubscribedOnChannel)
                                    return;
                                }
                            }
                        }
                    }
                    
                    let chs = (ch == -1) ? allChannels : [ch]
                    
                    self?.mqtt?.subscribe(topic, channel: ch, group: group, qos: .atLeastOnce, callback : { meta, err in
                        if err == nil {
                            if let groupSub = self?.subscription[group] {
                                if let _ = groupSub[topic] {} else {
                                    self?.subscription[group]?[topic] = []
                                }
                                for ch in chs {
                                    self?.subscription[group]?[topic]?.append(ch)
                                }
                            } else {
                                var ts : [String : [Int]] = [ : ]
                                ts[topic] = chs
                                self?.subscription[group] = ts
                            }
                        }
                        
                        self?.read(topic, group: group, channels: chs, listener: listener, callback: {});
                        
                        callback?(meta, err)
                    })
                }
                return;
            }
            
            callback?(subMeta, MagistralException.topicNotFound);
        }
        
        if let listenerGroups = self.lstMap[topic] {
            if listenerGroups[group] == nil {
                self.lstMap[topic]![group] = listener;
            }
        } else {
            self.lstMap[topic] = [ group : listener ]
        }
    }
    
    public func unsubscribe(_ topic : String, callback : io.magistral.client.sub.Callback?) throws {
        let hts = topic.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ".", with: "-");
        
        self.removeSubscription(topic: topic, channel: -1);
        self.mqtt?.unsubscribe(self.subKey + "/" + hts, callback: { meta, err in
            callback?(io.magistral.client.sub.SubMeta(topic: meta.topic(), channel: meta.channel(), group: meta.group(), endPoints: meta.endPoints()), err);
        })
    }
    
    public func unsubscribe(_ topic : String, channel : Int, callback : io.magistral.client.sub.Callback?) throws {
        let hts = self.subKey + "/" + topic.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ".", with: "-");
        
        self.removeSubscription(topic: topic, channel: channel);
        self.mqtt?.unsubscribe(hts, channel: channel, callback: { meta, err in
            callback?(io.magistral.client.sub.SubMeta(topic: meta.topic(), channel: meta.channel(), group: meta.group(), endPoints: meta.endPoints()), err);
        })
    }
    
    private func removeSubscription(topic : String, channel : Int) {
        for (group, topicSubscription) in self.subscription {
            for (t, channelsSubscription) in topicSubscription {
                if (t == topic){
                    if channel >= 0 {
                        if let index = channelsSubscription.index(of: channel) {
                            self.subscription[group]?[topic]?.remove(at: index)
                        }
                    } else {
                        self.subscription[group]?[topic]?.removeAll()
                    }
                }
            }
        }
    }
    
//  TOPICS
    
    public func topics(_ callback : @escaping io.magistral.client.topics.Callback) throws {
        try permissions({ perms, err in
            
            var topics : [io.magistral.client.topics.TopicMeta] = []

            var map : [ String : [Int]] = [ : ]
            
            for p in perms {
                
                if map.keys.contains(p.topic()) {
                    for _ch in p.channels() {
                        map[p.topic()]?.append(_ch)
                    }
                } else {
                    var channels : [Int] = [];
                    for _ch in p.channels() {
                        channels.append(_ch)
                    }
                    map[p.topic()] = channels
                }
            }
            
            for mk in map.keys {
                var chs : Set<Int> = Set<Int>();
                
                for x in map[mk]! {
                    chs.insert(x);
                }
                topics.append(io.magistral.client.topics.TopicMeta(topic: mk, channels: chs))
            }
            
            callback(topics, err == nil ? nil : MagistralException.fetchTopicsError);
        });
    }
    
    public func topic(_ topic : String, callback : @escaping io.magistral.client.topics.Callback) throws {
        try permissions(topic, callback: { perms, err in
            var topics : [io.magistral.client.topics.TopicMeta] = [];
            
            for p in perms {
                topics.append(io.magistral.client.topics.TopicMeta(topic: p.topic(), channels: p.channels()))
            }
            
            callback(topics, err == nil ? nil : MagistralException.fetchTopicsError);
        });
    }
    
    // ACCESS CONTROL
    
    public func permissions(_ callback : @escaping io.magistral.client.perm.Callback) throws {
        let baseURL = "https://" + self.host + "/api/magistral/net/permissions"
        
        let user = self.pubKey + "|" + self.subKey;
        
        RestApiManager.sharedInstance.makeHTTPGetRequest(path: baseURL, parameters: [:], user: user, password : self.secretKey, onCompletion: { json, err in
            do {
                let permissions : [io.magistral.client.perm.PermMeta] = try JsonConverter.sharedInstance.handle(json: json);
                callback(permissions, err == nil ? nil : MagistralException.permissionFetchError);
            } catch MagistralException.historyInvocationError {
                
            } catch {
                
            }
        })
    }
    
    public func permissions(_ topic: String, callback : @escaping io.magistral.client.perm.Callback) throws {
        let baseURL = "https://" + self.host + "/api/magistral/net/permissions"
        
        var params : Parameters = [ : ]
        params["topic"] = topic;
        
        let user = self.pubKey + "|" + self.subKey;
        
        RestApiManager.sharedInstance.makeHTTPGetRequest(path: baseURL, parameters: params, user: user, password : self.secretKey, onCompletion: { json, err in
            do {
                let permissions : [io.magistral.client.perm.PermMeta] = try JsonConverter.sharedInstance.handle(json: json);
                callback(permissions, err == nil ? nil : MagistralException.permissionFetchError);
            } catch {
            
            }
        })
    }
    
    // PERMISSIONS - GRANT
    
    public func grant(_ user: String, topic: String, read: Bool, write: Bool, callback : io.magistral.client.perm.Callback?) throws {
        try self.grant(user, topic: topic, channel: -1, read: read, write: write, ttl: -1, callback: callback);
    }
    
    public func grant(_ user: String, topic: String, read: Bool, write: Bool, ttl: Int, callback : io.magistral.client.perm.Callback?) throws {
        try self.grant(user, topic: topic, channel: -1, read: read, write: write, ttl: ttl, callback: callback);
    }
    
    public func grant(_ user: String, topic: String, channel: Int, read: Bool, write: Bool, callback : io.magistral.client.perm.Callback?) throws {
        try self.grant(user, topic: topic, channel: channel, read: read, write: write, ttl: -1, callback: callback);
    }
    
    public func grant(_ user: String, topic: String, channel: Int, read: Bool, write: Bool, ttl: Int, callback : io.magistral.client.perm.Callback?) throws {
        
        let baseURL = "https://" + self.host + "/api/magistral/net/grant"
        
        var params : Parameters = [ : ]
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
        
        let secretKey = self.secretKey
        let host = self.host
        RestApiManager.sharedInstance.makeHTTPPutRequestText(baseURL, parameters: params, user: auth, password : secretKey, onCompletion: { text, err in
            if (callback != nil && err == nil) {
                
                let baseURL = "https://" + host + "/api/magistral/net/user_permissions"
                
                RestApiManager.sharedInstance.makeHTTPGetRequest(path: baseURL, parameters: [ "userName" : user], user: auth, password : secretKey, onCompletion: { json, err in
                    do {
                        let permissions : [io.magistral.client.perm.PermMeta] = try JsonConverter.sharedInstance.handle(json: json);
                        callback?(permissions, err == nil ? nil : MagistralException.permissionFetchError);
                    } catch {
                    }
                })
            }
        })
    }
    
    // PERMISSIONS - REVOKE
    
    public func revoke(_ user: String, topic: String, callback : io.magistral.client.perm.Callback?) throws {
        try revoke(user, topic: topic, channel: -1, callback: callback);
    }

    public func revoke(_ user: String, topic: String, channel: Int, callback : io.magistral.client.perm.Callback?) throws {
        let baseURL = "https://" + self.host + "/api/magistral/net/revoke"
        
        var params : Parameters = [ : ]
        params["user"] = user;
        params["topic"] = topic;
        
        if (channel > -1) {
            params["channel"] = channel;
        }
        
        let auth = self.pubKey + "|" + self.subKey;
        let host = self.host
        let secretKey = self.secretKey
        RestApiManager.sharedInstance.makeHTTPDeleteRequestText(baseURL, parameters: params, user: auth, password: secretKey) { text, err in
            if (callback != nil && err == nil) {
                
                let baseURL = "https://" + host + "/api/magistral/net/user_permissions"
                
                RestApiManager.sharedInstance.makeHTTPGetRequest(path: baseURL, parameters: [ "userName" : user], user: auth, password : secretKey, onCompletion: { json, err in
                    do {
                        let permissions : [io.magistral.client.perm.PermMeta] = try JsonConverter.sharedInstance.handle(json: json);
                        callback?(permissions, err == nil ? nil : MagistralException.permissionFetchError);
                    } catch {
                    }
                })
            }
        }
    }
    
    // HISTORY
    
    public func history(_ topic: String, channel: Int, count: Int, callback : @escaping io.magistral.client.data.Callback) throws {
        try self.history(topic, channel: channel, start: UInt64(0), count: count, callback: callback)
    }
    
    public func history(_ topic: String, channel: Int, startingIndex: Int, count: Int, callback: @escaping io.magistral.client.data.Callback) throws {
        let baseURL = "https://" + self.host + "/api/magistral/data/historyPage"
        
        var params : Parameters = [ : ]
        
        params["topic"] = topic;
        params["channel"] = channel;
        params["startIndex"] = startingIndex;
        params["count"] = count;
        
        let user = self.pubKey + "|" + self.subKey;
        
        RestApiManager.sharedInstance.makeHTTPGetRequest(path: baseURL, parameters: params, user: user, password : self.secretKey, onCompletion: { json, err in
            do {
                let history : io.magistral.client.data.History = try JsonConverter.sharedInstance.handle(json: json);
                callback(history, err == nil ? nil : MagistralException.historyInvocationError);
            } catch MagistralException.historyInvocationError {
                let history = io.magistral.client.data.History(messages: [Message]());
                callback(history, MagistralException.historyInvocationError)
            } catch {
                
            }
        })
    }
    
    public func history(_ topic: String, channel: Int, start: UInt64, count: Int, callback : @escaping io.magistral.client.data.Callback) throws {
        let baseURL = "https://" + self.host + "/api/magistral/data/history"
        
        var params : Parameters = [ : ]
        
        params["topic"] = topic;
        params["channel"] = channel;
        params["count"] = count;
        
        if (start > 0) {
            params["start"] = start
        }
        
        let user = self.pubKey + "|" + self.subKey;
        
        RestApiManager.sharedInstance.makeHTTPGetRequest(path: baseURL, parameters: params, user: user, password : self.secretKey, onCompletion: { json, err in
            do {
                let history : io.magistral.client.data.History = try JsonConverter.sharedInstance.handle(json: json);
                if err == nil {
                    callback(history, nil);
                } else {
                    callback(history, MagistralException.historyInvocationError);
                }
                
            } catch MagistralException.historyInvocationError {
                let history = io.magistral.client.data.History(messages: [Message]());
                callback(history, MagistralException.historyInvocationError)
            } catch {
                
            }
        })
    }
    
    public func history(_ topic: String, channel: Int, start: UInt64, end: UInt64, callback : @escaping io.magistral.client.data.Callback) throws {
        let baseURL = "https://" + self.host + "/api/magistral/data/historyForPeriod"
        
        var params : Parameters = [ : ]
        
        params["topic"] = topic;
        params["channel"] = channel;
        
        params["start"] = start;
        params["end"] = end;
        
        let user = self.pubKey + "|" + self.subKey;
        
        RestApiManager.sharedInstance.makeHTTPGetRequest(path: baseURL, parameters: params, user: user, password : self.secretKey, onCompletion: { json, err in
            do {
                let history : io.magistral.client.data.History = try JsonConverter.sharedInstance.handle(json: json);
                callback(history, err == nil ? nil : MagistralException.historyInvocationError);
            } catch MagistralException.historyInvocationError {
                let history = io.magistral.client.data.History(messages: [Message]());
                callback(history, MagistralException.historyInvocationError)
            } catch {
                
            }
        })
    }
    
    deinit {}
    
    public func close() {
        self.commitOffsets();
        
        self.active = false;
        self.commitTimer.invalidate();
        
        mqtt?.removeMessageListeners();
        mqtt?.disconnect();
        mqtt?.delegate = nil
    }
}
