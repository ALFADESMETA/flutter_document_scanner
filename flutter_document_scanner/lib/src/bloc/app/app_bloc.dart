// Copyright (c) 2021, Christian Betancourt
// https://github.com/criistian14
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:flutter_document_scanner/src/bloc/app/app.dart';
import 'package:flutter_document_scanner/src/bloc/crop/crop.dart';
import 'package:flutter_document_scanner/src/document_scanner_controller.dart';
import 'package:flutter_document_scanner/src/utils/image_utils.dart';
import 'package:flutter_document_scanner_platform_interface/flutter_document_scanner_platform_interface.dart';

/// Controls interactions throughout the application by means
/// of the [DocumentScannerController]
class AppBloc extends Bloc<AppEvent, AppState> {
  /// Create instance AppBloc
  AppBloc({
    required ImageUtils imageUtils,
  })  : _imageUtils = imageUtils,
        super(AppState.init()) {
    on<AppCameraInitialized>(_cameraInitialized);
    on<AppPhotoTaken>(_photoTaken);
    on<AppExternalImageContoursFound>(_externalImageContoursFound);
    on<AppPageChanged>(_pageChanged);
    on<AppPhotoCropped>(_photoCropped);
    on<AppLoadCroppedPhoto>(_loadCroppedPhoto);
    on<AppStartedSavingDocument>(_startedSavingDocument);
    on<AppDocumentSaved>(_documentSaved);
    on<AppFlashModeChanged>(_flashModeChanged);
  }

  final ImageUtils _imageUtils;
  CameraController? _cameraController;
  late XFile? _pictureTaken;

  /// Initialize [CameraController]
  Future<void> _cameraInitialized(
    AppCameraInitialized event,
    Emitter<AppState> emit,
  ) async {
    emit(state.copyWith(statusCamera: AppStatus.loading));

    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == event.cameraLensDirection,
        orElse: () => cameras.first,
      );

      if (_cameraController != null) {
        await _cameraController?.dispose();
        _cameraController = null;
      }

      _cameraController = CameraController(
        camera,
        event.resolutionCamera,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(FlashMode.off);

      emit(state.copyWith(
        statusCamera: AppStatus.success,
        cameraController: _cameraController,
        flashMode: FlashMode.off,
      ));
    } catch (e) {
      emit(state.copyWith(statusCamera: AppStatus.failure));
    }
  }

  /// Handle flash mode changes
  Future<void> _flashModeChanged(
    AppFlashModeChanged event,
    Emitter<AppState> emit,
  ) async {
    if (_cameraController != null) {
      try {
        await _cameraController!.setFlashMode(event.mode);
        emit(state.copyWith(flashMode: event.mode));
      } catch (e) {
        emit(state.copyWith(flashMode: FlashMode.off));
      }
    }
  }

  /// Take a photo with the [CameraController.takePicture]
  Future<void> _photoTaken(
    AppPhotoTaken event,
    Emitter<AppState> emit,
  ) async {
    emit(state.copyWith(statusTakePhotoPage: AppStatus.loading));

    if (_cameraController == null) return;

    try {
      _pictureTaken = await _cameraController!.takePicture();

      final byteData = await _pictureTaken!.readAsBytes();
      final response = await _imageUtils.findContourPhoto(
        byteData,
        minContourArea: event.minContourArea,
      );

      final fileImage = File(_pictureTaken!.path);

      emit(state.copyWith(
        statusTakePhotoPage: AppStatus.success,
        pictureInitial: fileImage,
        contourInitial: response,
      ));

      emit(state.copyWith(currentPage: AppPages.cropPhoto));
    } catch (e) {
      emit(state.copyWith(statusTakePhotoPage: AppStatus.failure));
    }
  }

  /// Find the contour from an external image like gallery
  Future<void> _externalImageContoursFound(
    AppExternalImageContoursFound event,
    Emitter<AppState> emit,
  ) async {
    try {
      final externalImage = event.image;
      final byteData = await externalImage.readAsBytes();
      final response = await _imageUtils.findContourPhoto(
        byteData,
        minContourArea: event.minContourArea,
      );

      emit(state.copyWith(
        pictureInitial: externalImage,
        contourInitial: response,
      ));

      emit(state.copyWith(currentPage: AppPages.cropPhoto));
    } catch (e) {
      emit(state.copyWith(statusTakePhotoPage: AppStatus.failure));
    }
  }

  /// When changing the page, the state will be initialized
  Future<void> _pageChanged(
    AppPageChanged event,
    Emitter<AppState> emit,
  ) async {
    switch (event.newPage) {
      case AppPages.takePhoto:
        emit(state.copyWith(
          currentPage: event.newPage,
          statusTakePhotoPage: AppStatus.initial,
          statusCropPhoto: AppStatus.initial,
          contourInitial: null,
        ));
        break;

      case AppPages.cropPhoto:
        emit(state.copyWith(currentPage: event.newPage));
        break;
    }
  }

  /// Handle photo cropping state
  Future<void> _photoCropped(
    AppPhotoCropped event,
    Emitter<AppState> emit,
  ) async {
    emit(state.copyWith(statusCropPhoto: AppStatus.loading));
  }

  /// Handle cropped photo loading
  Future<void> _loadCroppedPhoto(
    AppLoadCroppedPhoto event,
    Emitter<AppState> emit,
  ) async {
    emit(state.copyWith(
      statusCropPhoto: AppStatus.success,
      pictureCropped: event.image,
      contourInitial: event.area,
    ));

    add(AppStartedSavingDocument());
  }

  /// Start saving document
  Future<void> _startedSavingDocument(
    AppStartedSavingDocument event,
    Emitter<AppState> emit,
  ) async {
    emit(state.copyWith(statusSavePhotoDocument: AppStatus.loading));
  }

  /// Handle document saving completion
  Future<void> _documentSaved(
    AppDocumentSaved event,
    Emitter<AppState> emit,
  ) async {
    emit(state.copyWith(
      statusSavePhotoDocument:
          event.isSuccess ? AppStatus.success : AppStatus.failure,
    ));
  }

  @override
  Future<void> close() async {
    if (_cameraController != null) {
      await _cameraController!.setFlashMode(FlashMode.off);
      await _cameraController?.dispose();
    }
    return super.close();
  }
}