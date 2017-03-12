//
//  ApiAIService.swift
//  SpeechPlayground
//
//  Created by Martin Mitrevski on 12/03/17.
//  Copyright © 2017 Martin Mitrevski. All rights reserved.
//

import UIKit
import ApiAI

public typealias SuccesfullApiAIResponseBlock = (ApiAIResponse?) -> Swift.Void
public typealias FailureApiAIResponseBlock = (Error?) -> Swift.Void

class ApiAIService: NSObject {
    static let resultKey = "result"
    static let parametersKey = "parameters"
    static let addProductKey = "AddProduct"
    static let removeProductKey = "RemoveProduct"
    static let errorCode = 777
    static let errorDomain = "com.mitrevski.invalidjson"
    static let clientAccessToken = "YOUR_API_AI_KEY"
    
    private var apiAI = ApiAI()
    static let sharedInstance = ApiAIService()
    
    override init() {
        super.init()
        setupApiAI()
    }
    
    func extractProducts(fromText text: String,
                         success: SuccesfullApiAIResponseBlock!,
                         failure: FailureApiAIResponseBlock!) {
        let request = self.apiAI.textRequest()
        request?.query = text
        request?.setCompletionBlockSuccess({ [unowned self] (request, response) in
            if let response = response as? Dictionary<String, Any> {
                success(self.extractProducts(fromResponse: response))
            } else {
                let error = NSError(domain:ApiAIService.errorDomain,
                                    code:ApiAIService.errorCode,
                                    userInfo:nil)
                failure(error)
            }
        }, failure: { (request, error) in
            failure(error)
        })
        self.apiAI.enqueue(request)
    }
    
    private func setupApiAI() {
        let configuration = AIDefaultConfiguration()
        configuration.clientAccessToken = ApiAIService.clientAccessToken
        self.apiAI.configuration = configuration
    }
    
    private func extractProducts(fromResponse response: Dictionary<String, Any>) -> ApiAIResponse? {
        var toBeAdded = [String]()
        var toBeRemoved = [String]()
        
        guard let result = response[ApiAIService.resultKey] as? Dictionary<String, Any> else {
            return nil
        }
        
        guard let parameters = result[ApiAIService.parametersKey] as? Dictionary<String, Any> else {
            return nil
        }
        
        if let addProducts = parameters[ApiAIService.addProductKey] as? Array<String> {
            toBeAdded = addProducts
        }
        
        if let removeProducts = parameters[ApiAIService.removeProductKey] as? Array<String> {
            toBeRemoved = removeProducts
        }
        
        return ApiAIResponse(addedProducts: toBeAdded, removedProducts: toBeRemoved)
    }
}
