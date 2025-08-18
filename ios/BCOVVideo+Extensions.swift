//
//  BCOVVideo+Extensions.swift
//  react-native-brightcove
//

import BrightcovePlayerSDK

extension BCOVVideo {
  var videoId: String? {
    return properties[BCOVVideo.PropertyKeyId] as? String
  }

  var referenceId: String? {
    return properties[BCOVVideo.PropertyKeyReferenceId] as? String
  }

  var accountId: String? {
    return properties[BCOVVideo.PropertyKeyAccountId] as? String
  }

  var offlineVideoToken: String? {
    return properties[BCOVOfflineVideo.TokenPropertyKey] as? String
  }

  var name: String? {
    return properties[BCOVVideo.PropertyKeyName] as? String
  }

  var shortDescription: String? {
    return properties[BCOVVideo.PropertyKeyDescription] as? String
  }

  var longDescription: String? {
    return properties[BCOVVideo.PropertyKeyLongDescription] as? String
  }

  var duration: NSNumber? {
    return properties[BCOVVideo.PropertyKeyDuration] as? NSNumber
  }

  var thumbnail: String? {
    //    return properties[BCOVVideo.PropertyKeyThumbnail] as? String
    return properties[BCOVOfflineVideo.ThumbnailFilePathPropertyKey] as? String
  }

  var poster: String? {
    //    return properties[BCOVVideo.PropertyKeyPoster] as? String
    return properties[BCOVOfflineVideo.PosterFilePathPropertyKey] as? String
  }

  var licenseExpirationTime: Double {
    var timestamp = 0.0
    if let expirationTime = properties[BCOVOfflineVideo.LicenseAbsoluteExpirationTimePropertyKey]
      as? NSNumber
    {
      let expirationDate = Date(timeIntervalSinceReferenceDate: expirationTime.doubleValue)
      timestamp = expirationDate.timeIntervalSince1970 * 1000
    }
    return timestamp
  }

  var size: Double {
    var videoSize = 0.0
    if let videoFilePath = properties[BCOVOfflineVideo.FilePathPropertyKey] as? String {
      let usedSpace = getDiskSpace(forFolderPath: videoFilePath)
      videoSize = usedSpace
    }
    return videoSize
  }

  func getDiskSpace(forFolderPath folderPath: String) -> Double {
    var directorySize = Double.zero
    do {
      let filesArray = try FileManager.default.subpathsOfDirectory(atPath: folderPath)
      for fileName in filesArray {
        let path = folderPath + "/" + fileName
        let fileDictionary = try FileManager.default.attributesOfItem(atPath: path)
        if let fileSize = fileDictionary[.size] as? NSNumber {
          directorySize = directorySize + fileSize.doubleValue
        }
      }
    } catch {
      print("Error getDiskSpace: \(error.localizedDescription)")
    }
    return directorySize
  }

  func matches(with video: BCOVVideo) -> Bool {
    guard let v1Account = accountId,
      let v1Id = videoId,
      let v2Account = video.accountId,
      let v2Id = video.videoId
    else { return false }
    return (v1Account == v2Account) && (v1Id == v2Id)
  }
}
