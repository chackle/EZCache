//
//  CacheableImage.swift
//  EZCache
//
//  Created by Michael Green on 30/12/2019.
//  Copyright © 2019 Michael Green. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public struct CacheableImage {
  
  public let rawValue: UIImage
  
  public init(_ image: UIImage) {
    self.rawValue = image
  }
}

extension CacheableImage: Cacheable {
  
  public static var subdirectoryName: String { "images" }
  public static var fileExtension: String { ".png" }
  public static var storagePolicy: StoragePolicy { .allowStale }
  
  public static func decode(from data: Data) throws -> CacheableImage {
    guard let image = UIImage(data: data) else { throw CachingError.decodingFailed }
    return CacheableImage(image)
  }
  
  public func toData() throws -> Data? {
    self.rawValue.pngData()
  }
}
#endif
