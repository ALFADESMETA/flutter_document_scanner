// Copyright (c) 2021, Christian Betancourt
// https://github.com/criistian14
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_document_scanner/src/models/area.dart';
import 'package:flutter_document_scanner/src/ui/pages/crop_photo_document_page.dart';
import 'package:flutter_document_scanner/src/ui/pages/take_photo_document_page.dart';
import 'package:flutter_document_scanner/src/utils/image_utils.dart';
import 'package:flutter_document_scanner/src/utils/model_utils.dart';

/// Status of the app
enum AppStatus {
  /// Is initializing
  initial,

  /// Is loading
  loading,

  /// Completed without errors
  success,

  /// An error occurred
  failure,
}

/// Pages of the app
enum AppPages {
  /// Reference to the page [TakePhotoDocumentPage]
  takePhoto,

  /// Reference to the page [CropPhotoDocumentPage]
  cropPhoto,
}

/// Controls the status general of the app
class AppState extends Equatable {
  /// Create an state instance
  const AppState({
    this.currentPage = AppPages.takePhoto,
    this.statusCamera = AppStatus.initial,
    this.cameraController,
    this.statusTakePhotoPage = AppStatus.initial,
    this.pictureInitial,
    this.statusCropPhoto = AppStatus.initial,
    this.contourInitial,
    this.pictureCropped,
    this.statusSavePhotoDocument = AppStatus.initial,
    this.flashMode = FlashMode.off,
  });

  /// Initial state
  factory AppState.init() {
    return const AppState();
  }

  /// Current page being displayed
  final AppPages currentPage;

  /// Status of when the [cameraController] is being created
  final AppStatus statusCamera;

  /// Camera controller from Camera library
  final CameraController? cameraController;

  /// Status when the photo was captured
  final AppStatus statusTakePhotoPage;

  /// Picture that was taken
  final File? pictureInitial;

  /// Status when the photo was cropped
  final AppStatus statusCropPhoto;

  /// Contour found with [ImageUtils.findContourPhoto]
  final Area? contourInitial;

  /// Picture that was cropped
  final Uint8List? pictureCropped;

  /// Status when the photo was saved
  final AppStatus statusSavePhotoDocument;

  /// Current flash mode
  final FlashMode flashMode;

  /// Returns true if there is either a cropped or initial picture available
  bool get hasImage => pictureCropped != null || pictureInitial != null;

  /// Gets the final image bytes, preferring cropped over initial
  Uint8List? get finalImageBytes {
    if (pictureCropped != null) {
      return pictureCropped;
    }
    if (pictureInitial != null) {
      try {
        return pictureInitial!.readAsBytesSync();
      } catch (e) {
        print('Error reading initial picture bytes: $e');
        return null;
      }
    }
    return null;
  }

  /// Returns true if state indicates processing is in progress
  bool get isProcessing =>
      statusCamera == AppStatus.loading ||
      statusTakePhotoPage == AppStatus.loading ||
      statusCropPhoto == AppStatus.loading ||
      statusSavePhotoDocument == AppStatus.loading;

  @override
  List<Object?> get props => [
        currentPage,
        statusCamera,
        cameraController,
        statusTakePhotoPage,
        pictureInitial,
        statusCropPhoto,
        contourInitial,
        pictureCropped,
        statusSavePhotoDocument,
        flashMode,
      ];

  /// Creates a copy of this state but with the given fields replaced with
  /// the new values.
  AppState copyWith({
    AppPages? currentPage,
    AppStatus? statusCamera,
    CameraController? cameraController,
    AppStatus? statusTakePhotoPage,
    File? pictureInitial,
    AppStatus? statusCropPhoto,
    Object? contourInitial = valueNull,
    Uint8List? pictureCropped,
    AppStatus? statusSavePhotoDocument,
    FlashMode? flashMode,
  }) {
    return AppState(
      currentPage: currentPage ?? this.currentPage,
      statusCamera: statusCamera ?? this.statusCamera,
      cameraController: cameraController ?? this.cameraController,
      statusTakePhotoPage: statusTakePhotoPage ?? this.statusTakePhotoPage,
      pictureInitial: pictureInitial ?? this.pictureInitial,
      statusCropPhoto: statusCropPhoto ?? this.statusCropPhoto,
      contourInitial: contourInitial == valueNull
          ? this.contourInitial
          : contourInitial as Area?,
      pictureCropped: pictureCropped ?? this.pictureCropped,
      statusSavePhotoDocument:
          statusSavePhotoDocument ?? this.statusSavePhotoDocument,
      flashMode: flashMode ?? this.flashMode,
    );
  }
}