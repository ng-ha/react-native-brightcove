//
//  RCTBrightcoveDownloaderImpl.swift
//  react-native-brightcove
//

import BrightcovePlayerSDK
import Foundation
import React

@objc public protocol RCTBrightcoveDownloadEventEmitterDelegate {
  @objc func emitOnDownloadRequested(_ value: [String: Any]?)
  @objc func emitOnDownloadStarted(_ value: [String: Any]?)
  @objc func emitOnDownloadProgress(_ value: [String: Any]?)
  @objc func emitOnDownloadPaused(_ value: [String: Any]?)
  @objc func emitOnDownloadCompleted(_ value: [String: Any]?)
  @objc func emitOnDownloadCanceled(_ value: [String: Any]?)
  @objc func emitOnDownloadDeleted(_ value: [String: Any]?)
  @objc func emitOnDownloadFailed(_ value: [String: Any]?)
}

@objc public class RCTBrightcoveDownloaderImpl: NSObject {
  private var accountId: String?
  private var policyKey: String?
  private var playbackService: BCOVPlaybackService?
  @objc public weak var eventEmitterDelegate: RCTBrightcoveDownloadEventEmitterDelegate?

  private func getVideoId(fromVideoOfflineToken token: BCOVOfflineVideoToken) -> String? {
    guard let offlineManager = BCOVOfflineVideoManager.sharedManager else { return nil }
    let video = offlineManager.videoObject(fromOfflineVideoToken: token)
    return video?.videoId
  }

  private func getDiskSpace(forFolderPath folderPath: String) -> Int64 {
    var directorySize = Int64.zero
    do {
      let filesArray = try FileManager.default.subpathsOfDirectory(atPath: folderPath)

      for fileName in filesArray {
        let path = folderPath + "/" + fileName
        let fileDictionary = try FileManager.default.attributesOfItem(atPath: path)
        if let fileSize = fileDictionary[.size] as? NSNumber {
          directorySize = directorySize + fileSize.int64Value
        }
      }
    } catch {
      print("Error getDiskSpace: \(error.localizedDescription)")
    }

    return directorySize
  }

  private func formatFileSize(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = .useMB
    formatter.countStyle = .file
    formatter.includesUnit = false
    formatter.includesCount = true
    formatter.zeroPadsFractionDigits = true
    return formatter.string(fromByteCount: bytes) as String
  }

  @objc public func initModule(config: [String: Any]) {
    guard let accountId = config["accountId"] as? String, !accountId.isEmpty,
      let policyKey = config["policyKey"] as? String, !policyKey.isEmpty
    else { return }

    self.accountId = accountId
    self.policyKey = policyKey
    playbackService = BCOVPlaybackService(withAccountId: accountId, policyKey: policyKey)

    let options = [
      BCOVOfflineVideoManager.AllowsCellularDownloadKey: false,
      BCOVOfflineVideoManager.AllowsCellularPlaybackKey: false,
      BCOVOfflineVideoManager.AllowsCellularAnalyticsKey: false,
    ]
    BCOVOfflineVideoManager.initializeOfflineVideoManager(withDelegate: self, options: options)
  }

  @objc public func deinitModule() {
    eventEmitterDelegate = nil
    // remove listener
  }

