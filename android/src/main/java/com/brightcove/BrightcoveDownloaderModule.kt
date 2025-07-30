package com.brightcove

import android.util.Log
import com.facebook.react.bridge.ReactApplicationContext

class BrightcoveDownloaderModule(reactContext: ReactApplicationContext) :
  NativeBrightcoveDownloaderSpec(reactContext) {
  private val tag: String = "ng-ha:${this.javaClass.getSimpleName()}"

  override fun getName() = NAME

  override fun downloadVideo(id: String?) {
    Log.d(tag, "downloadVideo $id")
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
