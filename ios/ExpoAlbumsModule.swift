import CoreGraphics
import Photos
import UIKit
import ExpoModulesCore

internal class FileSystemNotFoundException: Exception {
  override var reason: String {
    "FileSystem module not found, make sure 'expo-file-system' is linked correctly"
  }
}

internal class CorruptedImageDataException: Exception {
  override var reason: String {
    "Cannot create image data for given image format"
  }
}

internal enum ImageFormat: String, EnumArgument {
  case jpeg
  case jpg
  case png

  var fileExtension: String {
    switch self {
    case .jpeg, .jpg:
      return ".jpg"
    case .png:
      return ".png"
    }
  }
}

internal class PermissionsModuleNotFoundException: Exception {
  override var reason: String {
    "Permissions module not found. Are you sure that Expo modules are properly linked?"
  }
}

internal class FileSystemModuleNotFoundException: Exception {
  override var reason: String {
    "FileSystem module not found. Are you sure that Expo modules are properly linked?"
  }
}

internal class ImageWriteFailedException: GenericException<String> {
  override var reason: String {
    "Writing image data to the file has failed: \(param)"
  }
}

public class ExpoAlbumsModule: Module {
    typealias LoadImageCallback = (Result<Any, Error>) -> Void
    typealias SaveImageResult = (url: URL, data: Data)

    public func definition() -> ModuleDefinition {

        Name("ExpoAlbums")

        AsyncFunction("mainFunction", mainFunction)
            .runOnQueue(.main)


    }

    internal func mainFunction(promise: Promise) {
        getImages() { result in
            switch result {
                case .failure(let error):
                    return promise.reject(error)
                case .success(let image):
                    do {
                      promise.resolve([
                        "uri": "Hello",
                        "auth": image
                      ])
                    } catch {
                      promise.reject(error)
                    }
                }
            }
    }

    internal func saveImage(image: UIImage) throws -> SaveImageResult {
        guard let fileSystem = self.appContext?.fileSystem else {
          throw FileSystemNotFoundException()
        }
        let directory = URL(fileURLWithPath: fileSystem.cachesDirectory).appendingPathComponent("ImageManipulator")
        let filename = UUID().uuidString.appending(".png")
        let fileUrl = directory.appendingPathComponent(filename)

        fileSystem.ensureDirExists(withPath: directory.path)

        guard let data = imageData(from: image, format: ImageFormat.png, compression: 1) else {
          throw CorruptedImageDataException()
        }

        do {
          try data.write(to: fileUrl, options: .atomic)
        } catch let error {
          throw ImageWriteFailedException(error.localizedDescription)
        }
        return (url: fileUrl, data: data)
    }


    internal func getImages(callback: @escaping LoadImageCallback) {
        PHPhotoLibrary.requestAuthorization { (status: PHAuthorizationStatus) in
            switch status {
                case .authorized:
                    print("Good to proceed")

                    var allFinalImageUrls = []

                    let fetchOptions = PHFetchOptions()
                    let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)

                    guard let firstAsset = assets.firstObject else {
                        return callback(.success("No first asset found"))
                    }

                    let size = CGSize(width: 50, height: 50)
                    let options = PHImageRequestOptions()

                    options.resizeMode = .exact
                    options.isNetworkAccessAllowed = true
                    options.isSynchronous = true
                    options.deliveryMode = .highQualityFormat

                    assets.enumerateObjects({ (object, count, stop) in
                        PHImageManager.default().requestImage(for: object, targetSize: size, contentMode: .aspectFill, options: options) { (image, info) in
                            guard let image = image else {
                                return callback(.success("Image not found"))
                            }

                            /**


                            let contentEditingOptions = PHContentEditingInputRequestOptions()
                            contentEditingOptions.isNetworkAccessAllowed = true

                            image.imageAsset.requestContentEditingInput(with: contentEditingOptions) { input, info in

                                guard let input = input else {
                                    return callback(.success("Got metadata for image"))
                                }

                                return callback(.success("Got metadata for image \(input.fullSizeImageURL)"))

                            }
                            */
                            do {
                                let saveResult = try self.saveImage(image: image)
                                let saveResultUrl = saveResult.url.absoluteString

                                let aspectRatio: Double = Double(object.pixelWidth) / Double(object.pixelHeight)

                                allFinalImageUrls.append([
                                    "aspectRatio": aspectRatio,
                                    "filepath": saveResultUrl
                                ])
                                // allFinalImageUrls.append(saveResultUrl)
                            } catch {
                                callback(.success("Error \(error)"))
                            }
                        }
                    })

                    return callback(.success(allFinalImageUrls))

                case .denied, .restricted:
                    return callback(.success("Not allowed"))
                case .notDetermined:
                    return callback(.success("Not determined yet"))
                default:
                    return callback(.success("Default"))
            }

        }
        /**
            let fetchOptions = PHFetchOptions()
            guard let asset = PHAsset.fetchAssets(with: .image, options: fetchOptions).firstObject else {
                return callback(.failure(ImageNotFoundException()))
            }
            let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            let options = PHImageRequestOptions()

            options.resizeMode = .exact
            options.isNetworkAccessAllowed = true
            options.isSynchronous = true
            options.deliveryMode = .highQualityFormat

            PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: options) { image, _ in
                guard let image = image else {
                    return callback(.failure(ImageNotFoundException()))
                }
                return callback(.success(image))
            }
        */
    }
}


func imageData(from image: UIImage, format: ImageFormat, compression: Double) -> Data? {
  switch format {
  case .jpeg, .jpg:
    return image.jpegData(compressionQuality: compression)
  case .png:
    return image.pngData()
  }
}
