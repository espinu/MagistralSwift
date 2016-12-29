//
//  exceptions.swift
//  ios
//
//  Created by rizarse on 01/08/16.
//  Copyright © 2016 magistral.io. All rights reserved.
//

import Foundation

public enum MagistralException: Error {
    
    case `default`(msg: String)
    case none
    
    case mqttConnectionError
    
    case conversionError
    
    case publishError
    case subscriptionError
    case unsubscriptionError
   
    case indexFetchError
    case historyInvocationError
    case fetchTopicsError
    
    case topicNotFound
    case invalidChannelNumber
    case channelOutOfBound
    
    case noPermissionsError
    
    case permissionFetchError
    case permissionGrantError
    case permissionRevokationError
    
    case invalidPubKey
    case invalidSubKey
    case invalidSecretKey
}