  @objc public func getDownloadedVideos(
    resolve: RCTPromiseResolveBlock,
    reject: RCTPromiseRejectBlock
  ) {
    guard let offlineManager = BCOVOfflineVideoManager.sharedManager else {
      reject("ERR_NO_OFFLINE_MANAGER", "Offline manager is nil", nil)
      return
    }
    let tokens = offlineManager.offlineVideoTokens
    var result: [[String: Any]] = []

    for token in tokens {
      guard let video = offlineManager.videoObject(fromOfflineVideoToken: token)
      else { continue }

      var timestamp = 0.0
      if let absoluteExpirationNumber = video.properties[
        BCOVOfflineVideo.LicenseAbsoluteExpirationTimePropertyKey] as? NSNumber
      {
        let expirationDate = Date(
          timeIntervalSinceReferenceDate: absoluteExpirationNumber.doubleValue)
        timestamp = expirationDate.timeIntervalSince1970 * 1000
      }

      var videoSize = 0.0

      if let videoFilePath = video.properties[BCOVOfflineVideo.FilePathPropertyKey] as? String,
        let usedSpace = Double(formatFileSize(getDiskSpace(forFolderPath: videoFilePath)))
      {
        videoSize = usedSpace
      }

      let dict: [String: Any] = [
        "id": video.properties[BCOVVideo.PropertyKeyId] as? String ?? "",
        "referenceId": video.properties[BCOVVideo.PropertyKeyReferenceId] as? String ?? "",
        "name": video.properties[BCOVVideo.PropertyKeyName] as? String ?? "",
        "shortDescription": video.properties[BCOVVideo.PropertyKeyDescription] as? String ?? "",
        "longDescription": video.properties[BCOVVideo.PropertyKeyLongDescription] as? String ?? "",
        "duration": video.properties[BCOVVideo.PropertyKeyDuration] as? NSNumber ?? 0,
        "thumbnailUri": video.properties[BCOVVideo.PropertyKeyThumbnail] as? String ?? "",
        "posterUri": video.properties[BCOVVideo.PropertyKeyPoster] as? String ?? "",
        "licenseExpiryDate": timestamp,
        "size": videoSize,
        "thumbnailUri2": video.properties[BCOVOfflineVideo.ThumbnailFilePathPropertyKey] as? String
          ?? "",
        "posterUri2": video.properties[BCOVOfflineVideo.PosterFilePathPropertyKey] as? String ?? "",
      ]
      result.append(dict)
    }
    resolve(result)
  }

  @objc public func findVideoToDownload(withId id: String?) {
    guard let id else {
      eventEmitterDelegate?.emitOnDownloadFailed([
        "id": "",
        "reason": "Cannot find video: missing video ID",
      ])
      return
    }

    guard let playbackService else {
      eventEmitterDelegate?.emitOnDownloadFailed([
        "id": id,
        "reason": "Cannot find video: playback service unavailable",
      ])
      return
    }

    let configuration = [BCOVPlaybackService.ConfigurationKeyAssetID: id]
    playbackService.findVideo(withConfiguration: configuration, queryParameters: nil) {
      [weak self] (video: BCOVVideo?, jsonResponse: Any?, error: Error?) in
      guard let self else { return }

      if let video {
        self.checkAndPreloadVideo(video)
        return
      }

      eventEmitterDelegate?.emitOnDownloadFailed([
        "id": id,
        "reason": "Cannot find video: \(error?.localizedDescription ?? "unknown error")",
      ])
      print("Cannot find video: \(error?.localizedDescription ?? "unknown error")")
    }
  }

  private func checkAndPreloadVideo(_ video: BCOVVideo) {
    // check if the video has already been downloaded or is in the process of downloading
    guard let offlineManager = BCOVOfflineVideoManager.sharedManager else {
      eventEmitterDelegate?.emitOnDownloadFailed([
        "id": video.videoId ?? "",
        "reason": "Cannot check/preload video: offlineManager is nil",
      ])
      return
    }

    let tokens = offlineManager.offlineVideoTokens
    for token in tokens {
      guard let offlineVideo = offlineManager.videoObject(fromOfflineVideoToken: token)
      else { continue }

      if offlineVideo.matches(with: video) {
        // TODO: Handle video with error or cancelled status
        // if let status = offlineManager.offlineVideoStatus(forToken: token),
        //   status.downloadState == .error || status.downloadState == .cancelled
        // {
        //   return
        // }
        eventEmitterDelegate?.emitOnDownloadFailed([
          "id": video.videoId ?? "",
          "reason": "Check video failed: It is already downloaded/failed/canceled/in progress",
        ])
        return
      }
    }

    // preload for FairPlay video
    if video.usesFairPlay {
      // TODO: handle parameters
      offlineManager.preloadFairPlayLicense(video, parameters: [:]) {
        [weak self] (offlineVideoToken: String?, error: Error?) in
        guard let self else { return }

        if let error {
          self.eventEmitterDelegate?.emitOnDownloadFailed([
            "id": video.videoId ?? "",
            "reason": "Error preload FairPlay license: \(error.localizedDescription)",
          ])
          print("Error preload FairPlay license: \(error.localizedDescription)")
          return
        }

        if let offlineVideoToken { print("Preloaded \(offlineVideoToken)") }
        self.downloadVideo(video)
      }
    } else {
      print(
        "Video \"\(video.localizedName(forLocale: nil) ?? "nil")\" does not use FairPlay; preloading not necessary"
      )
      downloadVideo(video)
    }
  }

