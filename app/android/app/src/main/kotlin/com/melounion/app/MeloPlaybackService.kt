package com.melounion.app

import android.content.Intent
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import org.json.JSONArray

class MeloPlaybackService : MediaSessionService() {
    private lateinit var player: ExoPlayer
    private var mediaSession: MediaSession? = null

    override fun onCreate() {
        super.onCreate()
        player = ExoPlayer.Builder(this).build()
        mediaSession = MediaSession.Builder(this, player).build()
        setStatus("idle")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        handleCommand(intent)
        return super.onStartCommand(intent, flags, startId)
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaSession? {
        return mediaSession
    }

    override fun onDestroy() {
        mediaSession?.release()
        mediaSession = null
        if (::player.isInitialized) {
            player.release()
        }
        setStatus("released")
        super.onDestroy()
    }

    private fun handleCommand(intent: Intent?) {
        when (intent?.action) {
            ACTION_LOAD_QUEUE -> loadQueue(
                itemsJson = intent.getStringExtra(EXTRA_ITEMS_JSON).orEmpty(),
                playWhenReady = intent.getBooleanExtra(EXTRA_PLAY_WHEN_READY, false),
            )

            ACTION_PLAY -> {
                player.play()
                setStatus("playing")
            }

            ACTION_PAUSE -> {
                player.pause()
                setStatus("paused")
            }

            ACTION_STOP -> {
                player.stop()
                setStatus("stopped")
                stopSelf()
            }

            ACTION_NEXT -> {
                if (player.hasNextMediaItem()) {
                    player.seekToNextMediaItem()
                    player.play()
                    setStatus("playing")
                }
            }

            ACTION_PREVIOUS -> {
                if (player.hasPreviousMediaItem()) {
                    player.seekToPreviousMediaItem()
                    player.play()
                    setStatus("playing")
                }
            }
        }
    }

    private fun loadQueue(itemsJson: String, playWhenReady: Boolean) {
        val items = parseMediaItems(itemsJson)
        if (items.isEmpty()) {
            player.clearMediaItems()
            setStatus("idle")
            return
        }

        player.setMediaItems(items, 0, 0L)
        player.prepare()
        if (playWhenReady) {
            player.play()
            setStatus("playing")
        } else {
            setStatus("ready")
        }
    }

    private fun parseMediaItems(itemsJson: String): List<MediaItem> {
        if (itemsJson.isBlank()) {
            return emptyList()
        }

        val items = mutableListOf<MediaItem>()
        val source = JSONArray(itemsJson)
        for (index in 0 until source.length()) {
            val item = source.getJSONObject(index)
            val uri = item.optString("mediaUri")
            if (uri.isBlank()) {
                continue
            }
            val title = item.optString("title")
            val artist = item.optString("artist")
            val providerId = item.optString("providerId")
            val trackId = item.optString("trackId")
            val mediaId = listOf(providerId, trackId).filter { it.isNotBlank() }.joinToString(":")

            val metadata = MediaMetadata.Builder()
                .setTitle(title)
                .setArtist(artist)
                .build()

            items += MediaItem.Builder()
                .setMediaId(mediaId.ifBlank { uri })
                .setUri(uri)
                .setMediaMetadata(metadata)
                .build()
        }
        return items
    }

    private fun setStatus(state: String) {
        updateStatus(
            mapOf(
                "state" to state,
                "mediaItemCount" to if (::player.isInitialized) player.mediaItemCount else 0,
                "currentIndex" to if (::player.isInitialized) player.currentMediaItemIndex else -1,
            ),
        )
    }

    companion object {
        const val CHANNEL_NAME = "melounion/playback"
        const val ACTION_LOAD_QUEUE = "com.melounion.app.playback.LOAD_QUEUE"
        const val ACTION_PLAY = "com.melounion.app.playback.PLAY"
        const val ACTION_PAUSE = "com.melounion.app.playback.PAUSE"
        const val ACTION_STOP = "com.melounion.app.playback.STOP"
        const val ACTION_NEXT = "com.melounion.app.playback.NEXT"
        const val ACTION_PREVIOUS = "com.melounion.app.playback.PREVIOUS"
        const val EXTRA_ITEMS_JSON = "itemsJson"
        const val EXTRA_PLAY_WHEN_READY = "playWhenReady"

        private val statusLock = Any()
        private var latestStatus: Map<String, Any?> = mapOf(
            "state" to "not_started",
            "mediaItemCount" to 0,
            "currentIndex" to -1,
        )

        fun statusSnapshot(): Map<String, Any?> = synchronized(statusLock) {
            HashMap(latestStatus)
        }

        private fun updateStatus(nextStatus: Map<String, Any?>) {
            synchronized(statusLock) {
                latestStatus = HashMap(nextStatus)
            }
        }
    }
}
