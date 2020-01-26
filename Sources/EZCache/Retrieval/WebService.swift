//
//  WebService.swift
//  EZCache
//
//  Created by Michael Green on 30/12/2019.
//  Copyright © 2019 Michael Green. All rights reserved.
//

import Foundation

public class WebService<V: Cacheable> {
  
  typealias CompletionHandler = ((_ result: Result<V, Error>) -> Void)

  var session: URLSession {
    URLSession.shared
  }
  
  required init() {
    
  }
  
  func fetchData(fromURL url: URL, withCompletionHandler handler: @escaping CompletionHandler) {
    self.session.dataTask(with: url) { (data, response, error) in
      if let error = error { return handler(.failure(error)) }
      guard let data = data else { return handler(.failure(WebServiceError.emptyDataFound)) }
      do {
        let codable = try V.decode(from: data)
        //let codable = try data.decode() as V
        DispatchQueue.main.async {
          handler(.success(codable))
        }
      } catch {
        handler(.failure(error))
      }
    }.resume()
  }
}