  private func downloadVideo(_ video: BCOVVideo) {
    guard let offlineManager = BCOVOfflineVideoManager.sharedManager else {
      eventEmitterDelegate?.emitOnDownloadFailed([
        "id": video.videoId ?? "",
        "reason": "Cannot download video: offlineManager is nil",
      ])
      return
    }

    // Log all available bitrates
    offlineManager.variantBitrates(forVideo: video) { (bitrates: [Int]?, error: Error?) in
      print("Variant Bitrates for video: \(video.localizedName(forLocale: nil) ?? "unknown")")
      if let bitrates {
        for bitrate in bitrates {
          print("\(bitrate)")
        }
      }
    }

    var urlAsset: AVURLAsset?
    do {
      urlAsset = try offlineManager.urlAsset(forVideo: video)
    } catch {
      print("Error creating AVURLAsset: \(error.localizedDescription)")
    }

    // If mediaSelections is `nil` the SDK will default to the AVURLAsset's `preferredMediaSelection`
    var mediaSelections = [AVMediaSelection]()

    if let urlAsset {
      if urlAsset.url.absoluteString.contains("aes128") {
        eventEmitterDelegate?.emitOnDownloadFailed([
          "id": video.videoId ?? "",
          "reason":
            "Cannot download video: HLSe (AES-128) streams are not supported for offline playback",
        ])
        return
      }

      mediaSelections = urlAsset.allMediaSelections

      // Logging
      if let legibleMSG = urlAsset.mediaSelectionGroup(forMediaCharacteristic: .legible),
        let audibleMSG = urlAsset.mediaSelectionGroup(forMediaCharacteristic: .audible)
      {
        var counter = 0
        for selection in mediaSelections {
          let legibleName = selection.selectedMediaOption(in: legibleMSG)?.displayName ?? "nil"
          let audibleName = selection.selectedMediaOption(in: audibleMSG)?.displayName ?? "nil"
          print("AVMediaSelection option \(counter) | legible display name: \(legibleName)")
          print("AVMediaSelection option \(counter) | audible display name: \(audibleName)")
          counter += 1
        }
      }
    }

    // TODO: handle parameters
    offlineManager.requestVideoDownload(video, mediaSelections: mediaSelections, parameters: nil) {
      [weak self] (offlineVideoToken: String?, error: Error?) in
      guard let self else { return }

      if let error {
        self.eventEmitterDelegate?.emitOnDownloadFailed([
          "id": video.videoId ?? "",
          "reason": "Download video failed: \(error.localizedDescription)",
        ])
      }
      print("request video download complete!")
    }
  }

  @objc public func pauseVideoDownload(
    withOfflineVideoToken offlineVideoToken: String?,
    resolve: RCTPromiseResolveBlock,
    reject: RCTPromiseRejectBlock
  ) {
    guard let token = offlineVideoToken as? BCOVOfflineVideoToken,
      let offlineManager = BCOVOfflineVideoManager.sharedManager,
      let status = offlineManager.offlineVideoStatus(forToken: token)
    else {
      reject("ERR_NO_STATUS", "Offline video status could not be retrieved", nil)
      return
    }

    if status.downloadState == .downloading {
      offlineManager.pauseVideoDownload(token)
      resolve(true)
    }

    reject("ERR_NOT_DOWNLOADING", "Video is not currently downloading", nil)
  }

  @objc public func resumeVideoDownload(
    withOfflineVideoToken offlineVideoToken: String?,
    resolve: RCTPromiseResolveBlock,
    reject: RCTPromiseRejectBlock
  ) {
    guard let token = offlineVideoToken as? BCOVOfflineVideoToken,
      let offlineManager = BCOVOfflineVideoManager.sharedManager,
      let status = offlineManager.offlineVideoStatus(forToken: token)
    else {
      reject("ERR_NO_STATUS", "Offline video status could not be retrieved", nil)
      return
    }

    if status.downloadState == .suspended {
      offlineManager.resumeVideoDownload(token)
      resolve(true)
    }

    reject("ERR_NOT_SUSPENDED", "Video is not currently suspended", nil)
  }

