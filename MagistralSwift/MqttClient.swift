//
//  MqttClient.swift
//  MagistralSwift
//
//  Created by rizarse on 05/08/16.
//  Copyright © 2016 magistral.io. All rights reserved.
//

import Foundation
import SwiftMQTT

class MqttClient : MQTTSession, MQTTSessionDelegate {
    
    typealias MessageListener = (MQTTSession, Message) -> Void
    
    var msgListeners : [MessageListener] = [];
    func addMessageListener(_ listener : @escaping MessageListener) {
        msgListeners.append(listener);
    }
    
//  DELETE LISTENERS

    func removeMessageListeners() {
        msgListeners.removeAll();
    }
    
//  Overrides
    
    var disconnectListener : MQTTDisconnectBlock?;
    var socketErrorListener : MQTTSocketErrorBlock?;
    
    public typealias MQTTDisconnectBlock = (SwiftMQTT.MQTTSession) -> Swift.Void
    public typealias MQTTSocketErrorBlock = (SwiftMQTT.MQTTSession) -> Swift.Void
    
    func connect(completion: MQTTSessionCompletionBlock?, disconnect: MQTTDisconnectBlock?, socketerr: MQTTSocketErrorBlock?) {
        super.connect { connected, error in
            completion?(connected, error);
        }
        disconnectListener = disconnect;
        socketErrorListener = socketerr;
    }
    
    func publish(_ topic : String, channel : Int, msg : [UInt8], callback : io.magistral.client.pub.Callback?) {
        publish(Data(msg), in: topic + ":" + String(channel), delivering: .atLeastOnce, retain: false) { published, error in
            callback?(io.magistral.client.pub.PubMeta(topic: topic, channel: channel), published ? nil : MagistralException.publishError)
        }
    }
    
    func subscribe(_ topic : String, channel: Int, group : String, qos: MQTTQoS, callback : io.magistral.client.sub.Callback?) {
        super.subscribe(to: topic + ":" + String(channel), delivering: qos) { succeeded, error -> Void in
            callback?(io.magistral.client.sub.SubMeta(topic: topic, channel: channel, group: group, endPoints: []), succeeded ? nil : MagistralException.subscriptionError)
        }
    }
    
    func unsubscribe(_ topic : String, callback : io.magistral.client.sub.Callback?) {
        super.unSubscribe(from: topic) { succeeded, error -> Void in
            callback?(io.magistral.client.sub.SubMeta(topic: topic, channel: -1, group: "", endPoints: []), succeeded ? nil : MagistralException.unsubscriptionError)
        }
    }
    
    func unsubscribe(_ topic : String, channel: Int, callback : io.magistral.client.sub.Callback?) {
        super.unSubscribe(from: topic + ":" + String(channel)) { succeeded, error -> Void in
            callback?(io.magistral.client.sub.SubMeta(topic: topic, channel: -1, group: "", endPoints: []), succeeded ? nil : MagistralException.unsubscriptionError)
        }
    }
    
    private func getCurrentMillis() -> Int64 {
        return Int64(UInt64(Date().timeIntervalSince1970 * 1000))
    }
    
    func mqttDidReceive(message data: Data, in topic: String, from session: SwiftMQTT.MQTTSession) {
        for l in msgListeners {
            
            let bytes = [UInt8](data);
            
            let str = topic;
            let index = self.bytes2long(bytes: bytes);
            
            let tch = str.substring(from: str.index(str.startIndex, offsetBy: 41));
            
            var elements = tch.components(separatedBy: "/")
            
            if let myNumber = NumberFormatter().number(from: elements.popLast()!) {
                let ch = myNumber.intValue
                let merged = elements.joined(separator: "/");
                
                let t = merged.components(separatedBy: "-").joined(separator: ".");
                
                l(session, Message(topic: t, channel: ch, msg: bytes, index: index, timestamp: UInt64(self.getCurrentMillis())))
            }

        }
    }
    
    private func bytes2long(bytes: [UInt8]) -> UInt64 {
        var value : UInt64 = 0
        let data = NSData(bytes: bytes, length: 8)
        data.getBytes(&value, length: 8)
        value = UInt64(bigEndian: value)
        return value;
    }
    
    func mqttDidDisconnect(session: SwiftMQTT.MQTTSession) {
        disconnectListener?(session)
    }
    
    func mqttSocketErrorOccurred(session: SwiftMQTT.MQTTSession) {
        socketErrorListener?(session)
    }
}
