package com.brightcove

import com.facebook.react.BaseReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider
import com.facebook.react.uimanager.ViewManager

class BrightcoveViewPackage : BaseReactPackage() {
  override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
    return listOf(BrightcoveViewManager())
  }

  override fun getModule(name: String, reactContext: ReactApplicationContext): NativeModule? =
    when (name) {
      BrightcoveViewManager.NAME -> BrightcoveViewManager()
      BrightcoveDownloaderModule.NAME -> BrightcoveDownloaderModule(reactContext)
      else -> null
    }

  override fun getReactModuleInfoProvider(): ReactModuleInfoProvider = ReactModuleInfoProvider {
    mapOf(
      BrightcoveViewManager.NAME to ReactModuleInfo(
        name = BrightcoveViewManager.NAME,
        className = BrightcoveViewManager.NAME,
        canOverrideExistingModule = false,
        needsEagerInit = false,
        isCxxModule = false,
        isTurboModule = true,
      ),
      BrightcoveDownloaderModule.NAME to ReactModuleInfo(
        name = BrightcoveDownloaderModule.NAME,
        className = BrightcoveDownloaderModule.NAME,
        canOverrideExistingModule = false,
        needsEagerInit = false,
        isCxxModule = false,
        isTurboModule = true
      )
    )
  }
}
