// Copyright (c) 2021, Christian Betancourt
// https://github.com/criistian14
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter_document_scanner/flutter_document_scanner.dart';
import 'package:flutter_document_scanner/src/bloc/app/app_bloc.dart';
import 'package:flutter_document_scanner/src/bloc/app/app_event.dart';
import 'package:flutter_document_scanner/src/ui/pages/crop_photo_document_page.dart';
import 'package:flutter_document_scanner/src/ui/pages/take_photo_document_page.dart';
import 'package:flutter_document_scanner/src/utils/image_utils.dart';

/// This class is responsible for controlling the scanning process
class DocumentScannerController {
  /// Creates a new instance of the [AppBloc]
  final AppBloc _appBloc = AppBloc(
    imageUtils: ImageUtils(),
  );

  /// Return the [AppBloc] created
  AppBloc get bloc => _appBloc;

  /// Stream [AppStatus] to know the status while taking the picture
  Stream<AppStatus> get statusTakePhotoPage {
    return _appBloc.stream.map((data) => data.statusTakePhotoPage).distinct();
  }

  /// Stream [AppStatus] to know the status while the document is being cropped
  Stream<AppStatus> get statusCropPhoto {
    return _appBloc.stream.map((data) => data.statusCropPhoto).distinct();
  }

  /// Stream [AppStatus] to know the status while saving the document
  Stream<AppStatus> get statusSavePhotoDocument {
    return _appBloc.stream
        .map((data) => data.statusSavePhotoDocument)
        .distinct();
  }

  /// Stream [AppPages] to know the current page
  Stream<AppPages> get currentPage {
    return _appBloc.stream.map((data) => data.currentPage).distinct();
  }

  /// Stream [FlashMode] to know the current flash mode
  Stream<FlashMode> get flashMode {
    return _appBloc.stream.map((data) => data.flashMode).distinct();
  }

  /// Will return the picture taken on the [TakePhotoDocumentPage]
  File? get pictureTaken => _appBloc.state.pictureInitial;

  /// Will return the picture cropped on the [CropPhotoDocumentPage]
  Uint8List? get pictureCropped => _appBloc.state.pictureCropped;

  /// Will return the current photo data, either cropped or original
  /// Returns the cropped image if available, otherwise returns the original image bytes
  Uint8List? get photo {
    // First try to get the cropped image
    if (_appBloc.state.pictureCropped != null) {
      return _appBloc.state.pictureCropped;
    }
    // If no cropped image, try to get the original image
    if (_appBloc.state.pictureInitial != null) {
      try {
        return _appBloc.state.pictureInitial!.readAsBytesSync();
      } catch (e) {
        print('Error reading original photo bytes: $e');
        return null;
      }
    }
    return null;
  }

  /// Taking the photo
  /// Then find the contour with the largest area only when
  /// it exceeds [minContourArea]
  /// [minContourArea] is default 80000.0
  Future<void> takePhoto({
    double? minContourArea,
  }) async {
    _appBloc.add(AppPhotoTaken(minContourArea: minContourArea));
  }

  /// Find the contour from an external image like gallery
  /// [minContourArea] is default 80000.0
  Future<void> findContoursFromExternalImage({
    required File image,
    double? minContourArea,
  }) async {
    _appBloc.add(
      AppExternalImageContoursFound(
        image: image,
        minContourArea: minContourArea,
      ),
    );
  }

  /// Change current page by [AppPages]
  Future<void> changePage(AppPages page) async {
    _appBloc.add(AppPageChanged(page));
  }

  /// Cutting the photo and adjusting the perspective
  /// then save the document
  Future<void> cropPhoto() async {
    _appBloc.add(AppPhotoCropped());
    _appBloc.add(AppStartedSavingDocument());
  }

  /// Save the document with cropping area if available, otherwise saves the original photo
  /// It will return it as [Uint8List] in [DocumentScanner]
  /// The saved document can be accessed via the [photo] getter
  Future<void> savePhotoDocument() async {
    if (_appBloc.state.pictureCropped != null || _appBloc.state.pictureInitial != null) {
      _appBloc.add(AppStartedSavingDocument());
      _appBloc.add(AppDocumentSaved(isSuccess: true));
    } else {
      _appBloc.add(AppDocumentSaved(isSuccess: false));
    }
  }

  /// Set the camera flash mode
  Future<void> setFlashMode(FlashMode mode) async {
    _appBloc.add(AppFlashModeChanged(mode));
  }

  /// Toggle flash between torch and off
  Future<void> toggleFlash() async {
    final currentMode = _appBloc.state.flashMode;
    final newMode = currentMode == FlashMode.torch 
        ? FlashMode.off 
        : FlashMode.torch;
    await setFlashMode(newMode);
  }

  /// Get the current flash mode
  FlashMode getFlashMode() {
    return _appBloc.state.flashMode;
  }

  /// Dispose the [AppBloc] and clean up resources
  Future<void> dispose() async {
    await setFlashMode(FlashMode.off);
    _appBloc.close();
  }
}