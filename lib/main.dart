import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'services/api_service.dart';

void main() {
  runApp(const CropCareAI());
}

// ============================================================
// APP
// ============================================================

class CropCareAI extends StatelessWidget {
  const CropCareAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CropCare AI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F8F5),
      ),
      home: const HomePage(),
    );
  }
}

// ============================================================
// HOME PAGE
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? selectedImage;

  final ImagePicker picker = ImagePicker();

  bool isLoading = false;

  Map<String, dynamic>? predictionData;

  String? errorMessage;

  // ==========================================================
  // CAMERA
  // ==========================================================

 Future<void> captureImage() async {
  try {
    debugPrint("CAMERA: Opening camera...");

    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );

    debugPrint("CAMERA: Returned from camera");

    if (image == null) {
      debugPrint("CAMERA: image == null");
      return;
    }

    debugPrint("CAMERA PATH: ${image.path}");

    final File file = File(image.path);

    // Wait until the captured file is actually available.
    int attempts = 0;

    while (!await file.exists() && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }

    if (!await file.exists()) {
      debugPrint("CAMERA: File does not exist");
      showError("Captured photo could not be loaded. Please try again.");
      return;
    }

    debugPrint("CAMERA: File exists");

    if (!mounted) return;

    setState(() {
      selectedImage = file;
      predictionData = null;
      errorMessage = null;
    });

    debugPrint("CAMERA: Image displayed successfully");
  } catch (e, stackTrace) {
    debugPrint("CAMERA ERROR: $e");
    debugPrint("$stackTrace");

    if (!mounted) return;

    showError(
      "Camera error. Please try taking the photo again.",
    );
  }
}
  // ==========================================================
  // GALLERY
  // ==========================================================

  Future<void> uploadImage() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image == null) return;

      final file = File(image.path);

      if (!await file.exists()) {
        showError("Selected image could not be loaded.");
        return;
      }

      if (!mounted) return;

      setState(() {
        selectedImage = file;
        predictionData = null;
        errorMessage = null;
        isLoading = false;
      });
    } catch (e) {
      print("GALLERY ERROR: $e");

      showError(
        "Unable to open gallery.\n"
        "Please try again.",
      );
    }
  }

  // ==========================================================
  // SEND IMAGE TO SERVER
  // ==========================================================

  Future<void> sendImageToServer() async {
    if (selectedImage == null) return;

    setState(() {
      isLoading = true;
      predictionData = null;
      errorMessage = null;
    });

    try {
      final response = await ApiService.uploadImage(
        selectedImage!,
      );

      if (!mounted) return;

      setState(() {
        predictionData = response;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Analysis completed successfully."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print("UPLOAD ERROR: $e");

      if (!mounted) return;

      setState(() {
        errorMessage =
            "We couldn't analyze this image.\n"
            "Please check your connection and try again.";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Unable to connect to the AI server.",
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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

  // ==========================================================
  // RESET
  // ==========================================================

  void resetScan() {
    setState(() {
      selectedImage = null;
      predictionData = null;
      errorMessage = null;
      isLoading = false;
    });
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  void showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================================
  // CONFIDENCE
  // ==========================================================

  double getConfidence() {
    if (predictionData == null) return 0;

    final value = predictionData!["confidence"];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  String getConfidenceLevel(double confidence) {
    if (confidence >= 90) {
      return "High Confidence";
    }

    if (confidence >= 70) {
      return "Moderate Confidence";
    }

    return "Low Confidence";
  }

  Color getConfidenceColor(double confidence) {
    if (confidence >= 90) {
      return Colors.green;
    }

    if (confidence >= 70) {
      return Colors.orange;
    }

    return Colors.red;
  }

  // ============================================================
  // DISEASE NAME
  // ============================================================

  String formatDiseaseName(String? disease) {
    if (disease == null || disease.isEmpty) {
      return "Unknown";
    }

    if (disease.toLowerCase() == "not matched") {
      return "Image Not Recognized";
    }

    return disease
        .replaceAll("_", " ")
        .replaceAll("-", " ")
        .split(" ")
        .map(
          (word) => word.isEmpty
              ? word
              : "${word[0].toUpperCase()}${word.substring(1)}",
        )
        .join(" ");
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "CropCare AI",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 21,
              ),
            ),
            Text(
              "Smart Crop Disease Assistant",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.info_outline),
            tooltip: "About",
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // =================================================
              // WELCOME CARD
              // =================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2E7D32),
                      Color(0xFF43A047),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.20),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome, Farmer! 👋",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Detect crop diseases quickly\n"
                            "using Artificial Intelligence.",
                            style: TextStyle(
                              color: Colors.white,
                              height: 1.4,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // =================================================
              // TITLE
              // =================================================

              const Text(
                "Analyze Your Crop",
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 7),

              const Text(
                "Take a clear photo of a crop leaf or select one "
                "from your gallery.",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // IMAGE PREVIEW
              // =================================================

              _buildImagePreview(),

              const SizedBox(height: 20),

              // =================================================
              // CAMERA + GALLERY
              // =================================================

              if (selectedImage == null) ...[
                _buildMainButton(
                  icon: Icons.camera_alt_rounded,
                  title: "Take a Photo",
                  subtitle: "Use your camera",
                  onPressed: captureImage,
                  primary: true,
                ),

                const SizedBox(height: 12),

                _buildMainButton(
                  icon: Icons.photo_library_rounded,
                  title: "Choose from Gallery",
                  subtitle: "Select an existing image",
                  onPressed: uploadImage,
                  primary: false,
                ),
              ],

              // =================================================
              // SELECTED IMAGE
              // =================================================

              if (selectedImage != null &&
                  predictionData == null &&
                  !isLoading) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: captureImage,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Retake"),
                        style: OutlinedButton.styleFrom(
                          minimumSize:
                              const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: sendImageToServer,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text(
                          "Analyze",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize:
                              const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // =================================================
              // LOADING
              // =================================================

              if (isLoading) _buildLoadingCard(),

              // =================================================
              // RESULT
              // =================================================

              if (predictionData != null)
                _buildPredictionResult(),

              // =================================================
              // ERROR
              // =================================================

              if (errorMessage != null)
                _buildErrorCard(),

              const SizedBox(height: 28),

              // =================================================
              // SUPPORTED CROPS
              // =================================================

              _buildSupportedCrops(),

              const SizedBox(height: 18),

              // =================================================
              // TIP
              // =================================================

              _buildTipCard(),

              const SizedBox(height: 25),

              // =================================================
              // NEW SCAN
              // =================================================

              if (predictionData != null ||
                  errorMessage != null)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: resetScan,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text(
                      "Scan Another Image",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE PREVIEW
  // ============================================================

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.green.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: selectedImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 72,
                    width: 72,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.image_search_rounded,
                      size: 38,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "No image selected",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Add a crop leaf image to begin",
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 13,
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    selectedImage!,
                    fit: BoxFit.cover,
                  ),

                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: resetScan,
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  if (isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.45),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 4,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // MAIN BUTTON
  // ============================================================

  Widget _buildMainButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
    required bool primary,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary
              ? const Color(0xFF2E7D32)
              : Colors.white,
          foregroundColor:
              primary ? Colors.white : Colors.green.shade800,
          elevation: primary ? 2 : 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: primary
                ? BorderSide.none
                : BorderSide(
                    color: Colors.green.shade200,
                  ),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: primary
                    ? Colors.white.withOpacity(0.18)
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 25,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: primary
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            strokeWidth: 4,
            color: Colors.green,
          ),

          const SizedBox(height: 18),

          const Text(
            "Analyzing your crop...",
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "Our AI model is examining the leaf image.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 15),

          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 18,
                color: Colors.green,
              ),
              SizedBox(width: 6),
              Text(
                "Image uploaded",
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 6),

          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_top,
                size: 18,
                color: Colors.orange,
              ),
              SizedBox(width: 6),
              Text(
                "Identifying disease...",
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESULT
  // ============================================================

  Widget _buildPredictionResult() {
    final disease =
        predictionData?["disease"]?.toString() ?? "";

    final treatment =
        predictionData?["treatment"]?.toString() ?? "";

    final confidence = getConfidence();

    final isNotMatched =
        disease.toLowerCase() == "not matched";

    if (isNotMatched) {
      return _buildNotMatchedCard(
        confidence: confidence,
      );
    }

    final confidenceColor =
        getConfidenceColor(confidence);

    final confidenceLevel =
        getConfidenceLevel(confidence);

    return Container(
      margin: const EdgeInsets.only(top: 24),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.green.withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Colors.green,
                  size: 28,
                ),
              ),

              const SizedBox(width: 13),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Analysis Complete",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "AI prediction result",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          const Text(
            "Detected Condition",
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            formatDiseaseName(disease),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "AI Confidence",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),

              Text(
                "${confidence.toStringAsFixed(2)}%",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: confidenceColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: (confidence / 100)
                  .clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              color: confidenceColor,
            ),
          ),

          const SizedBox(height: 9),

          Row(
            children: [
              Icon(
                confidence >= 90
                    ? Icons.check_circle
                    : confidence >= 70
                        ? Icons.info
                        : Icons.warning,
                size: 18,
                color: confidenceColor,
              ),
              const SizedBox(width: 6),
              Text(
                confidenceLevel,
                style: TextStyle(
                  color: confidenceColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      color: Colors.green.shade800,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Recommended Action",
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  treatment.isEmpty
                      ? "No treatment information available."
                      : treatment,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            "Note: AI predictions are informational. "
            "For serious crop problems, consider consulting "
            "an agricultural expert.",
            style: TextStyle(
              fontSize: 11,
              color: Colors.black45,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NOT MATCHED
  // ============================================================

  Widget _buildNotMatchedCard({
    required double confidence,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.orange.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Colors.orange.shade700,
              size: 38,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            "Image Not Recognized",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "This image does not appear to be "
            "a supported crop leaf.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              height: 1.4,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  "For better results:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "✓ Use a clear crop leaf image\n"
                  "✓ Make sure the leaf is visible\n"
                  "✓ Avoid blurry or dark photos\n"
                  "✓ Use good lighting",
                  style: TextStyle(
                    height: 1.6,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "Supported crops: Potato • Tomato",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: Colors.red.shade700,
            size: 42,
          ),

          const SizedBox(height: 12),

          const Text(
            "Unable to Analyze Image",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            errorMessage ??
                "Something went wrong. Please try again.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUPPORTED CROPS
  // ============================================================

  Widget _buildSupportedCrops() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "Supported Crops",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              _cropChip("🥔", "Potato"),
              const SizedBox(width: 10),
              _cropChip("🍅", "Tomato"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cropChip(
    String emoji,
    String name,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TIP
  // ============================================================

  Widget _buildTipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.blue.shade100,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Colors.blue.shade700,
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  "Image Tip",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Use a clear, well-lit leaf image "
                  "and avoid blurry photos for "
                  "better AI results.",
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}