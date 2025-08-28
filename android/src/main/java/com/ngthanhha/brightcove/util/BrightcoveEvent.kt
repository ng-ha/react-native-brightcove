package com.ngthanhha.brightcove.util

enum class BrightcoveEvent(val eventName: String) {
  ON_READY("onReady"),
  ON_PLAY("onPlay"),
  ON_PAUSE("onPause"),
  ON_END("onEnd"),
  ON_PROGRESS("onProgress"),
  ON_UPDATE_BUFFER_PROGRESS("onUpdateBufferProgress"),
  ON_CHANGE_DURATION("onChangeDuration"),
  ON_ADS_LOADED("onAdsLoaded"),
  ON_ADS_PLAYING("onAdsPlaying"),
  ON_ENTER_FULLSCREEN("onEnterFullscreen"),
  ON_EXIT_FULLSCREEN("onExitFullscreen");
}
