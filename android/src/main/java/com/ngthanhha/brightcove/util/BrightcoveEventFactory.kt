package com.ngthanhha.brightcove.util

import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class EventFactory(
  private val name: String,
  private val payload: WritableMap,
  surfaceId: Int,
  viewId: Int,
) : Event<EventFactory>(surfaceId, viewId) {
  override fun getEventName() = name
  override fun getEventData() = payload
}
