//
//  MqttClient.swift
//  MagistralSwift
//
//  Created by rizarse on 05/08/16.
//  Copyright © 2016 magistral.io. All rights reserved.
//

import Foundation
import CocoaMQTT

class MqttClient : CocoaMQTT, CocoaMQTTDelegate {
    
    typealias MessageListener = (CocoaMQTT, CocoaMQTTMessage, UInt16) -> Void
    
    typealias ConnectionListener = (CocoaMQTT, Bool, String, Int?, NSError?) -> Void
    typealias ConnectionAckListener = (CocoaMQTT, CocoaMQTTConnAck) -> Void
    typealias SubscriptionListener = (CocoaMQTT, Bool, String) -> Void
    
    typealias PublishListener = (CocoaMQTT, CocoaMQTTMessage, UInt16) -> Void
    typealias PublishAckListener = (CocoaMQTT, UInt16) -> Void
    
    var msgListeners : [MessageListener] = [];
    var conListeners : [ConnectionListener] = [];
    var conAckListeners : [ConnectionAckListener] = [];
    var subListeners : [SubscriptionListener] = [];
    
    var pubListeners : [PublishListener] = [];
    var pubAckListeners : [PublishAckListener] = [];
    
    func addConnectionListener(listener : ConnectionListener) {
        conListeners.append(listener);
    }
    
    private func addConnectionAckListener(listener : ConnectionAckListener) {
        conAckListeners.append(listener);
    }
    
    private func addSubscriptionListener(listener : SubscriptionListener) {
        subListeners.append(listener);
    }
    
    func addMessageListener(listener : MessageListener) {
        msgListeners.append(listener);
    }
    
    private func addPublishListener(listener : PublishListener) {
        pubListeners.append(listener);
    }
    func addPublishAckListener(listener : PublishAckListener) {
        pubAckListeners.append(listener);
    }
    
//  DELETE LISTENERS
    
    func removeConnectionListeners() {
        conListeners.removeAll();
    }
    func removeConnectionAckListeners() {
        conAckListeners.removeAll();
    }
    func removeSubscriptionListeners() {
        subListeners.removeAll();
    }
    func removeMessageListeners() {
        msgListeners.removeAll();
    }
    func removePublishListeners() {
        pubListeners.removeAll();
    }
    func removePublishAckListeners() {
        pubAckListeners.removeAll();
    }
    
//  Overrides
    
    func connect(token : String, pubKey : String, callback : (Bool, String, Int, MagistralException?) -> Void) {
        addConnectionListener { ref, status, host, port, err in
            callback(status, host, port!, err != nil ? MagistralException.MqttConnectionError : nil)
            
            self.subscribe("exceptions");
            self.publish(CocoaMQTTMessage(topic: "presence/" + pubKey + "/" + token, payload: [ 1 ], qos: CocoaMQTTQOS.QOS2, retained: true, dup: false));
        }
    }
    
    var _pubCallbacks : [UInt16 : (io.magistral.client.pub.Callback, String, Int)] = [:]
    func publish(topic : String, channel : Int, msg : [UInt8], callback : io.magistral.client.pub.Callback) -> UInt16 {
        
        let id = super.publish(CocoaMQTTMessage(topic: topic + ":" + String(channel), payload: msg, qos: CocoaMQTTQOS.QOS1, retained: false, dup: false));
        self._pubCallbacks[id] = (callback, topic, channel);
        return id;
    }
    
    func subscribe(topic : String, channel: Int, group : String, qos: CocoaMQTTQOS, callback : io.magistral.client.sub.Callback) {
        super.subscribe(topic + ":" + String(channel), qos: qos);
        
        addSubscriptionListener { (ref, status, topic) in
            if (status) {
                callback(io.magistral.client.sub.SubMeta(topic: topic, channel: channel, group: group, endPoints: []), nil)
                self.removeSubscriptionListeners();
            }
        };        
        
    }
    
    func unsubscribe(topic : String, callback : io.magistral.client.sub.Callback) {
        super.unsubscribe(topic)
        
        addSubscriptionListener { ref, status, topic in
            if (status == false) {
                callback(io.magistral.client.sub.SubMeta(topic: topic, channel: -1, group: "", endPoints: []), nil)
                self.removeSubscriptionListeners();
            }
        };
    }
    
    func unsubscribe(topic : String, channel: Int?, callback : io.magistral.client.sub.Callback) {
        super.unsubscribe(topic + "/" + String(channel))
        
        addSubscriptionListener { ref, status, topic in
            if (status == false) {
                callback(io.magistral.client.sub.SubMeta(topic: topic, channel: channel!, group: "", endPoints: []), nil)
                self.removeSubscriptionListeners();
            }
        };
    }
    
//  CocoaMQTTDelegate stuff
    
    func mqtt(mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        
        for l in conListeners {
            l(mqtt, true, host, port, nil);
        }
    }
    func mqtt(mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        for l in conAckListeners {
            l(mqtt, ack)
        }
    }
    
    var pubacks : [UInt16] = [];
    func mqtt(mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        pubacks.append(id);
    }
    
    func mqtt(mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        if let tuple = _pubCallbacks[id] {
            tuple.0(io.magistral.client.pub.PubMeta(topic: tuple.1, channel: tuple.2), nil)
            _pubCallbacks.removeValueForKey(id);
        }
    }
    
    func mqtt(mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        for l in msgListeners {
            l(mqtt, message, id)
        }
    }
    
    func mqtt(mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        for l in subListeners {
            l(mqtt, true, topic)
        }
    }
    
    func mqtt(mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        for l in subListeners {
            l(mqtt, false, topic)
        }
    }
    
    func mqttDidDisconnect(mqtt: CocoaMQTT, withError err: NSError?) {
        for l in conListeners {
            l(mqtt, false, host, nil, err)
        }
    }
    
    func mqttDidPing(mqtt: CocoaMQTT) {
    
    }
    
    func mqttDidReceivePong(mqtt: CocoaMQTT) {
       
    }
}