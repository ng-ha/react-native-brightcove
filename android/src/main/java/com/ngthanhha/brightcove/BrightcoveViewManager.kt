package com.ngthanhha.brightcove

import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.BrightcoveViewManagerDelegate
import com.facebook.react.viewmanagers.BrightcoveViewManagerInterface
import com.ngthanhha.brightcove.util.BrightcoveEvent

@ReactModule(name = BrightcoveViewManager.NAME)
class BrightcoveViewManager : SimpleViewManager<BrightcoveView>(),
  BrightcoveViewManagerInterface<BrightcoveView> {
  private val delegate: ViewManagerDelegate<BrightcoveView> = BrightcoveViewManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<BrightcoveView> = delegate

  override fun getName(): String = NAME

  override fun createViewInstance(context: ThemedReactContext): BrightcoveView =
    BrightcoveView(context)

  @ReactProp(name = "accountId")
  override fun setAccountId(view: BrightcoveView?, value: String?) {
    view?.setAccountId(value)
  }

  @ReactProp(name = "policyKey")
  override fun setPolicyKey(view: BrightcoveView?, value: String?) {
    view?.setPolicyKey(value)
  }

  @ReactProp(name = "playerName")
  override fun setPlayerName(view: BrightcoveView?, value: String?) {
    view?.setPlayerName(value)
  }

  @ReactProp(name = "videoId")
  override fun setVideoId(view: BrightcoveView?, value: String?) {
    view?.setVideoId(value)
  }

  @ReactProp(name = "playlistReferenceId")
  override fun setPlaylistReferenceId(view: BrightcoveView?, value: String?) {
    view?.setPlaylistReferenceId(value)
  }

  @ReactProp(name = "autoPlay")
  override fun setAutoPlay(view: BrightcoveView?, value: Boolean) {
    view?.setAutoPlay(value)
  }

  @ReactProp(name = "play")
  override fun setPlay(view: BrightcoveView?, value: Boolean) {
    view?.setPlay(value)
  }

  @ReactProp(name = "fullscreen")
  override fun setFullscreen(view: BrightcoveView?, value: Boolean) {
    view?.setFullscreen(value)
  }

  @ReactProp(name = "disableDefaultControl")
  override fun setDisableDefaultControl(view: BrightcoveView?, value: Boolean) {
    view?.setDisableDefaultControl(value)
  }

  @ReactProp(name = "volume")
  override fun setVolume(view: BrightcoveView?, value: Float) {
    view?.setVolume(value)
  }

  @ReactProp(name = "playbackRate")
  override fun setPlaybackRate(view: BrightcoveView?, value: Float) {
    view?.setPlaybackRate(value)
  }

  override fun play(view: BrightcoveView?) {
    view?.play()
  }

  override fun pause(view: BrightcoveView?) {
    view?.pause()
  }

  override fun seekTo(view: BrightcoveView?, seconds: Int) {
    view?.seekTo(seconds * 1000L)
  }

  override fun stopPlayback(view: BrightcoveView?) {
    view?.stopPlayback()
  }

  override fun toggleFullscreen(view: BrightcoveView?, isFullscreen: Boolean) {
    view?.toggleFullscreen(isFullscreen)
  }

  override fun toggleInViewPort(view: BrightcoveView?, inViewPort: Boolean) {
    view?.toggleInViewPort(inViewPort)
  }

  companion object {
    const val NAME = "BrightcoveView"
  }

  override fun getExportedCustomBubblingEventTypeConstants(): Map<String, Any> {
    val result = mutableMapOf<String, Any>()
    val events = BrightcoveEvent.entries.map { it.eventName }
    for (event in events) {
      result[event] = mapOf(
        "phasedRegistrationNames" to mapOf(
          "bubbled" to event,
          "captured" to "${event}Capture"
        )
      )
    }
    return result
  }
}
