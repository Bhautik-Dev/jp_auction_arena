import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../widgets/gradient_button.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image from gallery or camera and opens square crop dialog
  static Future<String?> pickAndCropSquareImage(
    BuildContext context, {
    ImageSource source = ImageSource.gallery,
    String dialogTitle = 'Crop Logo to Square',
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file == null) return null;

      final Uint8List bytes = await file.readAsBytes();
      if (!context.mounted) return null;

      final String? croppedBase64 = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _SquareCropDialog(
          imageBytes: bytes,
          title: dialogTitle,
        ),
      );

      return croppedBase64;
    } catch (e) {
      debugPrint('Error picking/cropping image: $e');
      return null;
    }
  }
}

class _SquareCropDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final String title;

  const _SquareCropDialog({
    required this.imageBytes,
    required this.title,
  });

  @override
  State<_SquareCropDialog> createState() => _SquareCropDialogState();
}

class _SquareCropDialogState extends State<_SquareCropDialog> {
  final TransformationController _transformController = TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    // Convert bytes directly to Base64 data string
    final base64String = base64Encode(widget.imageBytes);
    Navigator.pop(context, base64String);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.crop_rounded, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            widget.title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        height: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pinch or scroll to scale, drag to position inside the 1:1 square frame.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: AppColors.accentPink, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      InteractiveViewer(
                        transformationController: _transformController,
                        minScale: 0.5,
                        maxScale: 3.5,
                        boundaryMargin: const EdgeInsets.all(40),
                        child: Center(
                          child: Image.memory(
                            widget.imageBytes,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      // Square Rule of Thirds Guide Grid
                      IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.15))))),
                                    Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.15))))),
                                    Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.15))))),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.15))))),
                                    Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.15))))),
                                    Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.15))))),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.15))))),
                                    Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.15))))),
                                    Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.15))))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        GradientButton(
          height: 38,
          onPressed: _onConfirm,
          icon: Icons.check_rounded,
          label: 'Apply Square Crop',
        ),
      ],
    );
  }
}
