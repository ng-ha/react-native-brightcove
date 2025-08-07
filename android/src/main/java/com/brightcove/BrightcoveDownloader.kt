package com.brightcove

import android.text.format.Formatter
import android.util.Log
import com.brightcove.player.edge.Catalog
import com.brightcove.player.edge.OfflineCallback
import com.brightcove.player.edge.OfflineCatalog
import com.brightcove.player.edge.VideoListener
import com.brightcove.player.event.Event
import com.brightcove.player.event.EventEmitter
import com.brightcove.player.event.EventEmitterImpl
import com.brightcove.player.model.Video
import com.brightcove.player.network.DownloadStatus
import com.brightcove.player.network.HttpRequestConfig
import com.brightcove.player.offline.MediaDownloadable.DownloadEventListener
import com.brightcove.util.BrightcoveDownloadUtil
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import java.io.Serializable

class BrightcoveDownloader(val reactContext: ReactApplicationContext) :
  NativeBrightcoveDownloaderSpec(reactContext) {
  private val tag: String = "ng-ha:${this.javaClass.simpleName}"
  private var accountId: String? = null
  private var policyKey: String? = null
  private var pasToken = "YOUR_PAS_TOKEN"
  private var catalog: OfflineCatalog? = null

  override fun getName() = NAME

  override fun initModule(config: ReadableMap?) {
    val accountId = config?.getString("accountId")
    val policyKey = config?.getString("policyKey")
    if (accountId == null || policyKey == null) return
    this.accountId = accountId
    this.policyKey = policyKey

    val eventEmitter: EventEmitter = EventEmitterImpl()
    catalog = OfflineCatalog.Builder(reactContext, eventEmitter, accountId)
      .setBaseURL(Catalog.DEFAULT_EDGE_BASE_URL)
      .setPolicy(policyKey)
      .build()
      .apply {
        isMobileDownloadAllowed = true
        isMeteredDownloadAllowed = false
        isRoamingDownloadAllowed = false
      }
    catalog?.addDownloadEventListener(downloadEventListener)
  }

  override fun deinitModule() {
    catalog?.removeDownloadEventListener(downloadEventListener)
  }

  override fun invalidate() {
    catalog?.removeDownloadEventListener(downloadEventListener)
  }

  override fun getDownloadedVideos(promise: Promise?) {
    if (catalog == null) {
      promise?.reject("1", "Catalog is null")
      return
    }

    catalog?.findAllVideoDownload(
      DownloadStatus.STATUS_COMPLETE,
      object : OfflineCallback<List<Video?>?> {
        override fun onSuccess(videos: List<Video?>?) {
          val result = Arguments.createArray()
          videos?.forEach { video ->
            if (video == null) return@forEach
            val videoInfo = Arguments.createMap().apply {
              putString("id", video.id)
              putString("referenceId", video.referenceId)
              putString("name", video.name)
              putLong("duration", video.durationLong)
              putString("shortDescription", video.description)
              video.longDescription?.let { putString("longDescription", it) }
              video.thumbnail?.let { putString("thumbnailUri", it.toString()) }
              video.posterImage?.let { putString("posterUri", it.toString()) }
              video.licenseExpiryDate?.let { putString("licenseExpiryDate", it.toString()) }
              catalog?.estimateSize(video)?.let { putLong("size", it) }
            }
            result.pushMap(videoInfo)
          }
          Log.d(tag, "downloaded videos: $result")
          promise?.resolve(result)
        }

        override fun onFailure(throwable: Throwable) {
          Log.e(tag, "Error fetching downloaded videos: ", throwable)
          promise?.reject("2", "Error fetching downloaded videos", throwable)
        }
      })
  }

  override fun downloadVideo(id: String?) {
    if (id == null) return

    val httpRequestConfig = HttpRequestConfig
      .Builder()
      .setBrightcoveAuthorizationToken(pasToken)
      .build()

    catalog?.findVideoByID(id, httpRequestConfig, object : VideoListener() {
      override fun onVideo(video: Video?) {
        if (video == null) return
        catalog?.getMediaFormatTracksAvailable(video) { mediaDownloadable, bundle ->
          BrightcoveDownloadUtil.selectMediaFormatTracksAvailable(mediaDownloadable, bundle)
          catalog?.downloadVideo(video, object : OfflineCallback<DownloadStatus?> {
            override fun onSuccess(downloadStatus: DownloadStatus?) {}

            override fun onFailure(throwable: Throwable) {
              Log.e(tag, "Error initializing video download: ", throwable)
            }
          })
        }
      }
    })
  }

  override fun pauseVideoDownload(id: String?, promise: Promise?) {
    if (id == null || catalog == null) {
      promise?.reject("1", "ID or catalog is null")
      return
    }

    catalog?.pauseVideoDownload(id, object : OfflineCallback<Int?> {
      override fun onSuccess(status: Int?) {
        val payload = Arguments.createMap().apply { if (status != null) putInt("status", status) }
        promise?.resolve(payload)
      }

      override fun onFailure(throwable: Throwable) {
        promise?.reject("3", "Error pausing video download", throwable)
        Log.e(tag, "Error pausing video download: ", throwable)
      }
    })
  }

  override fun resumeVideoDownload(id: String?, promise: Promise?) {
    if (id == null || catalog == null) {
      promise?.reject("1", "ID or catalog is null")
      return
    }

    catalog?.resumeVideoDownload(id, object : OfflineCallback<Int?> {
      override fun onSuccess(status: Int?) {
        val payload = Arguments.createMap().apply { if (status != null) putInt("status", status) }
        promise?.resolve(payload)
      }

      override fun onFailure(throwable: Throwable) {
        promise?.reject("4", "Error resuming video download", throwable)
        Log.e(tag, "Error resuming video download: ", throwable)
      }
    })
  }

  override fun deleteVideo(id: String?, promise: Promise?) {
    if (id == null || catalog == null) {
      promise?.reject("1", "ID or catalog is null")
      return
    }

    catalog?.deleteVideo(id, object : OfflineCallback<Boolean?> {
      override fun onSuccess(result: Boolean?) {
        val payload =
          Arguments.createMap().apply { if (result != null) putBoolean("result", result) }
        promise?.resolve(payload)
      }

      override fun onFailure(throwable: Throwable) {
        promise?.reject("5", "Error deleting video", throwable)
        Log.e(tag, "Error deleting video: ", throwable)
      }
    })
  }

  private val downloadEventListener = object : DownloadEventListener {
    override fun onDownloadRequested(video: Video) {
      val payload = Arguments.createMap().apply { putString("id", video.id) }
      emitOnDownloadRequested(payload)
      Log.d(tag, "Starting to process ${video.name} video download request")
    }

    override fun onDownloadStarted(
      video: Video,
      estimatedSize: Long,
      mediaProperties: Map<String, Serializable>,
    ) {
      val payload = Arguments.createMap().apply {
        putString("id", video.id)
        putLong("estimatedSize", estimatedSize)
      }
      emitOnDownloadStarted(payload)
      Log.d(
        tag, String.format(
          "Started to download '%s' video. Estimated = %s, width = %s, height = %s, mimeType = %s",
          video.name,
          Formatter.formatFileSize(reactContext, estimatedSize),
          mediaProperties[Event.RENDITION_WIDTH],
          mediaProperties[Event.RENDITION_HEIGHT],
          mediaProperties[Event.RENDITION_MIME_TYPE]
        )
      )
    }

    override fun onDownloadProgress(video: Video, status: DownloadStatus) {
      val payload = Arguments.createMap().apply {
        putString("id", video.id)
        putLong("maxSize", status.maxSize)
        putLong("bytesDownloaded", status.bytesDownloaded)
        putDouble("progress", status.progress)
      }
      emitOnDownloadProgress(payload)
      Log.d(
        tag, String.format(
          "Downloaded %s out of %s of '%s' video. Progress %3.2f",
          Formatter.formatFileSize(reactContext, status.bytesDownloaded),
          Formatter.formatFileSize(reactContext, status.maxSize),
          video.name,
          status.progress
        )
      )
    }

    override fun onDownloadPaused(video: Video, status: DownloadStatus) {
      val payload = Arguments.createMap().apply {
        putString("id", video.id)
        putInt("reason", status.reason)
      }
      emitOnDownloadPaused(payload)
      Log.d(tag, "Paused download of '${video.name}' video: Reason #${status.reason}")
    }

    override fun onDownloadCompleted(video: Video, status: DownloadStatus) {
      val payload = Arguments.createMap().apply { putString("id", video.id) }
      emitOnDownloadCompleted(payload)
      Log.d(tag, "Successfully saved '${video.name}' video")
    }

    override fun onDownloadCanceled(video: Video) {
      val payload = Arguments.createMap().apply { putString("id", video.id) }
      emitOnDownloadCanceled(payload)
      Log.d(tag, "Cancelled download of '${video.name}' video removed")
    }

    override fun onDownloadDeleted(video: Video) {
      val payload = Arguments.createMap().apply { putString("id", video.id) }
      emitOnDownloadDeleted(payload)
      Log.d(tag, "Offline copy of '${video.name}' video removed")
    }

    override fun onDownloadFailed(video: Video, status: DownloadStatus) {
      val payload = Arguments.createMap().apply {
        putString("id", video.id)
        putInt("reason", status.reason)
      }
      emitOnDownloadFailed(payload)
      Log.e(tag, "Failed to download '${video.name}' video: Error #${status.reason}")
    }
  }

  companion object {
    const val NAME = "BrightcoveDownloader"
  }
}
