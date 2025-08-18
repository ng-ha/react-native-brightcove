//
//  RCTBrightcoveViewImpl.swift
//  react-native-brightcove
//

import BrightcovePlayerSDK
import UIKit

@objc public protocol RCTBrightcoveViewEventEmitterDelegate {
  @objc func emitEvent(_ name: String, withPayload payload: [String: Any]?)
}

@objc public class RCTBrightcoveViewImpl: UIView {
  private var accountId: String?
  private var policyKey: String?
  private var playerName: String?
  private var videoId: String?
  private var playing = false
  private var autoPlay = false
  private var disableDefaultControl = false
  private var lastProgress = 0
  private var lastBufferProgress: Float = 0.0
  private var playbackRate: Float = 1.0
  private var volume: Float = 1.0
  private var inViewPort = true
  private var isAppInForeground = true
  private var playbackServiceDirty = false
  private let playbackController: BCOVPlaybackController
  private var playbackService: BCOVPlaybackService?
  private var playbackSession: BCOVPlaybackSession?
  private var playerView: BCOVPUIPlayerView?
  @objc public weak var eventEmitterDelegate: RCTBrightcoveViewEventEmitterDelegate?

  @objc override init(frame: CGRect) {
    playbackController = BCOVPlayerSDKManager.sharedManager().createPlaybackController()
    super.init(frame: frame)
    setup()
  }

  @objc required init?(coder: NSCoder) {
    playbackController = BCOVPlayerSDKManager.sharedManager().createPlaybackController()
    super.init(coder: coder)
    setup()
  }

  private func setup() {
    setupAudioSession()
    registerForNotifications()

    playbackController.delegate = self
    // playbackController.isAutoAdvance = true

    playerView = BCOVPUIPlayerView(
      playbackController: playbackController,
      options: nil,
      controlsView: BCOVPUIBasicControlView.withVODLayout()
    )

    guard let playerView else { return }

    addSubview(playerView)
    playerView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      playerView.topAnchor.constraint(equalTo: topAnchor),
      playerView.rightAnchor.constraint(equalTo: rightAnchor),
      playerView.leftAnchor.constraint(equalTo: leftAnchor),
      playerView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    playerView.delegate = self
    // playerView.frame = bounds
    // playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
  }

  private func setupAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
    } catch {
      print("Error setting AVAudioSession category. There may be no sound. \(error)")
    }
  }

  private func setupService() {
    if playbackService == nil || playbackServiceDirty,
      let accountId, !accountId.isEmpty,
      let policyKey, !policyKey.isEmpty
    {
      playbackServiceDirty = false
      playbackService = BCOVPlaybackService(withAccountId: accountId, policyKey: policyKey)
      playbackController.analytics.account = accountId
    }
  }

  private func loadVideo() {
    guard let videoId, !videoId.isEmpty, let offlineManager = BCOVOfflineVideoManager.sharedManager
    else { return }

    for token in offlineManager.offlineVideoTokens {
      guard let offlineVideo = offlineManager.videoObject(fromOfflineVideoToken: token)
      else { continue }
      if offlineVideo.videoId == videoId {
        playbackController.setVideos([offlineVideo])
        return
      }
    }

    //    let configuration = [BCOVPlaybackService.ConfigurationKeyAssetID: videoId]
    //    playbackService.findVideo(withConfiguration: configuration, queryParameters: nil) {
    //      [weak self] (video: BCOVVideo?, jsonResponse: Any?, error: Error?) in
    //      if let video {
    //        self?.playbackController.setVideos([video])
    //      } else {
    //        print("Error retrieving video: \(error?.localizedDescription ?? "unknown error")")
    //      }
    //    }
  }

  // MARK: - Set props

  @objc public func setAccountId(_ accountId: String) {
    self.accountId = accountId
    playbackServiceDirty = true
    setupService()
    loadVideo()
  }

  @objc public func setPolicyKey(_ policyKey: String) {
    self.policyKey = policyKey
    playbackServiceDirty = true
    setupService()
    loadVideo()
  }

  @objc public func setVideoId(_ videoId: String) {
    self.videoId = videoId
    setupService()
    loadVideo()
  }

  @objc public func setPlayerName(_ playerName: String) {
    self.playerName = playerName
    playbackController.analytics.playerName = playerName
  }

  @objc public func setAutoPlay(_ autoPlay: Bool) {
    self.autoPlay = autoPlay
    playbackController.isAutoPlay = autoPlay
  }

  @objc public func setPlay(_ play: Bool) {
    if playing == play { return }
    if play {
      self.play()
    } else {
      self.pause()
    }
  }

  @objc public func setVolume(_ volume: Float) {
    self.volume = volume
    playbackSession?.player?.volume = volume
  }

  @objc public func setPlaybackRate(_ rate: Float) {
    self.playbackRate = rate
    if playing { playbackSession?.player?.rate = rate }
  }

  @objc public func setDisableDefaultControl(_ disable: Bool) {
    self.disableDefaultControl = disable
    playerView?.controlsView.isHidden = disable
  }

  @objc public func setFullscreen(_ fullscreen: Bool) {
    if fullscreen {
      playerView?.performScreenTransition(with: .full)
    } else {
      playerView?.performScreenTransition(with: .normal)
    }
  }

  // MARK: - Player Actions

  @objc public func play() {
    playbackController.play()
  }

  @objc public func pause() {
    playbackController.pause()
  }

  @objc public func seek(to seconds: Double) async -> Bool {
    return await playbackController.seek(to: CMTime(seconds: seconds, preferredTimescale: 1))
  }

  @objc public func stopPlayback() {
    playbackController.setVideos([])
    // cleanup ...
  }

  @objc public func toggleInViewPort(_ isInViewPort: Bool) {
    if isInViewPort {
      inViewPort = true
    } else {
      inViewPort = false
      pause()
    }
  }

  // MARK: - Notification Handling

  private func registerForNotifications() {
    let notificationNames: [NSNotification.Name] = [
      UIApplication.didBecomeActiveNotification,
      UIApplication.willResignActiveNotification,
    ]

    for name in notificationNames {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleAppStateDidChange(_:)),
        name: name,
        object: nil
      )
    }
  }

  @objc private func handleAppStateDidChange(_ notification: Notification) {
    if notification.name == UIApplication.willResignActiveNotification {
      isAppInForeground = false
      toggleInViewPort(false)
      pause()
    }

    if notification.name == UIApplication.didBecomeActiveNotification {
      isAppInForeground = true
      toggleInViewPort(true)
      if autoPlay { play() }
    }
  }
}

