package com.brightcove

import android.content.Context
import android.graphics.Color
import android.util.AttributeSet
import android.util.Log
import android.view.Choreographer
import android.view.SurfaceView
import android.view.View
import android.widget.RelativeLayout
import androidx.core.view.ViewCompat
import androidx.core.view.size
import androidx.media3.common.PlaybackParameters
import com.brightcove.player.display.ExoPlayerVideoDisplayComponent
import com.brightcove.player.edge.Catalog
import com.brightcove.player.edge.CatalogError
import com.brightcove.player.edge.VideoListener
import com.brightcove.player.event.Event
import com.brightcove.player.event.EventType
import com.brightcove.player.model.DeliveryType
import com.brightcove.player.model.Video
import com.brightcove.player.view.BrightcoveExoPlayerVideoView
import com.brightcove.util.BrightcoveEvent
import com.brightcove.util.EventFactory
import com.brightcove.util.getInt
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.LifecycleEventListener
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.UIManagerHelper
import java.net.URI
import java.net.URISyntaxException

class BrightcoveView : RelativeLayout, LifecycleEventListener {
  private val tag: String = "ng-ha:${this.javaClass.getSimpleName()}"
  private var brightcoveVideoView = BrightcoveExoPlayerVideoView(context)
  private var uri: String? = null
  private var accountId: String? = null
  private var videoId: String? = null
  private var policyKey: String? = null
  private var playerName: String? = null
  private var autoPlay = false
  private var playing = false
  private var inViewPort = true
  private var playbackRate = 1f
  private var adVideoLoadTimeout = 3000
  private var bitRate = 0f
  private var frameCounter = 0

  constructor(context: Context?) : super(context)

  constructor(context: Context?, attrs: AttributeSet?) : super(context, attrs)

  constructor(context: Context?, attrs: AttributeSet?, defStyleAttr: Int) : super(
    context, attrs, defStyleAttr
  )

  init {
    (context as ThemedReactContext).addLifecycleEventListener(this)
    setBackgroundColor(Color.BLACK)
    addView(brightcoveVideoView)
    brightcoveVideoView.layoutParams =
      LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
    brightcoveVideoView.finishInitialization()
    setupLayout()
    requestLayout()
    ViewCompat.setTranslationZ(this, 9999f)

    val eventEmitter = brightcoveVideoView.getEventEmitter()
    eventEmitter.on(EventType.VIDEO_SIZE_KNOWN) {
      fixVideoLayout()
      updatePlaybackRate()
    }
    eventEmitter.on(EventType.READY_TO_PLAY) {
      val payload = Arguments.createMap()
      emitOnEvent(BrightcoveEvent.ON_READY.eventName, payload)
    }
    eventEmitter.on(EventType.DID_PLAY) {
      playing = true
      val payload = Arguments.createMap()
      emitOnEvent(BrightcoveEvent.ON_PLAY.eventName, payload)
    }
    eventEmitter.on(EventType.DID_PAUSE) {
      playing = false
      val payload = Arguments.createMap()
      emitOnEvent(BrightcoveEvent.ON_PAUSE.eventName, payload)
    }
    eventEmitter.on(EventType.COMPLETED) {
      val payload = Arguments.createMap()
      emitOnEvent(BrightcoveEvent.ON_END.eventName, payload)
    }
    eventEmitter.on(EventType.PROGRESS) {
      val currentTime = it.properties.getInt(Event.PLAYHEAD_POSITION_LONG)
      if (currentTime == null) return@on
      val payload = Arguments.createMap().apply { putInt("currentTime", currentTime) }
      emitOnEvent(BrightcoveEvent.ON_PROGRESS.eventName, payload)
    }
    eventEmitter.on(EventType.ENTER_FULL_SCREEN) {
      val payload = Arguments.createMap()
      emitOnEvent(BrightcoveEvent.ON_ENTER_FULLSCREEN.eventName, payload)
    }
    eventEmitter.on(EventType.EXIT_FULL_SCREEN) {
      val payload = Arguments.createMap()
      emitOnEvent(BrightcoveEvent.ON_EXIT_FULLSCREEN.eventName, payload)
    }
    eventEmitter.on(EventType.VIDEO_DURATION_CHANGED) {
      val duration = it.properties.getInt(Event.VIDEO_DURATION_LONG)
      if (duration == null) return@on
      val payload = Arguments.createMap().apply { putInt("duration", duration) }
      emitOnEvent(BrightcoveEvent.ON_CHANGE_DURATION.eventName, payload)
    }
    eventEmitter.on(EventType.BUFFERED_UPDATE) {
      val bufferProgress = it.properties.getInt(Event.PERCENT_COMPLETE)
      if (bufferProgress == null) return@on
      val payload = Arguments.createMap().apply { putInt("bufferProgress", bufferProgress) }
      emitOnEvent(BrightcoveEvent.ON_UPDATE_BUFFER_PROGRESS.eventName, payload)
    }
    eventEmitter.on(EventType.AD_BREAK_STARTED) {
      val payload = Arguments.createMap()
      emitOnEvent(BrightcoveEvent.ON_ADS_PLAYING.eventName, payload)
    }
  }

