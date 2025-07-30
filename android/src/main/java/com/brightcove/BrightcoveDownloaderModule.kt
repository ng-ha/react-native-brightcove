package com.brightcove

import android.text.format.Formatter
import android.util.Log
import com.brightcove.player.display.ExoPlayerVideoDisplayComponent
import com.brightcove.player.edge.Catalog
import com.brightcove.player.edge.CatalogError
import com.brightcove.player.edge.OfflineCallback
import com.brightcove.player.edge.OfflineCatalog
import com.brightcove.player.edge.OfflineStoreManager
import com.brightcove.player.edge.PlaylistListener
import com.brightcove.player.event.Event
import com.brightcove.player.event.EventEmitter
import com.brightcove.player.event.EventEmitterImpl
import com.brightcove.player.model.Playlist
import com.brightcove.player.model.Video
import com.brightcove.player.network.ConnectivityMonitor
import com.brightcove.player.network.DownloadStatus
import com.brightcove.player.network.HttpRequestConfig
import com.brightcove.player.offline.MediaDownloadable.DownloadEventListener
import com.brightcove.player.view.BrightcoveExoPlayerVideoView
import com.brightcove.player.view.BrightcovePlayer.TAG
import com.facebook.react.bridge.ReactApplicationContext
import java.io.Serializable

class BrightcoveDownloaderModule(val reactContext: ReactApplicationContext) :
  NativeBrightcoveDownloaderSpec(reactContext) {
  private val tag: String = "ng-ha:${this.javaClass.getSimpleName()}"
  private lateinit var catalog: OfflineCatalog
  private var connectivityMonitor: ConnectivityMonitor? = null
  private lateinit var httpRequestConfig: HttpRequestConfig
  private val pasToken = "YOUR_PAS_TOKEN"

  override fun getName() = NAME

  private val connectivityListener = ConnectivityMonitor.Listener { _, _ -> updateVideoList() }

  init {
    ConnectivityMonitor.getInstance(reactContext).addListener(connectivityListener)
    // catalog.addDownloadEventListener(downloadEventListener)
  }

  override fun downloadVideo(id: String?) {
    Log.d(tag, "downloadVideo $id")

    connectivityMonitor = ConnectivityMonitor.getInstance(reactContext)

    val eventEmitter: EventEmitter = EventEmitterImpl()

    catalog = OfflineCatalog.Builder(reactContext, eventEmitter, "5420904993001")
      .setBaseURL(Catalog.DEFAULT_EDGE_BASE_URL)
      .setPolicy("BCpkADawqM1RJu5c_I13hBUAi4c8QNWO5QN2yrd_OgDjTCVsbILeGDxbYy6xhZESTFi68MiSUHzMbQbuLV3q-gvZkJFpym1qYbEwogOqKCXK622KNLPF92tX8AY9a1cVVYCgxSPN12pPAuIM")
      .build()

    // Configure downloads through the catalog.
    catalog.isMobileDownloadAllowed = true
    catalog.isMeteredDownloadAllowed = false
    catalog.isRoamingDownloadAllowed = false

  }

  private fun updateVideoList() {

    // if (connectivityMonitor?.isConnected == true) {
    //
    //
    //   val httpRequestConfigBuilder = HttpRequestConfig.Builder()
    //   httpRequestConfigBuilder.setBrightcoveAuthorizationToken(pasToken)
    //   httpRequestConfig = httpRequestConfigBuilder.build()
    //   playlist.findPlaylist(catalog, httpRequestConfig, object : PlaylistListener() {
    //     override fun onPlaylist(playlist: Playlist) {
    //       onVideoListUpdated(false)
    //       brightcoveVideoView.addAll(playlist.videos)
    //     }
    //
    //     override fun onError(errors: List<CatalogError>) {
    //       super.onError(errors)
    //     }
    //   })
    // } else {
    //   catalog.findAllVideoDownload(
    //     DownloadStatus.STATUS_COMPLETE,
    //     object : OfflineCallback<List<Video?>?> {
    //       override fun onSuccess(videos: List<Video?>?) {
    //         onVideoListUpdated(false)
    //         brightcoveVideoView.clear()
    //         brightcoveVideoView.addAll(videos)
    //       }
    //
    //       override fun onFailure(throwable: Throwable) {
    //         Log.e(TAG, "Error fetching all videos downloaded: ", throwable)
    //       }
    //     })
    // }
  }


  private val downloadEventListener: DownloadEventListener = object : DownloadEventListener {
    override fun onDownloadRequested(video: Video) {
      Log.i(TAG, "Starting to process ${video.name} video download request")
    }

    override fun onDownloadStarted(
      video: Video,
      estimatedSize: Long,
      mediaProperties: Map<String, Serializable>,
    ) {
      val message = "Started to download '${video.name}' video. Estimated = ${
        Formatter.formatFileSize(
          reactContext,
          estimatedSize
        )
      }, width = ${mediaProperties[Event.RENDITION_WIDTH]}, height = ${mediaProperties[Event.RENDITION_HEIGHT]}, mimeType = ${mediaProperties[Event.RENDITION_MIME_TYPE]}"
      Log.i(TAG, message)
    }

    override fun onDownloadProgress(video: Video, status: DownloadStatus) {
      Log.i(
        TAG, String.format(
          "Downloaded %s out of %s of '%s' video. Progress %3.2f",
          Formatter.formatFileSize(reactContext, status.bytesDownloaded),
          Formatter.formatFileSize(reactContext, status.maxSize),
          video.name, status.progress
        )
      )
    }

    override fun onDownloadPaused(video: Video, status: DownloadStatus) {
      Log.i(TAG, "Paused download of '${video.name}' video: Reason #${status.reason}")
    }

    override fun onDownloadCompleted(video: Video, status: DownloadStatus) {
      val message = "Successfully saved '${video.name}' video"
      Log.i(TAG, message)
    }

    override fun onDownloadCanceled(video: Video) {
      // No need to update UI here because it will be handled by the deleteVideo method.
      val message = "Cancelled download of '${video.name}' video removed"
      Log.i(TAG, message)
    }

    override fun onDownloadDeleted(video: Video) {
      // No need to update UI here because it will be handled by the deleteVideo method.
      val message = "Offline copy of '${video.name}' video removed"
      Log.i(TAG, message)
    }

    override fun onDownloadFailed(video: Video, status: DownloadStatus) {
      val message = "Failed to download '${video.name}' video: Error #${status.reason}"
      Log.e(TAG, message)
    }
  }

  private fun onDownloadRemoved(video: Video) {
    // if (connectivityMonitor?.isConnected == true) {
    //   // Fetch the video object again to avoid using the given video that may have been
    //   // tainted by previous download.
    //   catalog.findVideoByID(video.id, object : FindVideoListener(video) {
    //     override fun onVideo(newVideo: Video) {
    //     }
    //   })
    // } else {
    //   onVideoListUpdated(false)
    // }
  }

  override fun pauseVideoDownload(id: String?) {
    Log.d(tag, "pauseVideoDownload $id")
  }

  override fun resumeVideoDownload(id: String?) {
    Log.d(tag, "resumeVideoDownload $id")
  }

  override fun deleteVideo(id: String?) {
    Log.d(tag, "deleteVideo $id")
  }

  companion object {
    const val NAME = "NativeBrightcoveDownloader"
  }
}
