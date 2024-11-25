import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ImagePicker imagePicker = ImagePicker();
  String? imagePath;
  List<Map<String, dynamic>> textElements = [];
  Image? image;

  Future<Map<String, double>> getImageDimensions(String imagePath) async {
    final file = File(imagePath);
    final image = await decodeImageFromList(await file.readAsBytes());

    return {
      'width': image.width.toDouble(),
      'height': image.height.toDouble(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              imagePath != null
                  ? Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: FutureBuilder<Map<String, double>>(
                    future: getImageDimensions(imagePath!),
                    builder: (context, snapshot) {
                      final imageWidth = snapshot.data?['width'];
                      final imageHeight = snapshot.data?['height'];

                      return Stack(
                        children: [
                          Container(
                            width: MediaQuery.sizeOf(context).width / 1.2,
                            height: MediaQuery.sizeOf(context).height / 1.3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32.0),
                            ),
                            child: Image.file(
                              imagePath != null
                                  ? File(imagePath!)
                                  : File(""),
                              fit: BoxFit.fill,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14.0),
                            child: Container(
                              width: MediaQuery.sizeOf(context).width / 1.2,
                              height: MediaQuery.sizeOf(context).height / 1.3,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32.0),
                                color: Colors.black26,
                              ),
                            ),
                          ),
                          ...textElements.map((element) {
                            final scaledRect = scaleRect(
                              rect: element["boundingBox"],
                              imageWidth: imageWidth!,
                              imageHeight: imageHeight!,
                              displayedImageWidth:
                              MediaQuery.sizeOf(context).width / 1.2,
                              displayedImageHeight:
                              MediaQuery.sizeOf(context).height / 1.3,
                            );

                            return Positioned(
                              left: scaledRect.left,
                              top: scaledRect.top,
                              width: scaledRect.width,
                              height: scaledRect.height,
                              child: Container(
                                decoration: BoxDecoration(
                                  // border: Border.all(
                                  //     color: Colors.black54, width: 1),
                                  color: Colors.white70,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                  child: SelectableText(
                                    // showCursor: true,
                                    element["text"],
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      height: 1.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList()
                        ],
                      );
                    }),
                  )
                  : const SizedBox.shrink(),
              ElevatedButton(
                onPressed: () async {
                  final pickedFile =
                  await imagePicker.pickImage(source: ImageSource.gallery);

                  setState(() {
                    imagePath = pickedFile?.path;
                  });

                  if (pickedFile != null) {
                    final InputImage inputImage =
                    InputImage.fromFilePath(pickedFile.path);

                    final textRecognizer =
                    TextRecognizer(script: TextRecognitionScript.latin);

                    final RecognizedText recognizedText =
                    await textRecognizer.processImage(inputImage);

                    for (TextBlock block in recognizedText.blocks) {
                      for (TextLine line in block.lines) {
                        textElements.add({
                          "text": line.text,
                          "boundingBox": line.boundingBox,
                        });
                      }
                    }

                    setState(() {

                    });
                  }
                },
                child: Text(imagePath != null ? "Change Image" : "Select Image"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Rect scaleRect({
  required Rect rect,
  required double imageWidth,
  required double imageHeight,
  required double displayedImageWidth,
  required double displayedImageHeight,
}) {
  final double scaleX = displayedImageWidth / imageWidth;
  final double scaleY = displayedImageHeight / imageHeight;

  final scaledRect = Rect.fromLTRB(
    rect.left * scaleX,
    rect.top * scaleY,
    rect.right * scaleX,
    rect.bottom * scaleY,
  );

  return scaledRect.inflate(4.0);
}
