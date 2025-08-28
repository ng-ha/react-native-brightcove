package com.ngthanhha.brightcove.util

fun Map<String, Any?>.getInt(key: String): Int? = when (val value = this[key]) {
  is Int -> value
  is Long -> value.toInt()
  is Double -> value.toInt()
  is Float -> value.toInt()
  is String -> value.toIntOrNull()
  else -> null
}

