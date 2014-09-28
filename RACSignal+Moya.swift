//
//  RACSignal+Moya.swift
//  Moya
//
//  Created by Ash Furrow on 2014-09-06.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Foundation
import ReactiveCocoa

let MoyaErrorDomain = "Moya"

public enum MoyaErrorCode: Int {
    case ImageMapping = 0
    case JSONMapping
    case StringMapping
    case StatusCode
    case Data
}

/// Extension for processing raw NSData generated by network access.
public extension RACSignal {
    
    /// Filters out responses that don't fall within the given range, generating errors when others are encountered.
    public func filterStatusCodes(range: ClosedInterval<Int>) -> RACSignal {
        return tryMap({ (object, error) -> AnyObject! in
            if let response = object as? MoyaResponse {
                if range.contains(response.statusCode) {
                    return object
                } else {
                    if error != nil {
                        error.memory = NSError(domain: MoyaErrorDomain, code: MoyaErrorCode.StatusCode.toRaw(), userInfo: ["data": object])
                    }
                    
                    return nil
                }
            }
            
            if error != nil {
                error.memory = NSError(domain: MoyaErrorDomain, code: MoyaErrorCode.Data.toRaw(), userInfo: ["data": object])
            }
            
            return nil
        })
    }
    
    public func filterSuccessfulStatusCodes() -> RACSignal {
        return filterStatusCodes(200...299)
    }
    
    /// Maps data received from the signal into a UIImage. If the conversion fails, the signal errors.
    public func mapImage() -> RACSignal {
        return tryMap({ (object, error) -> AnyObject! in
            var image: UIImage?
            if let response = object as? MoyaResponse {
                image = UIImage(data: response.data)
            }
            
            if image == nil && error != nil {
                error.memory = NSError(domain: MoyaErrorDomain, code: MoyaErrorCode.ImageMapping.toRaw(), userInfo: ["data": object])
            }
            
            return image
        })
    }
    
    /// Maps data received from the signal into a JSON object. If the conversion fails, the signal errors.
    public func mapJSON() -> RACSignal {
        return tryMap({ (object, error) -> AnyObject! in
            var json: AnyObject?
            if let response = object as? MoyaResponse {
                json = NSJSONSerialization.JSONObjectWithData(response.data, options: nil, error: error)
            }
            
            if json == nil && error != nil && error.memory == nil {
                var userInfo: [NSObject : AnyObject]?
                if object != nil {
                    userInfo = ["data": object]
                }
                
                error.memory = NSError(domain: MoyaErrorDomain, code: MoyaErrorCode.JSONMapping.toRaw(), userInfo: userInfo)
            }
            
            return json
        })
    }
    
    /// Maps data received from the signal into a String. If the conversion fails, the signal errors.
    public func mapString() -> RACSignal {
        return tryMap({ (object, error) -> AnyObject! in
            var string: String?
            
            if let response = object as? MoyaResponse {
                string = NSString(data: response.data, encoding: NSUTF8StringEncoding)
            }
            
            if string == nil {
                var userInfo: [NSObject : AnyObject]?
                if object != nil {
                    userInfo = ["data": object]
                }
                
                error.memory = NSError(domain: MoyaErrorDomain, code: MoyaErrorCode.StringMapping.toRaw(), userInfo: userInfo)
            }
            
            return string
        })
    }
}
