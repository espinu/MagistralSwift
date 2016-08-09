//
//  exceptions.swift
//  ios
//
//  Created by rizarse on 01/08/16.
//  Copyright © 2016 magistral.io. All rights reserved.
//

import Foundation

public enum MagistralException: ErrorType {
    case Default(msg: String)
    
    case None
    
    case MqttConnectionError
    
    case ConversionError
    
    case HistoryInvocationError
    case FetchTopicsError
    
    case PermissionFetchError
    case PermissionGrantError
    case PermissionRevokationError
    
    case InvalidPubKey
    case InvalidSubKey
    case InvalidSecretKey
}