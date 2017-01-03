//
//  NetworkHandler.swift
//  GroupChat
//
//  Created by Soham Bhattacharjee on 03/01/17.
//  Copyright © 2017 IBM. All rights reserved.
//

import Foundation
import UIKit

class NetworkHandler {
    
    class func callAPI(apiURL: URL, _ completionHandler: @escaping(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        // set up the session
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let task = session.dataTask(with: apiURL, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            completionHandler(data, response, error)
        })
        task.resume()
    }
}
