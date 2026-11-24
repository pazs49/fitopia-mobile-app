package com.example.fitopia

import android.content.ContentValues
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity: FlutterFragmentActivity() {
    private val channelName = "fitopia/file_downloads"

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)
            if (notificationManager.getNotificationChannel("fitopia_notifications") == null) {
                notificationManager.createNotificationChannel(
                    NotificationChannel(
                        "fitopia_notifications",
                        "Fitopia notifications",
                        NotificationManager.IMPORTANCE_DEFAULT
                    ).apply {
                        description = "Workout, nutrition, and account notifications"
                    }
                )
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "saveToDownloads") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val fileName = call.argument<String>("fileName")
                val bytes = call.argument<ByteArray>("bytes")
                if (fileName.isNullOrBlank() || bytes == null) {
                    result.error("INVALID_FILE", "A file name and bytes are required.", null)
                    return@setMethodCallHandler
                }

                try {
                    val savedLocation = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val values = ContentValues().apply {
                            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                            put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
                            put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                            put(MediaStore.Downloads.IS_PENDING, 1)
                        }
                        val resolver = contentResolver
                        val uri = resolver.insert(
                            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                            values
                        ) ?: throw IllegalStateException("Could not create the Downloads file.")
                        resolver.openOutputStream(uri)?.use { it.write(bytes) }
                            ?: throw IllegalStateException("Could not write the Downloads file.")
                        values.clear()
                        values.put(MediaStore.Downloads.IS_PENDING, 0)
                        resolver.update(uri, values, null, null)
                        uri.toString()
                    } else {
                        val downloads = Environment.getExternalStoragePublicDirectory(
                            Environment.DIRECTORY_DOWNLOADS
                        )
                        downloads.mkdirs()
                        val file = File(downloads, fileName)
                        FileOutputStream(file).use { it.write(bytes) }
                        file.absolutePath
                    }
                    result.success(savedLocation)
                } catch (error: Exception) {
                    result.error("SAVE_FAILED", error.message, null)
                }
            }
    }
}
