//
//  RCTBrightcoveDownloaderImpl.swift
//  react-native-brightcove
//

import BrightcovePlayerSDK
import Foundation
import React

public typealias RCTPromiseResolveBlock = (Any?) -> Void

public typealias RCTPromiseRejectBlock = (String?, String?, (any Error)?) -> Void

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

  private func getVideoId(fromVideoOfflineToken token: BCOVOfflineVideoToken?) -> String? {
    guard let token, let offlineManager = BCOVOfflineVideoManager.sharedManager else { return nil }
    let video = offlineManager.videoObject(fromOfflineVideoToken: token)
    return video?.videoId
  }

  private func getVideoOfflineToken(fromVideoId videoId: String?) -> BCOVOfflineVideoToken? {
    guard let videoId, let offlineManager = BCOVOfflineVideoManager.sharedManager else {
      return nil
    }
    for token in offlineManager.offlineVideoTokens {
      guard let offlineVideo = offlineManager.videoObject(fromOfflineVideoToken: token)
      else { continue }
      if offlineVideo.videoId == videoId { return token }
    }
    return nil
  }

  private func createVideoDictionary(
    from video: BCOVVideo,
    offlineManager: BCOVOfflineVideoManager,
    offlineVideoToken token: BCOVOfflineVideoToken
  ) -> [String: Any] {
    let status = offlineManager.offlineVideoStatus(forToken: token)?.downloadState.rawValue ?? -1

    let dict: [String: Any] = [
      "id": video.videoId ?? "",
      "referenceId": video.referenceId ?? "",
      "name": video.name ?? "",
      "shortDescription": video.shortDescription ?? "",
      "longDescription": video.longDescription ?? "",
      "duration": video.duration ?? 0,
      "thumbnailUri": video.offlineThumbnail ?? "",
      "posterUri": video.offlinePoster ?? "",
      "licenseExpiryDate": video.licenseExpirationTime,
      "actualSize": video.size,
      "status": status,
    ]
    return dict
  }

  @objc public func initModule(config: [String: Any]) {
    guard let accountId = config["accountId"] as? String, !accountId.isEmpty,
      let policyKey = config["policyKey"] as? String, !policyKey.isEmpty
    else { return }

    self.accountId = accountId
    self.policyKey = policyKey
    playbackService = BCOVPlaybackService(withAccountId: accountId, policyKey: policyKey)

    let options = [
      BCOVOfflineVideoManager.AllowsCellularDownloadKey: true,
      BCOVOfflineVideoManager.AllowsCellularPlaybackKey: true,
      BCOVOfflineVideoManager.AllowsCellularAnalyticsKey: true,
    ]
    BCOVOfflineVideoManager.initializeOfflineVideoManager(withDelegate: self, options: options)
  }

  @objc public func deinitModule() {
    eventEmitterDelegate = nil
  }

  @objc public func getAllDownloadedVideos(
    resolve: RCTPromiseResolveBlock,
    reject: RCTPromiseRejectBlock
  ) {
    guard let offlineManager = BCOVOfflineVideoManager.sharedManager else {
      reject("ERR_NO_OFFLINE_MANAGER", "Offline manager is nil", nil)
      return
    }
    var result: [[String: Any]] = []
    for token in offlineManager.offlineVideoTokens {
      guard let video = offlineManager.videoObject(fromOfflineVideoToken: token)
      else { continue }

      let videoDict = createVideoDictionary(
        from: video,
        offlineManager: offlineManager,
        offlineVideoToken: token
      )
      print("videoDict \(videoDict)")
      result.append(videoDict)
    }
    resolve(result)
  }

  @objc public func getDownloadedVideoById(
    _ id: String?,
    resolve: RCTPromiseResolveBlock,
    reject: RCTPromiseRejectBlock
  ) {
    guard let id, !id.isEmpty else {
      reject("ERR_INVALID_ID", "Video ID is nil or empty", nil)
      return
    }

    guard let offlineManager = BCOVOfflineVideoManager.sharedManager else {
      reject("ERR_NO_OFFLINE_MANAGER", "Offline manager is nil", nil)
      return
    }

    for token in offlineManager.offlineVideoTokens {
      guard let video = offlineManager.videoObject(fromOfflineVideoToken: token),
        video.videoId == id
      else { continue }

      let videoDict = createVideoDictionary(
        from: video,
        offlineManager: offlineManager,
        offlineVideoToken: token
      )
      print("videoDict \(videoDict)")
      resolve(videoDict)
      return
    }
    reject("ERR_VIDEO_NOT_FOUND", "No downloaded video found with given ID", nil)
  }

  @objc public func estimateDownloadSize(
    withVideoId id: String?,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    guard let id, !id.isEmpty else {
      reject("ERR_INVALID_ID", "Video ID is nil or empty", nil)
      return
    }

    guard let playbackService else {
      reject("ERR_NO_PLAYBACK_SERVICE", "Playback service is nil", nil)
      return
    }

    guard let offlineManager = BCOVOfflineVideoManager.sharedManager else {
      reject("ERR_NO_OFFLINE_MANAGER", "Offline manager is nil", nil)
      return
    }

    let configuration = [BCOVPlaybackService.ConfigurationKeyAssetID: id]
    playbackService.findVideo(withConfiguration: configuration, queryParameters: nil) {
      (video: BCOVVideo?, jsonResponse: Any?, error: Error?) in
      if let video {
        offlineManager.estimateDownloadSize(
          video, options: [BCOVOfflineVideoManager.RequestedBitrateKey: 0]
        ) { (size: Double, e: (any Error)?) in
          if let e {
            reject("ERR_ESTIMATE_FAILED", "Failed to estimate download size", e)
            print("Estimate error: \(e.localizedDescription)")
            return
          }
          resolve(size * 1024 * 1024)
        }
        return
      }

      reject("ERR_VIDEO_NOT_FOUND", "Cannot find video with given ID", error)
      print("Cannot find video: \(error?.localizedDescription ?? "unknown error")")
    }
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

      self.eventEmitterDelegate?.emitOnDownloadFailed([
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

    for token in offlineManager.offlineVideoTokens {
      guard let offlineVideo = offlineManager.videoObject(fromOfflineVideoToken: token)
      else { continue }
      if offlineVideo.matches(with: video) {
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
      print("Video \(video.name ?? "") does not use FairPlay, preloading not necessary")
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
      print("Variant Bitrates for video \(video.name ?? ""):")
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
      print("urlAsset: \(urlAsset.url.absoluteString)")
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

    offlineManager.requestVideoDownload(video, mediaSelections: mediaSelections, parameters: nil) {
      [weak self] (offlineVideoToken: String?, error: (any Error)?) in
      guard let self else { return }
      if let error {
        self.eventEmitterDelegate?.emitOnDownloadFailed([
          "id": video.videoId ?? "",
          "reason": "Download video failed: \(error.localizedDescription)",
        ])
        return
      }
      self.eventEmitterDelegate?.emitOnDownloadStarted([
        "id": video.videoId ?? "",
        "referenceId": video.referenceId ?? "",
        "name": video.name ?? "",
        "shortDescription": video.shortDescription ?? "",
        "longDescription": video.longDescription ?? "",
        "duration": video.duration ?? 0,
        "thumbnailUri": video.onlineThumbnail ?? "",
        "posterUri": video.onlinePoster ?? "",
      ])
      print("request video download complete!")
    }
  }

  @objc public func pauseVideoDownload(
    withVideoId videoId: String?,
    resolve: RCTPromiseResolveBlock,
    reject: RCTPromiseRejectBlock
  ) {
    guard let token = getVideoOfflineToken(fromVideoId: videoId),
      let offlineManager = BCOVOfflineVideoManager.sharedManager,
      let status = offlineManager.offlineVideoStatus(forToken: token)
    else {
      reject("ERR_NO_STATUS", "Offline video status could not be retrieved", nil)
      return
    }
    if status.downloadState == .downloading {
      offlineManager.pauseVideoDownload(token)
      resolve(true)
      return
    }
    reject("ERR_NOT_DOWNLOADING", "Video is not currently downloading", nil)
  }

  @objc public func resumeVideoDownload(
    withVideoId videoId: String?,
    resolve: RCTPromiseResolveBlock,
    reject: RCTPromiseRejectBlock
  ) {
    guard let token = getVideoOfflineToken(fromVideoId: videoId),
      let offlineManager = BCOVOfflineVideoManager.sharedManager,
      let status = offlineManager.offlineVideoStatus(forToken: token)
    else {
      reject("ERR_NO_STATUS", "Offline video status could not be retrieved", nil)
      return
    }
    if status.downloadState == .suspended {
      offlineManager.resumeVideoDownload(token)
      resolve(true)
      return
    }
    reject("ERR_NOT_SUSPENDED", "Video is not currently suspended", nil)
  }

  @objc public func cancelVideoDownload(
    withVideoId videoId: String?,
    resolve: RCTPromiseResolveBlock,
    reject: RCTPromiseRejectBlock
  ) {
    guard let token = getVideoOfflineToken(fromVideoId: videoId),
      let offlineManager = BCOVOfflineVideoManager.sharedManager
    else {
      reject("ERR_NO_STATUS", "Token or manager is nil", nil)
      return
    }
    offlineManager.cancelVideoDownload(token)
    resolve(true)
  }

  @objc public func deleteVideo(
    withVideoId videoId: String?,
    resolve: RCTPromiseResolveBlock,
    reject: RCTPromiseRejectBlock
  ) {
    guard let token = getVideoOfflineToken(fromVideoId: videoId),
      let offlineManager = BCOVOfflineVideoManager.sharedManager
    else {
      reject("ERR_INVALID_TOKEN", "Offline video token or manager is nil", nil)
      return
    }
    offlineManager.deleteOfflineVideo(token)
    eventEmitterDelegate?.emitOnDownloadDeleted(["id": videoId ?? ""])
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
    assetDownloadTask: AVAssetDownloadTask,
    willDownloadVariants variants: [AVAssetVariant]
  ) {
    print("assetDownloadTask \(offlineVideoToken) willDownloadVariants:\(variants)")
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
    print("aggregateDownloadTask \(offlineVideoToken) didProgressTo:\(progressPercent)")
  }

  public func offlineVideoToken(
    _ offlineVideoToken: BCOVOfflineVideoToken,
    didFinishMediaSelectionDownload mediaSelection: AVMediaSelection
  ) {
    let videoId = getVideoId(fromVideoOfflineToken: offlineVideoToken) ?? ""
    eventEmitterDelegate?.emitOnDownloadCompleted(["id": videoId])
    print("didFinishMediaSelectionDownload \(offlineVideoToken)")
  }

  public func offlineVideoToken(
    _ offlineVideoToken: BCOVOfflineVideoToken,
    didFinishDownloadWithError error: (any Error)?
  ) {
    guard let error else { return }
    let videoId = getVideoId(fromVideoOfflineToken: offlineVideoToken) ?? ""
    eventEmitterDelegate?.emitOnDownloadFailed([
      "id": videoId,
      "reason": error.localizedDescription,
    ])
    print("didFinishDownloadWithError \(error.localizedDescription)")
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
