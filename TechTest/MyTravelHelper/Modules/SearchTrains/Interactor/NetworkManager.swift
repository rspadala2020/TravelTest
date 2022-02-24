//
//  NetworkManager.swift
//  MyTravelHelper
//
//  Created by raja padala on 24/02/2022.
//  Copyright © 2022 Sample. All rights reserved.
//

import UIKit

class NetworkManager: NSObject {
    let session = URLSession.shared
    var presenter: InteractorToPresenterProtocol?
    private var completionHandler: ((_ response: Data?, _ error: Error?) -> Void)?
    
    func makeServiceCallForRequest(urlString: String, presenter: InteractorToPresenterProtocol?, handler: ((_ response: Data?, _ error: Error?) -> Void)? = nil) {
        self.presenter = presenter
        self.completionHandler = handler
        if Reach().isNetworkReachable() == true {
            if let url = URL(string: urlString) {
                let dataTask = session.dataTask(with: url) { (data, response, error) in
                    if error == nil, let responseData = data {
                        if let handler = self.completionHandler {
                            handler(responseData, nil)
                        }
                    } else {
                        if let handler = self.completionHandler {
                            handler(nil, error)
                        }
                    }
                }
                dataTask.resume()
            } else {
                if let handler = self.completionHandler {
                    handler(nil, nil)
                }
            }
        } else {
            if let handler = self.completionHandler {
                handler(nil, nil)
            }
            DispatchQueue.main.async {
                self.presenter?.showNoInterNetAvailabilityMessage()
            }
        }
        
    }
}
