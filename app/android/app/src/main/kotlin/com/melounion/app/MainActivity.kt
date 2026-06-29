package com.melounion.app

import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
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
