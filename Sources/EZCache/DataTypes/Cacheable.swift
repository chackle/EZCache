//
//  Cacheable.swift
//  EZCache
//
//  Created by Michael Green on 30/12/2019.
//  Copyright © 2019 Michael Green. All rights reserved.
//

import Foundation

public protocol Cacheable {
  static var subdirectoryName: String { get }
  static var fileExtension: String { get }
  static var storagePolicy: StoragePolicy { get }
  static func decode(from data: Data) throws -> Self
  func toData() throws -> Data?
}

public extension Cacheable {
  static var subdirectoryName: String { return String(describing: Self.self) }
  static var fileExtension: String { return "" }
  static var storagePolicy: StoragePolicy { return .refresh }
}

public extension Cacheable where Self: Codable {
  
  static func decode(from data: Data) throws -> Self {
    return try JSONDecoder().decode(Self.self, from: data)
  }
  
  func toData() throws -> Data? {
    return try JSONEncoder().encode(self)
  }
}

extension Array: Cacheable where Element: Cacheable & Codable {
  
  public static var subdirectoryName: String {
    if "\(Self.self)" == "Array<\(Element.subdirectoryName)>" { return "\(Self.self)" }
    return Element.subdirectoryName
  }
  public static var fileExtension: String { return Element.fileExtension }
  public static var storagePolicy: StoragePolicy { return Element.storagePolicy }
  
  public static func decode(from data: Data) throws -> Array<Element> {
    return try JSONDecoder().decode(Self.self, from: data)
  }
  
  public func toData() throws -> Data? {
    return try JSONEncoder().encode(self)
  }
}
