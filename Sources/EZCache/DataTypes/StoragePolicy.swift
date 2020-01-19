//
//  OverwritePolicy.swift
//  Cache
//
//  Created by Michael Green on 30/12/2019.
//  Copyright © 2019 Michael Green. All rights reserved.
//

import Foundation

public enum StoragePolicy {
  
  /// Allows a network call to be made even if stored or cached data is retrieved
  case refresh
  
  /// Skips network request if stored or cached data is retrieved
  case allowStale
}
