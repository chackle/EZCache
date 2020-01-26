//
//  DataFetcher.swift
//  EZCache
//
//  Created by Michael Green on 21/12/2019.
//  Copyright © 2019 Michael Green. All rights reserved.
//

import Foundation

public protocol DataFetcherProtocol {
  
  typealias CompletionHandler = ((_ result: Result<V, Error>) -> Void)
  
  associatedtype K: PersistantHashable
  associatedtype V: Cacheable
  
  func fetchFromCache(usingKey key: K) -> V?
  func fetchFromLocalStorage(usingKey key: K, withCompletionHandler handler: @escaping CompletionHandler)
  func fetchFromNetwork(usingURL url: URL, withCompletionHandler handler: @escaping CompletionHandler)
}

public final class DataFetcher<V: Cacheable>: DataFetcherProtocol {
  
  public typealias K = URL
  public typealias V = V
  
  let cache = Cache<K, V>()
  let webService = WebService<V>()
  
  public init() { }
  
  public func fetch(from url: URL, withCompletionHandler handler: @escaping CompletionHandler) {
    if let data = self.fetchFromCache(usingKey: url) {
      handler(.success(data))
      if case .allowStale = V.storagePolicy {
        print("[Cache] Allow Stale for '\(V.self)'")
        return
      }
    }
    
    self.fetchFromLocalStorage(usingKey: url) { (result) in
      if case .allowStale = V.storagePolicy, case .success(_) = result {
        print("[Local] Allow Stale + Success for '\(V.self)'")
        return handler(result)
      }
      print("[Network] Refresh OR Failure for '\(V.self)'")
      self.fetchFromNetwork(usingURL: url, withCompletionHandler: handler)
    }
  }
  
  // MARK: Data Retrieval
  public func fetchFromCache(usingKey key: K) -> V? {
    return self.cache[key]
  }
  
  public func fetchFromLocalStorage(usingKey key: K, withCompletionHandler handler: @escaping CompletionHandler) {
    self.cache.loadFromDisk(withKey: key) { (result) in
      if case let .success(data) = result {
        self.cache[key] = data
      }
      handler(result)
    }
  }
  
  public func fetchFromNetwork(usingURL url: URL, withCompletionHandler handler: @escaping CompletionHandler) {
    self.webService.fetchData(fromURL: url) { (result) in
      if case let .success(data) = result {
        self.cache[url] = data
        // TODO: Should singular errors be handled within a batch write?
        self.cache.writeToDisk { (_) in }
        handler(result)
      }
    }
  }
}

extension DataFetcher {
  public subscript(key: K) -> V? {
    get { return self.cache[key] }
  }
}