  // Props

  fun setUri(uri: String?) {
    if (uri == null) return
    this.uri = uri
    this.loadVideo()
  }

  fun setAccountId(accountId: String?) {
    if (accountId == null) return
    this.accountId = accountId
    val analytics = brightcoveVideoView.getAnalytics()
    analytics.setAccount(accountId)
    this.loadVideo()
  }

  fun setVideoId(videoId: String?) {
    if (videoId == null) return
    this.videoId = videoId
    this.loadVideo()
  }

  fun setAutoPlay(autoPlay: Boolean) {
    this.autoPlay = autoPlay
  }

  fun setPolicyKey(policyKey: String?) {
    if (policyKey == null) return
    this.policyKey = policyKey
    this.loadVideo()
  }

  fun setPlayerName(playerName: String?) {
    if (playerName == null) return
    this.playerName = playerName
    val analytics = brightcoveVideoView.getAnalytics()
    analytics.setPlayerName(playerName)
  }

  fun setPlay(play: Boolean) {
    if (playing == play) return
    if (play) {
      brightcoveVideoView.start()
    } else {
      brightcoveVideoView.pause()
    }
  }

  fun setVolume(volume: Float?) {
    if (volume == null) return
    val expPlayer =
      (brightcoveVideoView.getVideoDisplay() as ExoPlayerVideoDisplayComponent).exoPlayer
    if (expPlayer == null) {
      Log.e(tag, "Tried to set volume too soon, the player is not initialized yet")
      return
    }
    val details: MutableMap<String, Any?> = HashMap()
    details.put(Event.VOLUME, volume)
    brightcoveVideoView.getEventEmitter().emit(EventType.SET_VOLUME, details)
  }

  fun setBitRate(bitRate: Float?) {
    if (bitRate == null) return
    this.bitRate = bitRate
    // updateBitRate()
  }

  fun setAdVideoLoadTimeout(adVideoLoadTimeout: Int?) {
    if (adVideoLoadTimeout == null) return
    this.adVideoLoadTimeout = adVideoLoadTimeout
    this.loadVideo()
  }

  fun setPlaybackRate(playbackRate: Float?) {
    if (playbackRate == null || playbackRate == 0f) return
    this.playbackRate = playbackRate
    updatePlaybackRate()
  }

  fun setFullscreen(fullscreen: Boolean) {
    if (fullscreen) {
      brightcoveVideoView.getEventEmitter().emit(EventType.ENTER_FULL_SCREEN)
    } else {
      brightcoveVideoView.getEventEmitter().emit(EventType.EXIT_FULL_SCREEN)
    }
  }

  fun setDisableDefaultControl(disabled: Boolean) {

  }

  // Commands

  fun play() {
    brightcoveVideoView.start()
  }

  fun pause() {
    if (playing) brightcoveVideoView.pause()
  }

  fun seekTo(time: Long) {
    brightcoveVideoView.seekTo(time)
  }

  fun stopPlayback() {
    brightcoveVideoView.stopPlayback()
    brightcoveVideoView.clear()
    removeAllViews()
    (context as ThemedReactContext).removeLifecycleEventListener(this)

  }

  fun toggleInViewPort(inViewPort: Boolean) {
    if (inViewPort) {
      this.inViewPort = true
    } else {
      this.inViewPort = false
      brightcoveVideoView.pause()
    }
  }

