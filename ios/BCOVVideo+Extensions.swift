//
//  BCOVVideo+Extensions.swift
//  react-native-brightcove
//

import BrightcovePlayerSDK

extension BCOVVideo {
  var accountId: String? { properties[BCOVVideo.PropertyKeyAccountId] as? String }
  var videoId: String? { properties[BCOVVideo.PropertyKeyId] as? String }
  var offlineVideoToken: String? { properties[BCOVOfflineVideo.TokenPropertyKey] as? String }

  var duration: String {
    guard let durationNumber = properties[BCOVVideo.PropertyKeyDuration] as? NSNumber else {
      return ""
    }

    let totalSeconds = durationNumber.doubleValue / 1000
    let hours = Int(totalSeconds.truncatingRemainder(dividingBy: 86400) / 3600)
    let minutes = Int(totalSeconds.truncatingRemainder(dividingBy: 3600) / 60)
    let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
    if hours > 0 {
      return String(format: "%i:%02i:%02i", hours, minutes, seconds)
    } else {
      return String(format: "%02i:%02i", minutes, seconds)
    }
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
