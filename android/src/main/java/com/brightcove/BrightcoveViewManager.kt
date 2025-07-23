package com.brightcove

import android.graphics.Color
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.BrightcoveViewManagerInterface
import com.facebook.react.viewmanagers.BrightcoveViewManagerDelegate

@ReactModule(name = BrightcoveViewManager.NAME)
class BrightcoveViewManager : SimpleViewManager<BrightcoveView>(),
  BrightcoveViewManagerInterface<BrightcoveView> {
  private val mDelegate: ViewManagerDelegate<BrightcoveView>

  init {
    mDelegate = BrightcoveViewManagerDelegate(this)
  }

  override fun getDelegate(): ViewManagerDelegate<BrightcoveView>? {
    return mDelegate
  }

  override fun getName(): String {
    return NAME
  }

  public override fun createViewInstance(context: ThemedReactContext): BrightcoveView {
    return BrightcoveView(context)
  }

  @ReactProp(name = "color")
  override fun setColor(view: BrightcoveView?, color: String?) {
    view?.setBackgroundColor(Color.parseColor(color))
  }

  companion object {
    const val NAME = "BrightcoveView"
  }
}