  fun toggleFullscreen(isFullscreen: Boolean) {
  }

  // Private methods

  private fun emitOnEvent(eventName: String, payload: WritableMap) {
    val reactContext = context as ThemedReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(reactContext)
    val eventDispatcher = UIManagerHelper.getEventDispatcherForReactTag(reactContext, id)
    val event = EventFactory(eventName, payload, surfaceId, id)
    eventDispatcher?.dispatchEvent(event)
  }

  private fun fixVideoLayout() {
    val viewWidth = measuredWidth
    val viewHeight = measuredHeight
    val surfaceView = brightcoveVideoView.renderView as SurfaceView
    surfaceView.measure(viewWidth, viewHeight)
    val surfaceWidth = surfaceView.measuredWidth
    val surfaceHeight = surfaceView.measuredHeight
    val leftOffset = (viewWidth - surfaceWidth) / 2
    val topOffset = (viewHeight - surfaceHeight) / 2
    surfaceView.layout(leftOffset, topOffset, leftOffset + surfaceWidth, topOffset + surfaceHeight)
  }

  private fun updatePlaybackRate() {
    val expPlayer =
      (brightcoveVideoView.getVideoDisplay() as ExoPlayerVideoDisplayComponent).exoPlayer
    expPlayer?.playbackParameters = PlaybackParameters(playbackRate, 1f)
  }

  private fun loadVideo() {
    if (uri != null) {
      val video = Video.createVideo(uri!!, DeliveryType.HLS)
      try {
        val myPosterImage =
          URI("https://sdks.support.brightcove.com/assets/images/general/Great-Blue-Heron.png")
        video.getProperties().put(Video.Fields.STILL_IMAGE_URI, myPosterImage) // hard coded for now
      } catch (e: URISyntaxException) {
        e.printStackTrace()
      }
      playVideo(video)
      return
    }

    if (accountId == null || policyKey == null || videoId == null) return

    val eventEmitter = brightcoveVideoView.getEventEmitter()
    val catalog = Catalog.Builder(eventEmitter, accountId!!).setPolicy(policyKey!!).build()

    catalog.findVideoByID(videoId!!, object : VideoListener() {
      override fun onVideo(video: Video?) {
        playVideo(video)
      }

      override fun onError(error: MutableList<CatalogError?>) {
        Log.e(tag, "onError catalog.findVideoByID $error")
      }
    })
  }

  private fun playVideo(video: Video?) {
    brightcoveVideoView.clear()
    brightcoveVideoView.add(video)
    if (autoPlay) brightcoveVideoView.start()
  }

  /**
   * Android native UI components are not re-layout on dynamically added views.
   * Manually layout children every 60 frames to fix this.
   * See: https://github.com/facebook/react-native/issues/17968#issuecomment-369855903
   */
  private fun setupLayout() {
    Choreographer.getInstance().postFrameCallback(object : Choreographer.FrameCallback {
      override fun doFrame(frameTimeNanos: Long) {
        frameCounter++
        if (frameCounter == 1 || frameCounter >= 60) {
          Log.d(tag, "doFrame")
          manuallyLayoutChildren()
          getViewTreeObserver().dispatchOnGlobalLayout()
          frameCounter = 1
        }
        Choreographer.getInstance().postFrameCallback(this)
      }
    })
  }

  private fun manuallyLayoutChildren() {
    for (i in 0..<size) {
      val child: View = getChildAt(i)
      child.measure(
        MeasureSpec.makeMeasureSpec(measuredWidth, MeasureSpec.EXACTLY),
        MeasureSpec.makeMeasureSpec(measuredHeight, MeasureSpec.EXACTLY)
      )
      child.layout(0, 0, child.measuredWidth, child.measuredHeight)
    }
  }

  // Lifecycle handling

  override fun onHostResume() {
    if (autoPlay) play()
    toggleInViewPort(true)
    Log.d(tag, "onHostResume")
  }

  override fun onHostPause() {
    pause()
    toggleInViewPort(false)
    Log.d(tag, "onHostPause")
  }

  override fun onHostDestroy() {
    brightcoveVideoView.clear()
    removeAllViews()
    (context as ThemedReactContext).removeLifecycleEventListener(this)
    Log.d(tag, "onHostDestroy")
  }
}
