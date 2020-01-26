//
//  Cache.swift
//  EZCache
//
//  Created by Michael Green on 27/12/2019.
//  Copyright © 2019 Michael Green. All rights reserved.
//

import Foundation

public final class Cache<Key: PersistantHashable, Value: Cacheable> {
  
  typealias FileURL = (url: URL, error: Error?)
  typealias StorageCompletionHandler = (_ result: Result<[FileURL], Error>) -> Void
  typealias LoadingCompletionHandler = (_ result: Result<Value, Error>) -> Void
  
  let dispatchQueue = DispatchQueue(label: "com.chackle.EZCache", qos: .background)
  
  private let cache = NSCache<CacheKey, CachedValue>()
  private let providedDate: () -> Date
  private let valueLifetime: TimeInterval
  let keyTracker = KeyTracker()
  var cacheDirectory: URL { FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first! }
  
  init(providedDate: @escaping () -> Date = Date.init,
       valueLifetime: TimeInterval = 12 * 60 * 60, maximumNumberOfEntries: Int = 128) {
    self.providedDate = providedDate
    self.valueLifetime = valueLifetime
    self.cache.countLimit = maximumNumberOfEntries
    self.cache.delegate = self.keyTracker
  }
  
  func store(_ value: Value, forKey key: Key) {
    let date = self.providedDate().addingTimeInterval(self.valueLifetime)
    let cachedValue = CachedValue(associatedKey: key, value: value, expirationDate: date)
    self.store(cachedValue)
  }
  
  func store(_ value: CachedValue) {
    self.cache.setObject(value, forKey: CacheKey(value.associatedKey))
    self.keyTracker.keys.insert(value.associatedKey)
  }
  
  func value(forKey key: Key) -> Value? {
    self.value(forKey: key)?.value
  }
  
  func removeValue(forKey key: Key) {
    self.cache.removeObject(forKey: CacheKey(key))
  }
  
  func removeAllValues() {
    self.cache.removeAllObjects()
  }
}

private extension Cache {
  
  func value(forKey key: Key) -> CachedValue? {
    guard let value = self.cache.object(forKey: CacheKey(key)) else { return nil }
    guard self.providedDate() < value.expirationDate else {
      self.removeValue(forKey: key)
      return nil
    }
    return value
  }
}

extension Cache {
  subscript(key: Key) -> Value? {
    get { self.value(forKey: key) }
    set {
      guard let value = newValue else { return self.removeValue(forKey: key) }
      self.store(value, forKey: key)
    }
  }
}

extension Cache {
  final class KeyTracker: NSObject, NSCacheDelegate {
    var keys = Set<Key>()
    
    func cache(_ cache: NSCache<AnyObject, AnyObject>,
               willEvictObject object: Any) {
      guard let value = object as? CachedValue else { return }
      print("Evicting object: \(value)")
      self.keys.remove(value.associatedKey)
    }
  }
}

extension Cache {
  final class CacheKey: NSObject {
    let key: Key
    
    init(_ key: Key) {
      self.key = key
    }
    
    override var hash: Int {
      self.key.hashValue
    }
    
    override func isEqual(_ object: Any?) -> Bool {
      guard let object = object as? CacheKey else { return false }
      return object.key == key
    }
  }
}

extension Cache {
  final class CachedValue {
    let associatedKey: Key
    let value: Value
    let expirationDate: Date
    
    init(associatedKey: Key, value: Value, expirationDate: Date) {
      self.associatedKey = associatedKey
      self.value = value
      self.expirationDate = expirationDate
    }
  }
}

extension Cache {
  
  func writeToDisk(withCompletionHandler handler: @escaping StorageCompletionHandler) {
    self.dispatchQueue.async {
      var urls = [FileURL]()
      for key in self.keyTracker.keys {
        guard let persistantHash = key.persistantHash else { return handler(.failure(CachingError.persistantHashNotFound)) }
        let folderURL = self.cacheDirectory.appendingPathComponent(Value.subdirectoryName)
        let fileURL = folderURL.appendingPathComponent(String(persistantHash) + Value.fileExtension)
        do {
          guard let data = try self.value(forKey: key)?.toData() else { return handler(.failure(CachingError.encodingFailed)) }
          try FileManager.default.createDirectory(atPath: folderURL.path, withIntermediateDirectories: true, attributes: nil)
          try data.write(to: fileURL)
          urls.append(FileURL(url: fileURL, error: nil))
        } catch {
          urls.append(FileURL(url: fileURL, error: error))
        }
      }
      DispatchQueue.main.async {
        handler(.success(urls))
      }
    }
  }
  
  func loadFromDisk(withKey key: Key, withCompletionHandler handler: @escaping LoadingCompletionHandler) {
    guard let persistantHash = key.persistantHash else { return handler(.failure(CachingError.persistantHashNotFound)) }
    self.dispatchQueue.async {
      let dataPathComponent = Value.subdirectoryName + "/" + String(persistantHash)
      let dataPath = self.cacheDirectory.appendingPathComponent(dataPathComponent + Value.fileExtension)
      do {
        let data = try Data(contentsOf: dataPath)
        let cacheable = try Value.decode(from: data)
        self.store(cacheable, forKey: key)
        DispatchQueue.main.async {
          // TODO: Pulling this out and unwrapping using a guard causes ambiguous reference error
          return handler(.success(self.value(forKey: key)!))
        }
      } catch { return handler(.failure(error)) }
    }
  }
}
