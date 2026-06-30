package com.melounion.app

import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKeys

class MainActivity : FlutterActivity() {
    private companion object {
        const val STORAGE_CHANNEL_NAME = "melo_union/storage"
        const val CREDENTIALS_CHANNEL_NAME = "melo_union/provider_credentials"
        const val PROVIDER_CREDENTIALS_PREFS = "melo_union_provider_credentials"
        const val NETEASE_COOKIE_KEY = "netease_cookie"
        const val NETEASE_USER_ID_KEY = "netease_user_id"
        const val QQ_MUSIC_COOKIE_KEY = "qq_music_cookie"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MeloPlaybackService.CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadQueue" -> {
                    startPlaybackService(
                        MeloPlaybackService.ACTION_LOAD_QUEUE,
                        call.argument<String>(MeloPlaybackService.EXTRA_ITEMS_JSON).orEmpty(),
                        call.argument<Boolean>(MeloPlaybackService.EXTRA_PLAY_WHEN_READY) ?: false,
                    )
                    result.success(true)
                }

                "play" -> {
                    startPlaybackService(MeloPlaybackService.ACTION_PLAY)
                    result.success(true)
                }

                "pause" -> {
                    startPlaybackService(MeloPlaybackService.ACTION_PAUSE)
                    result.success(true)
                }

                "stop" -> {
                    startPlaybackService(MeloPlaybackService.ACTION_STOP)
                    result.success(true)
                }

                "next" -> {
                    startPlaybackService(MeloPlaybackService.ACTION_NEXT)
                    result.success(true)
                }

                "previous" -> {
                    startPlaybackService(MeloPlaybackService.ACTION_PREVIOUS)
                    result.success(true)
                }

                "status" -> result.success(MeloPlaybackService.statusSnapshot())

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            STORAGE_CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getApplicationSupportDirectory" -> result.success(filesDir.absolutePath)
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CREDENTIALS_CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "readNeteaseCredentials" -> {
                    val prefs = getEncryptedPrefs()
                    val cookie = prefs.getString(NETEASE_COOKIE_KEY, null)
                    if (cookie.isNullOrBlank()) {
                        result.success(null)
                    } else {
                        result.success(
                            mapOf(
                                "cookie" to cookie,
                                "userId" to prefs.getString(NETEASE_USER_ID_KEY, null),
                            ),
                        )
                    }
                }

                "writeNeteaseCredentials" -> {
                    val cookie = call.argument<String>("cookie")
                    if (cookie.isNullOrBlank()) {
                        result.error("invalid_credentials", "NetEase cookie must not be empty.", null)
                        return@setMethodCallHandler
                    }
                    val userId = call.argument<String>("userId")
                    val editor = getEncryptedPrefs().edit()
                        .putString(NETEASE_COOKIE_KEY, cookie)
                    if (userId.isNullOrBlank()) {
                        editor.remove(NETEASE_USER_ID_KEY)
                    } else {
                        editor.putString(NETEASE_USER_ID_KEY, userId)
                    }
                    editor.apply()
                    result.success(true)
                }

                "deleteNeteaseCredentials" -> {
                    getEncryptedPrefs().edit()
                        .remove(NETEASE_COOKIE_KEY)
                        .remove(NETEASE_USER_ID_KEY)
                        .apply()
                    result.success(true)
                }

                "readQqMusicCredentials" -> {
                    val cookie = getEncryptedPrefs().getString(QQ_MUSIC_COOKIE_KEY, null)
                    if (cookie.isNullOrBlank()) {
                        result.success(null)
                    } else {
                        result.success(mapOf("cookie" to cookie))
                    }
                }

                "writeQqMusicCredentials" -> {
                    val cookie = call.argument<String>("cookie")
                    if (cookie.isNullOrBlank()) {
                        result.error("invalid_credentials", "QQ Music cookie must not be empty.", null)
                        return@setMethodCallHandler
                    }
                    getEncryptedPrefs().edit()
                        .putString(QQ_MUSIC_COOKIE_KEY, cookie)
                        .apply()
                    result.success(true)
                }

                "deleteQqMusicCredentials" -> {
                    getEncryptedPrefs().edit()
                        .remove(QQ_MUSIC_COOKIE_KEY)
                        .apply()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun getEncryptedPrefs(): SharedPreferences {
        return try {
            val masterKeyAlias = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC)
            EncryptedSharedPreferences.create(
                PROVIDER_CREDENTIALS_PREFS,
                masterKeyAlias,
                applicationContext,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (e: Exception) {
            try {
                val sharedPrefsFile = java.io.File(filesDir.parent, "shared_prefs/$PROVIDER_CREDENTIALS_PREFS.xml")
                if (sharedPrefsFile.exists()) {
                    sharedPrefsFile.delete()
                }
            } catch (ignored: Exception) {}
            val masterKeyAlias = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC)
            EncryptedSharedPreferences.create(
                PROVIDER_CREDENTIALS_PREFS,
                masterKeyAlias,
                applicationContext,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        }
    }

    private fun startPlaybackService(
        action: String,
        itemsJson: String? = null,
        playWhenReady: Boolean? = null,
    ) {
        val intent = Intent(this, MeloPlaybackService::class.java).setAction(action)
        if (itemsJson != null) {
            intent.putExtra(MeloPlaybackService.EXTRA_ITEMS_JSON, itemsJson)
        }
        if (playWhenReady != null) {
            intent.putExtra(MeloPlaybackService.EXTRA_PLAY_WHEN_READY, playWhenReady)
        }
        startService(intent)
    }
}
