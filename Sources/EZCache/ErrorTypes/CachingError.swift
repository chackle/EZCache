//
//  CachingError.swift
//  EZCache
//
//  Created by Michael Green on 03/01/2020.
//  Copyright © 2019 Michael Green. All rights reserved.
//

import Foundation

enum CachingError: Error {
  
  case persistantHashNotFound
  case encodingFailed
  case decodingFailed
}
