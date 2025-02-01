// Copyright (c) 2021, Christian Betancourt
// https://github.com/criistian14
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_document_scanner/flutter_document_scanner.dart';

/// Default AppBar of the Crop Photo page
class AppBarCropPhoto extends StatelessWidget {
  /// Create a widget with style
  const AppBarCropPhoto({
    super.key,
    required this.cropPhotoDocumentStyle,
  });

  /// The style of the page
  final CropPhotoDocumentStyle cropPhotoDocumentStyle;

  @override
  Widget build(BuildContext context) {
    if (cropPhotoDocumentStyle.hideAppBarDefault) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 30, // Position from bottom
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Clear button
            Container(
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              child: TextButton(
                onPressed: () =>
                    context.read<DocumentScannerController>().changePage(
                          AppPages.takePhoto,
                        ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Scan button
            Container(
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              child: TextButton(
                onPressed: () {
                  final controller = context.read<DocumentScannerController>();
                  controller.cropPhoto();
                  controller.savePhotoDocument();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  cropPhotoDocumentStyle.textButtonSave,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}