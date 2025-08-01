package com.brightcove

import android.content.Context
import android.content.res.Configuration
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
import com.brightcove.player.edge.OfflineCallback
import com.brightcove.player.edge.OfflineCatalog
import com.brightcove.player.edge.OfflineStoreManager
import com.brightcove.player.edge.PlaylistListener
import com.brightcove.player.edge.VideoListener
import com.brightcove.player.event.Event
import com.brightcove.player.event.EventType
import com.brightcove.player.mediacontroller.BrightcoveMediaController
import com.brightcove.player.model.Playlist
import com.brightcove.player.model.Video
import com.brightcove.player.network.DownloadStatus
import com.brightcove.player.network.HttpRequestConfig
import com.brightcove.player.view.BrightcoveExoPlayerVideoView
import com.brightcove.util.BrightcoveEvent
import com.brightcove.util.EventFactory
import com.brightcove.util.getInt
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.LifecycleEventListener
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.UIManagerHelper

class BrightcoveView : RelativeLayout, LifecycleEventListener {
  private val tag: String = "ng-ha:${this.javaClass.simpleName}"
  private var brightcoveVideoView = BrightcoveExoPlayerVideoView(context)
  private var catalog: OfflineCatalog? = null
  private var accountId: String? = null
  private var playlistReferenceId: String? = null
  private var videoId: String? = null
  private var policyKey: String? = null
  private var playerName: String? = null
  private var autoPlay = false
  private var playing = false
  private var inViewPort = true
  private var disableDefaultControl = false
  private var mediaController: BrightcoveMediaController? = null
  private val controlTimeout = BrightcoveMediaController.DEFAULT_TIMEOUT
  private var playbackRate = 1f
  private var frameCounter = 0
  private var stopFrameCounter = false
  private val pasToken = "YOUR_PAS_TOKEN"

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
    requestLayout()
    ViewCompat.setTranslationZ(this, 9999f)

    val videoDisplayComponent = brightcoveVideoView.videoDisplay as ExoPlayerVideoDisplayComponent
    videoDisplayComponent.setMediaStore(OfflineStoreManager.getInstance(context))

    val eventEmitter = brightcoveVideoView.eventEmitter
    eventEmitter.on(EventType.VIDEO_SIZE_KNOWN) {
      mediaController = brightcoveVideoView.brightcoveMediaController
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

  fun setPlaylistReferenceId(playlistReferenceId: String?) {
    if (playlistReferenceId == null) return
    this.playlistReferenceId = playlistReferenceId
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
    disableDefaultControl = disabled
    if (disabled) {
      mediaController?.hide()
      mediaController?.setShowHideTimeout(1)
    } else {
      mediaController?.show()
      mediaController?.setShowHideTimeout(controlTimeout)
    }
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
    setFullscreen(isFullscreen)
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
    if (accountId == null || policyKey == null || videoId == null) return

    val eventEmitter = brightcoveVideoView.getEventEmitter()

    catalog = OfflineCatalog.Builder(context, eventEmitter, accountId!!)
      .setBaseURL(Catalog.DEFAULT_EDGE_BASE_URL)
      .setPolicy(policyKey!!)
      .build()
      .apply {
        isMobileDownloadAllowed = true
        isMeteredDownloadAllowed = false
        isRoamingDownloadAllowed = false
      }

    catalog?.findAllVideoDownload(
      DownloadStatus.STATUS_COMPLETE,
      object : OfflineCallback<List<Video?>?> {
        override fun onSuccess(videos: List<Video?>?) {
          val video = videos?.find { it?.id == videoId }
          if (video == null) return
          playVideo(video)
        }

        override fun onFailure(throwable: Throwable) {
          Log.e(tag, "Error fetching all videos downloaded: ", throwable)
        }
      })

    // if (videoId != null) {
    //   catalog?.findVideoByID(videoId!!, object : VideoListener() {
    //     override fun onVideo(video: Video?) {
    //       playVideo(video)
    //     }
    //
    //     override fun onError(error: MutableList<CatalogError?>) {
    //       Log.e(tag, "onError catalog.findVideoByID $error")
    //     }
    //   })
    // }

    if (playlistReferenceId != null) {
      val httpRequestConfig = HttpRequestConfig
        .Builder()
        .setBrightcoveAuthorizationToken(pasToken)
        .build()

      catalog?.findPlaylistByReferenceID(
        playlistReferenceId!!,
        httpRequestConfig,
        object : PlaylistListener() {
          override fun onPlaylist(playlist: Playlist) {
            brightcoveVideoView.addAll(playlist.videos)
            if (autoPlay) brightcoveVideoView.start()
          }

          override fun onError(errors: List<CatalogError>) {
            super.onError(errors)
            Log.d(tag, "onError: $errors")
          }
        })
    }
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
          manuallyLayoutChildren()
          getViewTreeObserver().dispatchOnGlobalLayout()
          frameCounter = 1
        }
        if (!stopFrameCounter) {
          Choreographer.getInstance().postFrameCallback(this)
        }
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

  override fun onConfigurationChanged(configuration: Configuration) {
    super.onConfigurationChanged(configuration)
    if (configuration.orientation == Configuration.ORIENTATION_LANDSCAPE && !brightcoveVideoView.isFullScreen) {
      brightcoveVideoView.eventEmitter.emit(EventType.ENTER_FULL_SCREEN)
      return
    }
    if (configuration.orientation == Configuration.ORIENTATION_PORTRAIT && brightcoveVideoView.isFullScreen) {
      brightcoveVideoView.eventEmitter.emit(EventType.EXIT_FULL_SCREEN)
    }
  }

  override fun onHostResume() {
    if (autoPlay) play()
    toggleInViewPort(true)
    stopFrameCounter = false
    setupLayout()
    Log.d(tag, "onHostResume")
  }

  override fun onHostPause() {
    pause()
    toggleInViewPort(false)
    stopFrameCounter = true
    Log.d(tag, "onHostPause")
  }

  override fun onHostDestroy() {
    brightcoveVideoView.clear()
    removeAllViews()
    (context as ThemedReactContext).removeLifecycleEventListener(this)
    Log.d(tag, "onHostDestroy")
  }
}
