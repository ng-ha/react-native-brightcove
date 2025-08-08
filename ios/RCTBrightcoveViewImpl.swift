//
//  RCTBrightcoveViewImpl.swift
//  react-native-brightcove
//

import BrightcovePlayerSDK
import UIKit

let kAccountId = "5434391461001"
let kPolicyKey =
  "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
// Video Asset
let kVideoId = "6140448705001"
// Audio-Only Asset
// let kVideoId = "1732548841120406830"

@objc
public class RCTBrightcoveViewImpl: UIView, BCOVPlaybackControllerDelegate,
  BCOVPUIPlayerViewDelegate
{
  let sharedSDKManager = BCOVPlayerSDKManager.sharedManager()
  let playbackService = BCOVPlaybackService(withAccountId: kAccountId, policyKey: kPolicyKey)
  let playbackController: BCOVPlaybackController
  var playerView: BCOVPUIPlayerView?

  @objc public var playerViewDelegate: BCOVPUIPlayerViewDelegate?
  @objc public var controllerDelegate: BCOVPlaybackControllerDelegate?

  @objc override init(frame: CGRect) {
    playbackController = sharedSDKManager.createPlaybackController()
    super.init(frame: frame)
    setup()
  }

  @objc required init?(coder: NSCoder) {
    playbackController = sharedSDKManager.createPlaybackController()
    super.init(coder: coder)
    setup()
  }

  func setup() {
    playbackController.analytics.account = kAccountId
    playbackController.delegate = self
    playbackController.isAutoAdvance = true
    playbackController.isAutoPlay = true

    // Set up our player view. Create with a standard VOD layout.
    playerView = BCOVPUIPlayerView(
      playbackController: playbackController,
      options: nil,
      controlsView: BCOVPUIBasicControlView.withVODLayout()
    )

    guard let playerView else { return }

    // Install in the container view and match its size.
    //    playerView.translatesAutoresizingMaskIntoConstraints = false
    //    NSLayoutConstraint.activate([
    //      playerView.topAnchor.constraint(equalTo: topAnchor),
    //      playerView.rightAnchor.constraint(equalTo: rightAnchor),
    //      playerView.leftAnchor.constraint(equalTo: leftAnchor),
    //      playerView.bottomAnchor.constraint(equalTo: bottomAnchor),
    //    ])
    playerView.frame = bounds
    playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(playerView)

    // Associate the playerView with the playback controller.
    playerView.playbackController = playbackController // no needed
    requestContentFromPlaybackService()
  }

//  public override func layoutSubviews() {
//    super.layoutSubviews()
//    if let playerView { playerView.frame = bounds }
//  }

  // Trigger required third-party controller event
  //  @objc func triggerViewWillAppear() {
  //    self.cameraViewController?.viewWillAppear(true)
  //  }

  func requestContentFromPlaybackService() {
    let configuration = [BCOVPlaybackService.ConfigurationKeyAssetID: kVideoId]
    playbackService.findVideo(
      withConfiguration: configuration, queryParameters: nil
    ) { [weak self] (video: BCOVVideo?, jsonResponse: Any?, error: Error?) in
      if let v = video {
        self?.playbackController.setVideos([v])
      } else {
        print(
          "ViewController Debug - Error retrieving video: \(error?.localizedDescription ?? "unknown error")"
        )
      }
    }
  }
}
