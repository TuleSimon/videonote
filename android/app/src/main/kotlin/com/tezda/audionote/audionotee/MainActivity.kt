package com.tezda.audionote.audionotee

import io.flutter.embedding.android.FlutterActivity
//import android.util.Log
//import android.content.Context
//import android.os.Environment
//import androidx.annotation.NonNull
//import java.util.Calendar
//import com.arthenica.mobileffmpeg.FFmpeg
//import io.flutter.embedding.engine.plugins.FlutterPlugin
//import io.flutter.plugin.common.MethodCall
//import io.flutter.embedding.engine.FlutterEngine
//import io.flutter.plugins.GeneratedPluginRegistrant
//import io.flutter.plugin.common.MethodChannel
//import android.content.pm.PackageManager
//import androidx.core.app.ActivityCompat
//import androidx.core.content.ContextCompat
//import java.io.File

class MainActivity: FlutterActivity()
//    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
//        super.configureFlutterEngine(flutterEngine)
////        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
////            // This method is invoked on the main thread.
////                call, result ->
////            if (call.method == "video_cropping_plugin") {
////
////            }
////        }
//     //   GeneratedPluginRegistrant.registerWith(flutterEngine)
//
////        // Register the plugin manually
////        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "video_cropping_plugin")
////        channel.setMethodCallHandler(VideoCroppingPlugin())
//
//
//    }







//
//class VideoCroppingPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
//
//    private lateinit var context: Context
//
//    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
//        context = binding.applicationContext
//        val channel = MethodChannel(binding.binaryMessenger, "video_cropping_plugin")
//        channel.setMethodCallHandler(this)
//    }
//
//
//
//    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
//        if (call.method == "cropVideoToCircle") {
//            val inputPath = call.argument<String>("inputPath")!!
//            val name =         Calendar.getInstance().timeInMillis
//            val outputPath = getDCIMVideoPath("$name.mp4")
//            cropVideoToCircle(inputPath, outputPath, result)
//        } else {
//            result.notImplemented()
//        }
//    }
//
//
//    private fun getDCIMVideoPath(fileName: String): String {
//        val dcimDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM), "Videos")
//        if (!dcimDir.exists()) {
//            dcimDir.mkdirs()
//        }
//        return File(dcimDir, fileName).absolutePath
//    }
//
//    private fun cropVideoToCircle(inputPath: String, outputPath: String, result: MethodChannel.Result) {
//
//        Log.d("VideoCroppingPlugin", "c Path: $outputPath")
//        val antiAliasing=2
//        val maskFile = File(context.cacheDir, "mask.png")
//        if (!maskFile.exists()) {
//            context.assets.open("assets/mask.png").use { inputStream ->
//                maskFile.outputStream().use { outputStream ->
//                    inputStream.copyTo(outputStream)
//                }
//            }
//        }
//
//        val command = """
//            ffmpeg -i $inputPath -i ${maskFile.absolutePath} -filter_complex "[0]scale=400:400[ava];[1]alphaextract[alfa];[ava][alfa]alphamerge" $outputPath
//        """.trimIndent()
//
//        val rc = FFmpeg.execute(command)
//        if (rc == 0) {
//            result.success(outputPath)
//        } else {
//            result.error("CROP_ERROR", "Failed to crop video. Error code: $rc", null)
//        }
//    }
//
//    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}
//}
