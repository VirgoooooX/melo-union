package com.melounion.app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKeys
import com.ryanheise.audioservice.AudioServiceActivity
import kotlin.math.abs

class MainActivity : AudioServiceActivity() {
    private companion object {
        const val STORAGE_CHANNEL_NAME = "melo_union/storage"
        const val CREDENTIALS_CHANNEL_NAME = "melo_union/provider_credentials"
        const val NOTIFICATIONS_CHANNEL_NAME = "melo_union/notifications"
        const val POST_NOTIFICATIONS_REQUEST_CODE = 2407
        const val PROVIDER_CREDENTIALS_PREFS = "melo_union_provider_credentials"
        const val NETEASE_COOKIE_KEY = "netease_cookie"
        const val NETEASE_USER_ID_KEY = "netease_user_id"
        const val QQ_MUSIC_COOKIE_KEY = "qq_music_cookie"
        const val KUGOU_SESSION_KEY = "kugou_session"
        const val WEBDAV_URL_KEY = "webdav_url"
        const val WEBDAV_USERNAME_KEY = "webdav_username"
        const val WEBDAV_PASSWORD_KEY = "webdav_password"
        const val WEBDAV_REMOTE_DIRECTORY_KEY = "webdav_remote_directory"
    }

    private var pendingNotificationPermissionResult: Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        preferHighRefreshRate()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (requestCode == POST_NOTIFICATIONS_REQUEST_CODE) {
            pendingNotificationPermissionResult?.success(
                grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED,
            )
            pendingNotificationPermissionResult = null
            return
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATIONS_CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPostNotifications" -> requestPostNotifications(result)
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
                    if (editor.commit()) {
                        result.success(true)
                    } else {
                        result.error("storage_error", "Failed to write NetEase credentials.", null)
                    }
                }

                "deleteNeteaseCredentials" -> {
                    val ok = getEncryptedPrefs().edit()
                        .remove(NETEASE_COOKIE_KEY)
                        .remove(NETEASE_USER_ID_KEY)
                        .commit()
                    if (ok) {
                        result.success(true)
                    } else {
                        result.error("storage_error", "Failed to delete NetEase credentials.", null)
                    }
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
                    val ok = getEncryptedPrefs().edit()
                        .putString(QQ_MUSIC_COOKIE_KEY, cookie)
                        .commit()
                    if (ok) {
                        result.success(true)
                    } else {
                        result.error("storage_error", "Failed to write QQ Music credentials.", null)
                    }
                }

                "deleteQqMusicCredentials" -> {
                    val ok = getEncryptedPrefs().edit()
                        .remove(QQ_MUSIC_COOKIE_KEY)
                        .commit()
                    if (ok) {
                        result.success(true)
                    } else {
                        result.error("storage_error", "Failed to delete QQ Music credentials.", null)
                    }
                }

                "readKugouCredentials" -> {
                    val session = getEncryptedPrefs().getString(KUGOU_SESSION_KEY, null)
                    if (session.isNullOrBlank()) {
                        result.success(null)
                    } else {
                        result.success(mapOf("session" to session))
                    }
                }

                "writeKugouCredentials" -> {
                    val session = call.argument<String>("session")
                    if (session.isNullOrBlank()) {
                        result.error("invalid_credentials", "Kugou session must not be empty.", null)
                        return@setMethodCallHandler
                    }
                    val ok = getEncryptedPrefs().edit()
                        .putString(KUGOU_SESSION_KEY, session)
                        .commit()
                    if (ok) {
                        result.success(true)
                    } else {
                        result.error("storage_error", "Failed to write Kugou credentials.", null)
                    }
                }

                "deleteKugouCredentials" -> {
                    val ok = getEncryptedPrefs().edit()
                        .remove(KUGOU_SESSION_KEY)
                        .commit()
                    if (ok) {
                        result.success(true)
                    } else {
                        result.error("storage_error", "Failed to delete Kugou credentials.", null)
                    }
                }

                "readWebDavConfig" -> {
                    val prefs = getEncryptedPrefs()
                    val url = prefs.getString(WEBDAV_URL_KEY, null)
                    val username = prefs.getString(WEBDAV_USERNAME_KEY, null)
                    val password = prefs.getString(WEBDAV_PASSWORD_KEY, null)
                    if (url.isNullOrBlank() || username.isNullOrBlank() || password.isNullOrEmpty()) {
                        result.success(null)
                    } else {
                        result.success(
                            mapOf(
                                "url" to url,
                                "username" to username,
                                "password" to password,
                                "remoteDirectory" to prefs.getString(WEBDAV_REMOTE_DIRECTORY_KEY, "/MeloUnion/backups/"),
                            ),
                        )
                    }
                }

                "writeWebDavConfig" -> {
                    val url = call.argument<String>("url")
                    val username = call.argument<String>("username")
                    val password = call.argument<String>("password")
                    val remoteDirectory = call.argument<String>("remoteDirectory")
                    if (url.isNullOrBlank() || username.isNullOrBlank() || password.isNullOrEmpty()) {
                        result.error("invalid_webdav_config", "WebDAV URL, username and password are required.", null)
                        return@setMethodCallHandler
                    }
                    getEncryptedPrefs().edit()
                        .putString(WEBDAV_URL_KEY, url)
                        .putString(WEBDAV_USERNAME_KEY, username)
                        .putString(WEBDAV_PASSWORD_KEY, password)
                        .putString(
                            WEBDAV_REMOTE_DIRECTORY_KEY,
                            if (remoteDirectory.isNullOrBlank()) "/MeloUnion/backups/" else remoteDirectory,
                        )
                        .apply()
                    result.success(true)
                }

                "deleteWebDavConfig" -> {
                    getEncryptedPrefs().edit()
                        .remove(WEBDAV_URL_KEY)
                        .remove(WEBDAV_USERNAME_KEY)
                        .remove(WEBDAV_PASSWORD_KEY)
                        .remove(WEBDAV_REMOTE_DIRECTORY_KEY)
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

    private fun requestPostNotifications(result: Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }

        pendingNotificationPermissionResult?.success(false)
        pendingNotificationPermissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            POST_NOTIFICATIONS_REQUEST_CODE,
        )
    }

    @Suppress("DEPRECATION")
    private fun preferHighRefreshRate() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return

        val supportedModes = windowManager.defaultDisplay.supportedModes
        val preferredMode = supportedModes
            .filter { it.refreshRate >= 90f }
            .minByOrNull { abs(it.refreshRate - 120f) }
            ?: return

        val attributes = window.attributes
        attributes.preferredDisplayModeId = preferredMode.modeId
        window.attributes = attributes
    }
}
