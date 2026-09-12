 import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';



import 'services/api_service.dart';

void main() {
  runApp(const CropDiseaseApp());
}

class CropDiseaseApp extends StatelessWidget {
  const CropDiseaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Crop Disease Detection',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? selectedImage;

  final ImagePicker picker = ImagePicker();

  bool isLoading = false;

  String result = "";

  // Camera
  Future<void> captureImage() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
    );

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });

      await sendImageToServer();
    }
  }

  // Gallery
  Future<void> uploadImage() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });

      await sendImageToServer();
    }
  }

Future<void> sendImageToServer() async {
  if (selectedImage == null) return;

  setState(() {
    isLoading = true;
    result = "";
  });

  try {
    final response = await ApiService.uploadImage(
  selectedImage!,
);

final prediction = """
✅ Prediction Complete

🌿 Disease : ${response["disease"]}

🎯 Confidence : ${response["confidence"]}%

💊 Treatment :
${response["treatment"]}
""";


if (!mounted) return;

setState(() {
  result = prediction;
});

    ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text("Prediction Complete"),
    backgroundColor: Colors.green,
  ),
);
  } catch (e) {
    print("UPLOAD ERROR: $e");

    if (!mounted) return;

    setState(() {
      result = "Error:\n$e";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.toString(),
          maxLines: 5,
        ),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Crop Disease Detection"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              const Icon(
                Icons.agriculture,
                size: 100,
                color: Colors.green,
              ),

              const SizedBox(height: 20),

              const Text(
                "Welcome Farmer!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green),
                ),
                child: selectedImage == null
                    ? const Center(
                        child: Text(
                          "No Image Selected",
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : Image.file(
                        selectedImage!,
                        fit: BoxFit.cover,
                      ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: captureImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text(
                    "Capture Image",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: uploadImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text(
                    "Upload Image",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              if (isLoading)
                const CircularProgressIndicator(),

              const SizedBox(height: 20),

              Container(
  width: double.infinity,
  padding: const EdgeInsets.all(15),
  decoration: BoxDecoration(
    color: Colors.green.shade50,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: Colors.green),
  ),
  child: SelectableText(
    result,
    style: const TextStyle(
      fontSize: 18,
      color: Colors.black,
      height: 1.5,
    ),
  ),
),
            ],  
          ),
        ),
      ),
    );
  }
}