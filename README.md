# 📦 EZCache
<p>
    <img src="https://img.shields.io/badge/Swift-5.1-orange.svg" />
    <a href="https://swift.org/package-manager">
        <img src="https://img.shields.io/badge/swiftpm-compatible-brightgreen.svg?style=flat" alt="Swift Package Manager" />
    </a>
</p>

A lightweight caching and data retrieval library for iOS which aims to be as non-intrusive as possible. To see example usage of EZCache check out the [sample project repository](https://github.com/chackle/EZCache).

## 🎯 Project aim

The original aim of the project was to understand when and where to use generics in software engineering. Swift, being a language that favors strongly typed software patterns, was perfect for this. Further understanding was achieved through the implementation of generic protocols with associated types and inferred generic typing with multiple layers of abstraction for different types of caching.

## ⚙️ Usage

Implement `Cacheable` on the `struct` or  `class` you want to cache. If your object conforms to `Codable` it's really simple to get started.
``` swift
extension YourData: Cacheable { }
```

Instantiate a `DataFetcher` on an object that won't be deallocated during use such as a `UIViewController` or a view model layer. If the `DataFetcher` or its parent is deallocated the underlying `Cache` will be invalidated and emptied.
``` swift
let dataFetcher = DataFetcher<YourData>()
```

Provide a `URL` with some data that conforms to your data type whether it be image data or JSON. If this operation has previously been successful for the specified `URL` during the lifecycle of the `DataFetcher` then it will retrieve it from the cache. If the `DataFetcher` is new or the app was terminated then it will attempt to retrieve it from local storage instead.
``` swift 
self.dataFetcher.fetch(from: URL("http://www.myurl.com/data")!) { (result) in
  switch result {
    case .success(let yourData):
      // Do something with your data
      break
    case .failure(let error):
      break
  }
}

```
...and that's pretty much it! There are a few other things you can customise and fine tune using `Cacheable` which you'll need to do if you want to decode more elaborate data such as an image, PDF or another file format. Here's an example of a more precise implementation of `Cacheable` from the `CacheableImage` struct:
``` swift
extension CacheableImage: Cacheable {
  
  public static var subdirectoryName: String { "images" }
  public static var fileExtension: String { ".png" }
  public static var storagePolicy: StoragePolicy { .allowStale }
  
  public static func decode(from data: Data) throws -> CacheableImage {
    guard let image = UIImage(data: data) else { throw CachingError.decodingFailed }
    CacheableImage(image)
  }
  
  public func toData() throws -> Data? {
    self.rawValue.pngData()
  }
}
```

## 🔨 TODOs

- [x] Provide real error handling
- [x] Introduce `StoragePolicy` to allow state data refreshing or ignorance
- [x] Streamline `Cacheable` implementation by providing default values and functions
- [x] Change any remaining synchronous calls into asynchronous or provide both
- [ ] Allow `DataFetcher` to be constructed with a passed `Cache` instance, but set default if none provided
- [ ] Introduce `UIImageView` helper or subclass for making network calls even simpler
- [ ] Provide useful comments
- [ ] Add some basic tests for error throwing
