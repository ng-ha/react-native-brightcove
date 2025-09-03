package com.ngthanhha.brightcove.util

import android.content.res.Configuration
import android.util.Log
import com.brightcove.player.pictureinpicture.PictureInPictureManager
import com.brightcove.player.pictureinpicture.PictureInPictureManagerException

class PictureInPictureUtil {
  companion object {
    private val tag: String = "ng-ha:${PictureInPictureUtil::class.java.simpleName}"

    fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
      PictureInPictureManager.getInstance()
        .onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
    }

    fun onUserLeaveHint() {
      if (!PictureInPictureManager.getInstance().isPictureInPictureEnabled) return
      try {
        PictureInPictureManager.getInstance().onUserLeaveHint()
      } catch (e: PictureInPictureManagerException) {
        Log.e(tag, "onUserLeaveHint failed", e)
      }
    }
  }
}