// MARK: - BCOVPUIPlayerViewDelegate methods

extension RCTBrightcoveViewImpl: BCOVPUIPlayerViewDelegate {
  public func playerView(
    _ playerView: BCOVPUIPlayerView,
    didTransitionTo screenMode: BCOVPUIScreenMode
  ) {
    if screenMode == .normal {
      eventEmitterDelegate?.emitEvent("onExitFullscreen", withPayload: nil)
    } else if screenMode == .full {
      eventEmitterDelegate?.emitEvent("onEnterFullscreen", withPayload: nil)
    }
  }
}

// MARK: - BCOVPlaybackControllerDelegate methods

extension RCTBrightcoveViewImpl: BCOVPlaybackControllerDelegate {
  public func playbackController(
    _ controller: (any BCOVPlaybackController)!,
    playbackSession session: (any BCOVPlaybackSession)!,
    didChangeDuration duration: TimeInterval
  ) {
    if duration.isFinite {
      eventEmitterDelegate?.emitEvent("onChangeDuration", withPayload: ["duration": Int(duration)])
    }
  }

  public func playbackController(
    _ controller: (any BCOVPlaybackController)!,
    playbackSession session: (any BCOVPlaybackSession)!,
    didProgressTo progress: TimeInterval
  ) {
    if progress.isFinite {  // check for NaN, infinity, -infinity
      let currentTime = Int(progress)
      if lastProgress != currentTime {
        lastProgress = currentTime
        eventEmitterDelegate?.emitEvent("onProgress", withPayload: ["currentTime": currentTime])
      }
    }

    let bufferProgress: Float = playerView?.controlsView.progressSlider.bufferProgress ?? 0
    if bufferProgress.isFinite, lastBufferProgress != bufferProgress {
      lastBufferProgress = bufferProgress
      eventEmitterDelegate?.emitEvent(
        "onUpdateBufferProgress", withPayload: ["bufferProgress": bufferProgress])
    }
  }

  public func playbackController(
    _ controller: (any BCOVPlaybackController)!,
    playbackSession session: (any BCOVPlaybackSession)!,
    didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!
  ) {
    let eventType = lifecycleEvent.eventType
    print("playbackController didReceive lifecycleEvent: \(eventType)")

    if eventType == kBCOVPlaybackSessionLifecycleEventPlaybackBufferEmpty
      || eventType == kBCOVPlaybackSessionLifecycleEventFail
      || eventType == kBCOVPlaybackSessionLifecycleEventError
      || eventType == kBCOVPlaybackSessionLifecycleEventTerminate
    {
      playbackSession = nil
      return
    }

    playbackSession = session

    if eventType == kBCOVPlaybackSessionLifecycleEventReady {
      playbackSession?.player?.volume = volume
      eventEmitterDelegate?.emitEvent("onReady", withPayload: nil)
    } else if eventType == kBCOVPlaybackSessionLifecycleEventPlay {
      playing = true
      playbackSession?.player?.rate = playbackRate
      eventEmitterDelegate?.emitEvent("onPlay", withPayload: nil)
    } else if eventType == kBCOVPlaybackSessionLifecycleEventPause {
      playing = false
      eventEmitterDelegate?.emitEvent("onPause", withPayload: nil)
    } else if eventType == kBCOVPlaybackSessionLifecycleEventEnd {
      eventEmitterDelegate?.emitEvent("onEnd", withPayload: nil)
    }
  }
}