  @objc public func deleteVideo(
    withOfflineVideoToken offlineVideoToken: String?,
    resolve: RCTPromiseResolveBlock,
    reject: RCTPromiseRejectBlock
  ) {
    guard let token = offlineVideoToken as? BCOVOfflineVideoToken,
      let offlineManager = BCOVOfflineVideoManager.sharedManager
    else {
      reject("ERR_INVALID_TOKEN", "Offline video token or manager is nil", nil)
      return
    }

    offlineManager.deleteOfflineVideo(token)
    let videoId = getVideoId(fromVideoOfflineToken: token) ?? ""
    eventEmitterDelegate?.emitOnDownloadDeleted(["id": videoId])
    resolve(true)
  }
}

// MARK: - BCOVOfflineVideoManagerDelegate methods

extension RCTBrightcoveDownloaderImpl: BCOVOfflineVideoManagerDelegate {
  public func didCreateSharedBackgroundSesssionConfiguration(
    _ backgroundSessionConfiguration: URLSessionConfiguration
  ) {
    // Helps prevent downloads from appearing to sometimes stall
    backgroundSessionConfiguration.isDiscretionary = false
    print("didCreateSharedBackgroundSessionConfiguration")
  }

  public func offlineVideoToken(
    _ offlineVideoToken: BCOVOfflineVideoToken,
    aggregateDownloadTask: AVAggregateAssetDownloadTask,
    didProgressTo progressPercent: TimeInterval,
    forMediaSelection mediaSelection: AVMediaSelection
  ) {
    let videoId = getVideoId(fromVideoOfflineToken: offlineVideoToken) ?? ""
    let payload: [String: Any] = ["id": videoId, "progress": progressPercent]
    eventEmitterDelegate?.emitOnDownloadProgress(payload)
    print("\(offlineVideoToken) aggregateDownloadTask didProgressTo:\(progressPercent)")
  }

  // remove
  public func offlineVideoToken(
    _ offlineVideoToken: BCOVOfflineVideoToken,
    assetDownloadTask: AVAssetDownloadTask,
    didProgressTo progressPercent: TimeInterval
  ) {
    print("\(offlineVideoToken) assetDownloadTask didProgressTo:\(progressPercent)")
  }

  // remove
  public func offlineVideoToken(
    _ offlineVideoToken: BCOVOfflineVideoToken,
    assetDownloadTask: AVAssetDownloadTask,
    willDownloadVariants variants: [AVAssetVariant]
  ) {
    print("\(offlineVideoToken) assetDownloadTask willDownloadVariants:\(variants)")
  }

  public func offlineVideoToken(
    _ offlineVideoToken: BCOVOfflineVideoToken,
    didFinishMediaSelectionDownload mediaSelection: AVMediaSelection
  ) {
    let videoId = getVideoId(fromVideoOfflineToken: offlineVideoToken) ?? ""
    eventEmitterDelegate?.emitOnDownloadCompleted(["id": videoId])
    print("offlineVideoToken \(offlineVideoToken) didFinishMediaSelectionDownload")
  }

  public func offlineVideoToken(
    _ offlineVideoToken: BCOVOfflineVideoToken,
    didFinishDownloadWithError error: (any Error)?
  ) {
    let videoId = getVideoId(fromVideoOfflineToken: offlineVideoToken) ?? ""
    eventEmitterDelegate?.emitOnDownloadFailed([
      "id": videoId,
      "reason": error?.localizedDescription ?? "",
    ])
    print("\(offlineVideoToken) didFinishDownloadWithError \(error?.localizedDescription ?? "nil")")
  }

  public func downloadWasPaused(forOfflineVideoToken offlineVideoToken: BCOVOfflineVideoToken) {
    let videoId = getVideoId(fromVideoOfflineToken: offlineVideoToken) ?? ""
    eventEmitterDelegate?.emitOnDownloadPaused(["id": videoId])
    print("downloadWasPaused \(offlineVideoToken)")
  }

  public func offlineVideoStorageDidChange() {
    print("offlineVideoStorageDidChange")
    // called on the main thread.
  }
}
