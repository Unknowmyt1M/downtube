package com.downtube.downtube

import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import com.yausername.youtubedl_android.YoutubeDLException
import com.yausername.ffmpeg.FFmpeg
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

class MainActivity : FlutterActivity() {
    private val shareChannelName = "com.downtube.downtube/share_intent"
    private val ytdlpChannelName = "com.downtube.downtube/ytdlp"
    private var sharedText: String? = null
    private var isInitialized = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Capture initial share intent if present
        handleSendIntent(intent)

        // Share intent channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, shareChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedText" -> {
                    val text = sharedText
                    sharedText = null // Consume single-use
                    result.success(text)
                }
                else -> result.notImplemented()
            }
        }

        // yt-dlp & FFmpeg native engine channel
        val ytdlpChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ytdlpChannelName)
        ytdlpChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "init" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            if (!isInitialized) {
                                YoutubeDL.getInstance().init(applicationContext)
                                FFmpeg.getInstance().init(applicationContext)
                                isInitialized = true
                            }
                            withContext(Dispatchers.Main) {
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("INIT_FAILED", e.message, null)
                            }
                        }
                    }
                }
                "download" -> {
                    val url = call.argument<String>("url") ?: run {
                        result.error("INVALID_URL", "URL cannot be null", null)
                        return@setMethodCallHandler
                    }
                    val processId = call.argument<String>("processId") ?: System.currentTimeMillis().toString()
                    val outputDir = call.argument<String>("outputDir") ?: applicationContext.filesDir.absolutePath
                    val format = call.argument<String>("format") ?: "best"

                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            if (!isInitialized) {
                                YoutubeDL.getInstance().init(applicationContext)
                                FFmpeg.getInstance().init(applicationContext)
                                isInitialized = true
                            }

                            val dir = File(outputDir)
                            if (!dir.exists()) dir.mkdirs()

                            val request = YoutubeDLRequest(url).apply {
                                addOption("-o", "$outputDir/%(title)s.%(ext)s")
                                addOption("-f", format)
                                addOption("--no-mtime")
                            }

                            val response = YoutubeDL.getInstance().execute(request, processId) { progress, etaInSeconds, line ->
                                Handler(Looper.getMainLooper()).post {
                                    ytdlpChannel.invokeMethod("onProgress", mapOf(
                                        "processId" to processId,
                                        "progress" to progress.toDouble(),
                                        "eta" to etaInSeconds,
                                        "log" to line
                                    ))
                                }
                            }

                            withContext(Dispatchers.Main) {
                                result.success(mapOf(
                                    "processId" to processId,
                                    "output" to response.out,
                                    "elapsedTime" to response.elapsedTime
                                ))
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("DOWNLOAD_FAILED", e.message, null)
                            }
                        }
                    }
                }
                "cancel" -> {
                    val processId = call.argument<String>("processId") ?: ""
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            YoutubeDL.getInstance().destroyProcessById(processId)
                            withContext(Dispatchers.Main) {
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("CANCEL_FAILED", e.message, null)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleSendIntent(intent)
        val text = sharedText
        if (text != null) {
            flutterEngine?.let {
                MethodChannel(it.dartExecutor.binaryMessenger, shareChannelName).invokeMethod("onSharedText", text)
                sharedText = null
            }
        }
    }

    private fun handleSendIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_SEND && intent.type?.startsWith("text/") == true) {
            sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
        }
    }
}
