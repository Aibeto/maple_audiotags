package aibeto.maple.audiotags

import android.net.Uri
import android.provider.DocumentsContract
import android.content.Intent
import android.database.Cursor
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
// import io.flutter.plugin.common.MethodResult

class MainActivity : FlutterActivity() {
    private val CHANNEL = "aibeto.maple.audiotags/filepath"
    // private var pendingResult: MethodResult? = null
    
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
                "selectMultipleAudioFiles" -> {
                    val maxFiles = call.argument<Int>("maxFiles") ?: 1000
                    // selectMultipleAudioFiles(maxFiles, result)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    // private fun selectMultipleAudioFiles(maxFiles: Int, result: MethodResult) {
        // pendingResult = result
        
    //     val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
    //         addCategory(Intent.CATEGORY_OPENABLE)
    //         type = "*/*" // 允许所有类型，后续会过滤音频文件
    //         putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
    //         putExtra(Intent.EXTRA_MIME_TYPES, arrayOf(
    //             "audio/mpeg", "audio/wav", "audio/flac", "audio/aac", "audio/ogg", "audio/mp4"
    //         ))
    //     }
        
    //     startActivityForResult(intent, 42)
    // }
    
    // override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    //     super.onActivityResult(requestCode, resultCode, data)
        
    //     if (requestCode == 42 && pendingResult != null) {
    //         try {
    //             // val result = pendingResult!!
    //             pendingResult = null
                
    //             if (resultCode == RESULT_OK && data != null) {
    //                 val files = mutableListOf<Map<String, String>>()
                    
    //                 // 处理单个或多个文件
    //                 val clipData = data.clipData
    //                 if (clipData != null) {
    //                     // 多个文件
    //                     for (i in 0 until clipData.itemCount) {
    //                         if (files.size >= 1000) break // 限制文件数量
                            
    //                         val uri = clipData.getItemAt(i).uri
    //                         val realPath = getRealPathFromURI(uri)
    //                         if (realPath != null) {
    //                             files.add(mapOf("path" to realPath))
    //                         }
    //                     }
    //                 } else {
    //                     // 单个文件
    //                     val uri = data.data
    //                     if (uri != null) {
    //                         val realPath = getRealPathFromURI(uri)
    //                         if (realPath != null) {
    //                             files.add(mapOf("path" to realPath))
    //                         }
    //                     }
    //                 }
                    
    //                 // result.success(files)
    //             } else {
    //                 // result.success(null)
    //             }
    //         } catch (e: Exception) {
    //             val result = pendingResult!!
    //             pendingResult = null
    //             // result.error("ERROR", e.message, null)
    //         }
    //     }
    // }
    
    private fun getRealPathFromURI(uri: Uri): String? {
        when {
            DocumentsContract.isDocumentUri(this, uri) -> {
                val docId = DocumentsContract.getDocumentId(uri)
                val split = docId.split(":").toTypedArray()
                
                when (uri.authority) {
                    "com.android.externalstorage.documents" -> {
                        // ExternalStorageProvider
                        val type = split[0]
                        if ("primary".equals(type, ignoreCase = true)) {
                            return "/storage/emulated/0/${split[1]}"
                        }
                    }
                    "com.android.providers.downloads.documents" -> {
                        // DownloadsProvider
                        val id = split[1]
                        val contentUri = android.net.Uri.parse("content://downloads/public_downloads")
                        return getDataColumn(contentUri, "_id=?", arrayOf(id))
                    }
                    "com.android.providers.media.documents" -> {
                        // MediaProvider
                        // val type = split[0]
                        // var contentUri: Uri? = null
                        // when (type) {
                        //     "image" -> contentUri = android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                        //     "video" -> contentUri = android.provider.MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                        //     "audio" -> contentUri = android.provider.MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                        // }
                        // val selection = "_id=?"
                        // // val selectionArgs = arrayOf(split[1])
                        // return getDataColumn(contentUri, selection, selectionArgs)
                    }
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
        var cursor: Cursor? = null
        val column = "_data"
        val projection = arrayOf(column)
        
        try {
            cursor = context.contentResolver.query(uri!!, projection, selection, selectionArgs, null)
            if (cursor != null && cursor.moveToFirst()) {
                val columnIndex = cursor.getColumnIndexOrThrow(column)
                return cursor.getString(columnIndex)
            }
        } catch (e: Exception) {
            // 忽略异常，返回null
        } finally {
            cursor?.close()
        }
        return null
    }
}