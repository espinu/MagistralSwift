//
//  RestApiManager.swift
//  ios
//
//  Created by rizarse on 01/08/16.
//  Copyright © 2016 magistral.io. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

typealias ServiceResponse = (JSON, NSError?) -> Void
typealias ServiceResponseText = (String, NSError?) -> Void

public struct MagistralEncoding : ParameterEncoding {
    
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        let res = try URLEncoding.queryString.encode(urlRequest, with: parameters).url?.absoluteString.replacingOccurrences(of: "%5B%5D=", with: "=");
        return URLRequest(url: URL(string: res!)!);
    }
    
}

open class RestApiManager: NSObject {
    
    enum ResponseType {
        case json
        case text
    }
    
    let queue = DispatchQueue(label: "io.magistral.response-queue", qos: .utility, attributes: [.concurrent])
    static let sharedInstance = RestApiManager()
    
    
    
    func makeHTTPGetRequest(path: String, parameters : Parameters, user : String, password : String, onCompletion: @escaping ServiceResponse) {
//        debugPrint(
        Alamofire
            .request(path, method: .get, parameters: parameters, encoding: MagistralEncoding.init())
            .authenticate(user: user, password: password)
            .validate(statusCode: 200..<300)
            .validate()
            .responseJSON (queue: queue) { response in
                
                guard response.result.isSuccess else {
                    print("REST CALL ERROR: \(response.result.error)")
                    onCompletion(JSON.null, response.result.error as NSError?)
                    return
                }
                
                DispatchQueue.main.async {
                    let json: JSON = JSON(data: response.data!);
                    onCompletion(json, nil);
                }
        }
//        )
        
    }
    
    func makeHTTPGetRequestText(_ path: String, parameters : Parameters, user : String, password : String, onCompletion: @escaping ServiceResponseText) {
        Alamofire
            .request(path, method: .get, parameters: parameters)
            .authenticate(user: user, password: password)
            .validate(statusCode: 200..<300)
            .validate()
            .responseString { response in
                switch response.result {
                    case .success:
                        onCompletion(response.result.value! , nil)
                    case .failure(let error):
                        onCompletion("", error as NSError?)
                }
            }
    }
    
    func makeHTTPPutRequest(_ path: String, parameters : Parameters, user : String, password : String, onCompletion: @escaping ServiceResponse) {
        Alamofire
            .request(path, method: .put, parameters: parameters, encoding: URLEncoding.default)
            .authenticate(user: user, password: password)
            .validate(statusCode: 200..<300)
            .responseString { response in
                switch response.result {
                    case .success:
                        let json: JSON = JSON(data: response.data!);
                        onCompletion(json , nil)
                    case .failure(let error):
                        onCompletion("", error as NSError?)
                }
        }
    }
    
    func makeHTTPDeleteRequestText(_ path: String, parameters : Parameters, user : String, password : String, onCompletion: @escaping ServiceResponseText) {
        Alamofire
            .request(path, method: .delete, parameters: parameters, encoding: URLEncoding.default)
            .authenticate(user: user, password: password)
            .validate(statusCode: 200..<300)
            .responseString { response in
                switch response.result {
                    case .success:
                        onCompletion(response.result.value! , nil)
                    case .failure(let error):
                        onCompletion("", error as NSError?)
                }
        }
    }
    
    func makeHTTPPutRequestText(_ path: String, parameters : Parameters, user : String, password : String, onCompletion: @escaping ServiceResponseText) {
        Alamofire
            .request(path, method: .put, parameters: parameters, encoding: URLEncoding.default)
            .authenticate(user: user, password: password)
            .validate(statusCode: 200..<300)
            .responseString { response in
                switch response.result {
                case .success:
                    onCompletion(response.result.value! , nil)
                case .failure(let error):
                    onCompletion("", error as NSError?)
            }
        }
    }
    
    // MARK: Perform a POST Request
    func makeHTTPPostRequest(_ path: String, body: Parameters, onCompletion: @escaping ServiceResponse) {
        
        Alamofire.request(path, method: .post, parameters: body, encoding: JSONEncoding.default)
            .responseString { response in
                switch response.result {
                case .success:
                    let json: JSON = JSON(data: response.data!);
                    onCompletion(json , nil)
                case .failure(let error):
                    onCompletion("", error as NSError?)
                }
            }
    }
}
