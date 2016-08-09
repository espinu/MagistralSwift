//
//  RestApiManager.swift
//  ios
//
//  Created by rizarse on 01/08/16.
//  Copyright © 2016 magistral.io. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

typealias ServiceResponse = (JSON, NSError?) -> Void
typealias ServiceResponseText = (String, NSError?) -> Void

public class RestApiManager: NSObject {
    
    enum ResponseType {
        case JSON
        case TEXT
    }
    
    static let sharedInstance = RestApiManager()
    
    func makeHTTPGetRequest(path: String, parameters : [String : AnyObject]?, user : String, password : String, onCompletion: ServiceResponse) {
        Alamofire
            .request(.GET, path, parameters: parameters)
            .authenticate(user: user, password: password)
            .validate(statusCode: 200..<300)
            .validate()
            .responseJSON { response in
                guard response.result.isSuccess else {
                    print("REST CALL ERROR: \(response.result.error)")
                    onCompletion(nil, response.result.error)
                    return
                }
                
                let json: JSON = JSON(data: response.data!);
                onCompletion(json, nil);
        }
    }
    
    func makeHTTPGetRequestText(path: String, parameters : [String : AnyObject]?, user : String, password : String, onCompletion: ServiceResponseText) {
        
        Alamofire
            .request(.GET, path, parameters: parameters)
            .authenticate(user: user, password: password)
            .validate(statusCode: 200..<300)
            .validate()
            .responseString { response in
                
            }
    }
    
    func makeHTTPPutRequest(path: String, parameters : [String : AnyObject]?, user : String, password : String, onCompletion: ServiceResponse) {
        let URL = NSURL(string: path)
        var request = NSMutableURLRequest(URL: URL!)
        
        let encoding = Alamofire.ParameterEncoding.URL
        (request, _) = encoding.encode(request, parameters: parameters)
        
        Alamofire
            .request(.PUT, (request.URL?.absoluteString)!)
            .authenticate(user: user, password: password)
            .validate(statusCode: 200..<300)
            .responseJSON {
                response in
                guard response.result.isSuccess else {
                    print("REST CALL ERROR: \(response.result.error)")
                    onCompletion(nil, response.result.error)
                    return
                }
                
                let json: JSON = JSON(data: response.data!);
                onCompletion(json, nil);
        }
    }
    
    func makeHTTPDeleteRequestText(path: String, parameters : [String : AnyObject]?, user : String, password : String, onCompletion: ServiceResponseText) {
        let URL = NSURL(string: path)
        var request = NSMutableURLRequest(URL: URL!)
        
        let encoding = Alamofire.ParameterEncoding.URL
        (request, _) = encoding.encode(request, parameters: parameters)
        
        Alamofire
            .request(.DELETE, (request.URL?.absoluteString)!)
            .authenticate(user: user, password: password)
            .validate(statusCode: 200..<300)
            .responseString { response in
                switch response.result {
                    case .Success:
                        onCompletion(response.result.value! , nil)
                    case .Failure(let error):
                        onCompletion("", error)
                }
        }
    }
    
    func makeHTTPPutRequestText(path: String, parameters : [String : AnyObject]?, user : String, password : String, onCompletion: ServiceResponseText) {
        
        let URL = NSURL(string: path)
        var request = NSMutableURLRequest(URL: URL!)
       
        let encoding = Alamofire.ParameterEncoding.URL
        (request, _) = encoding.encode(request, parameters: parameters)
        
        Alamofire
            .request(.PUT, (request.URL?.absoluteString)!)
            .authenticate(user: user, password: password)
            .validate(statusCode: 200..<300)
            
            .responseString { response in
                
                switch response.result {
                case .Success:
                    onCompletion(response.result.value!, nil)
                case .Failure(let error):
                    onCompletion("", error)
                }
            }
    }
    
    // MARK: Perform a POST Request
    func makeHTTPPostRequest(path: String, body: [String: AnyObject], onCompletion: ServiceResponse) {
        let request = NSMutableURLRequest(URL: NSURL(string: path)!)
        
        // Set the method to POST
        request.HTTPMethod = "POST"
        
        do {
            // Set the POST body for the request
            let jsonBody = try NSJSONSerialization.dataWithJSONObject(body, options: .PrettyPrinted)
            request.HTTPBody = jsonBody
            let session = NSURLSession.sharedSession()
            
            let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
                if let jsonData = data {
                    let json:JSON = JSON(data: jsonData)
                    onCompletion(json, nil)
                } else {
                    onCompletion(nil, error)
                }
            })
            task.resume()
        } catch {
            // Create your personal error
            onCompletion(nil, nil)
        }
    }
}