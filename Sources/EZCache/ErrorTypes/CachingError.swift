//
//  File.swift
//  
//
//  Created by Michael Green on 03/01/2020.
//

import Foundation

enum CachingError: Error {
  
  case persistantHashNotFound
  case encodingFailed
  case decodingFailed
}
