package aibeto.maple.audiotags

import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "aibeto.maple.audiotags/filepath"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getRealPathFromUri" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        val uri = Uri.parse(uriString)
                        val realPath = getRealPathFromURI(uri)
                        result.success(realPath)
                    } else {
                        result.error("NULL_URI", "URI is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun getRealPathFromURI(uri: Uri): String? {
        when {
            DocumentsContract.isDocumentUri(this, uri) -> {
                val docId = DocumentsContract.getDocumentId(uri)
                
                when {
                    uri.authority == "com.android.externalstorage.documents" -> {
                        val split = docId.split(":").toTypedArray()
                        val type = split[0]
                        if ("primary".equals(type, ignoreCase = true)) {
                            return context.getExternalFilesDir(null)?.absolutePath?.replace("/Android/data/${context.packageName}/files", "") + "/" + split[1]
                        }
                    }
                    // uri.authority == "com.android.providers.downloads.documents" -> {
                    //     val contentUri = android.net.Uri.parse("content://downloads/public_downloads")
                    //     return getDataColumn(contentUri, docId.toLong().toString())
                    // }
                    // uri.authority == "com.android.providers.media.documents" -> {
                    //     val split = docId.split(":").toTypedArray()
                    //     val type = split[0]
                    //     var contentUri: Uri? = null
                    //     when (type) {
                    //         "image" -> contentUri = android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                    //         "video" -> contentUri = android.provider.MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                    //         "audio" -> contentUri = android.provider.MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                    //     }
                    //     val selection = "_id=?"
                    //     // val selectionArgs = arrayOf(split[1])
                    //     return getDataColumn(contentUri, selection, selectionArgs)
                    // }
                }
            }
            "content".equals(uri.scheme, ignoreCase = true) -> {
                return getDataColumn(uri, null, null)
            }
            "file".equals(uri.scheme, ignoreCase = true) -> {
                return uri.path
            }
        }
        return null
    }
    
    private fun getDataColumn(uri: Uri?, selection: String?, selectionArgs: Array<String>?): String? {
        var cursor: android.database.Cursor? = null
        val column = "_data"
        val projection = arrayOf(column)
        
        try {
            cursor = context.contentResolver.query(uri!!, projection, selection, selectionArgs, null)
            if (cursor != null && cursor.moveToFirst()) {
                val columnIndex = cursor.getColumnIndexOrThrow(column)
                return cursor.getString(columnIndex)
            }
        } catch (e: Exception) {
            // Handle exception
        } finally {
            cursor?.close()
        }
        return null
    }
    
    // private val context: android.content.Context
    //     get() = this
}