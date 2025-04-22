import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Enable file upload support for Android
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      AndroidWebViewController.enableDebugging(true);
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {
            print('WebView Error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) async {
            print('Navigation Request: ${request.url}');
            // Handle file upload requests
            if (request.url.startsWith('file://')) {
              final status = await Permission.storage.request();
              if (status.isGranted) {
                return NavigationDecision.navigate;
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    // Enable file upload support
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      final androidController = controller.platform as AndroidWebViewController;
      
      // Configure file upload handling
      androidController.setOnShowFileSelector((FileSelectorParams params) async {
        print('File selector params: ${params.acceptTypes}');
        try {
          // Request storage permission
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            print('Storage permission denied');
            return [];
          }

          // Request camera permission as well
          final cameraStatus = await Permission.camera.request();
          if (!cameraStatus.isGranted) {
            print('Camera permission denied');
            return [];
          }

          // Initialize image picker
          final ImagePicker picker = ImagePicker();
          
          // Pick image with specific parameters
          final XFile? image = await picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1920,
            maxHeight: 1080,
            imageQuality: 85,
          );
          
          if (image != null) {
            final file = File(image.path);
            if (await file.exists()) {
              print('Selected file path: ${file.path}');
              print('File size: ${await file.length()} bytes');
              return [file.path];
            } else {
              print('Selected file does not exist');
            }
          } else {
            print('No image selected');
          }
        } catch (e, stackTrace) {
          print('Error picking file: $e');
          print('Stack trace: $stackTrace');
        }
        return [];
      });
    }

    return MaterialApp(
      title: 'WebView App',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Digit Recognition App'),
        ),
        body: WebViewWidget(
          controller: controller
            ..loadRequest(Uri.parse('https://hand-written-digit-recognition-pratham.streamlit.app/')),
        ),
      ),
    );
  }
}
