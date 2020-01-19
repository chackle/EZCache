//
//  PersistantHashing.swift
//  Cache
//
//  Created by Michael Green on 29/12/2019.
//  Copyright © 2019 Michael Green. All rights reserved.
//

import Foundation

public typealias PersistantHashable = Persistant & Hashable & Codable

public protocol Persistant {
  var persistantHash: Int? { get }
}

extension String: Persistant {
  public var persistantHash: Int? {
    return self.utf8.reduce(5381) { ($0 << 5) &+ $0 &+ Int($1) }
  }
}

extension URL: Persistant {
  public var persistantHash: Int? {
    return self.absoluteString.persistantHash
  }
}
