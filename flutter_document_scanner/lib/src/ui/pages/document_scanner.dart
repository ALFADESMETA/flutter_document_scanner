import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_document_scanner/src/bloc/app/app_bloc.dart';
import 'package:flutter_document_scanner/src/bloc/app/app_state.dart';
import 'package:flutter_document_scanner/src/document_scanner_controller.dart';
import 'package:flutter_document_scanner/src/ui/pages/crop_photo_document_page.dart';
import 'package:flutter_document_scanner/src/ui/pages/take_photo_document_page.dart';
import 'package:flutter_document_scanner/src/utils/crop_photo_document_style.dart';
import 'package:flutter_document_scanner/src/utils/dialogs.dart';
import 'package:flutter_document_scanner/src/utils/general_styles.dart';
import 'package:flutter_document_scanner/src/utils/take_photo_document_style.dart';

/// This class is the main page of the document scanner
class DocumentScanner extends StatelessWidget {
  const DocumentScanner({
    super.key,
    this.controller,
    this.generalStyles = const GeneralStyles(),
    this.pageTransitionBuilder,
    this.initialCameraLensDirection = CameraLensDirection.back,
    this.resolutionCamera = ResolutionPreset.high,
    this.takePhotoDocumentStyle = const TakePhotoDocumentStyle(),
    this.cropPhotoDocumentStyle = const CropPhotoDocumentStyle(),
    required this.onSave,
  });

  /// Controller for the document scanner
  final DocumentScannerController? controller;

  /// General styles for the scanner
  final GeneralStyles generalStyles;

  /// Custom page transition builder
  final AnimatedSwitcherTransitionBuilder? pageTransitionBuilder;

  /// Initial camera lens direction
  final CameraLensDirection initialCameraLensDirection;

  /// Camera resolution preset
  final ResolutionPreset resolutionCamera;

  /// Styles for the take photo page
  final TakePhotoDocumentStyle takePhotoDocumentStyle;

  /// Styles for the crop photo page
  final CropPhotoDocumentStyle cropPhotoDocumentStyle;

  /// Callback when document is scanned
  final Function(Uint8List) onSave;

  @override
  Widget build(BuildContext context) {
    final Dialogs dialogs = Dialogs();
    final DocumentScannerController _controller = 
        controller ?? DocumentScannerController();

    return BlocProvider(
      create: (BuildContext context) => _controller.bloc,
      child: RepositoryProvider<DocumentScannerController>(
        create: (context) => _controller,
        child: MultiBlocListener(
          listeners: [
            // Show default dialogs in Take Photo
            BlocListener<AppBloc, AppState>(
              listenWhen: (previous, current) =>
                  current.statusTakePhotoPage != previous.statusTakePhotoPage,
              listener: (context, state) {
                if (generalStyles.hideDefaultDialogs) return;

                if (state.statusTakePhotoPage == AppStatus.loading) {
                  dialogs.defaultDialog(
                    context,
                    generalStyles.messageTakingPicture,
                  );
                }

                if (state.statusTakePhotoPage == AppStatus.success) {
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),

            // Show default dialogs in Crop Photo
            BlocListener<AppBloc, AppState>(
              listenWhen: (previous, current) =>
                  current.statusCropPhoto != previous.statusCropPhoto,
              listener: (context, state) {
                if (generalStyles.hideDefaultDialogs) return;

                if (state.statusCropPhoto == AppStatus.loading) {
                  dialogs.defaultDialog(
                    context,
                    generalStyles.messageCroppingPicture,
                  );
                }

                if (state.statusCropPhoto == AppStatus.success) {
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),

            // Show default dialogs in Save Photo Document
            BlocListener<AppBloc, AppState>(
              listenWhen: (previous, current) =>
                  current.statusSavePhotoDocument !=
                  previous.statusSavePhotoDocument,
              listener: (context, state) {
                if (generalStyles.hideDefaultDialogs) return;

                if (state.statusSavePhotoDocument == AppStatus.loading) {
                  dialogs.defaultDialog(
                    context,
                    generalStyles.messageSavingPicture,
                  );
                }

                if (state.statusSavePhotoDocument == AppStatus.success) {
                  try {
                    final imageData = state.pictureCropped ?? 
                        (state.pictureInitial?.readAsBytesSync());
                        
                    if (imageData != null) {
                      onSave(imageData);
                    }
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    print('Error saving document: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to save document'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
          child: ColoredBox(
            color: generalStyles.baseColor,
            child: _View(
              pageTransitionBuilder: pageTransitionBuilder,
              generalStyles: generalStyles,
              takePhotoDocumentStyle: takePhotoDocumentStyle,
              cropPhotoDocumentStyle: cropPhotoDocumentStyle,
              onSave: onSave,
              initialCameraLensDirection: initialCameraLensDirection,
              resolutionCamera: resolutionCamera,
            ),
          ),
        ),
      ),
    );
  }
}

class _View extends StatelessWidget {
  const _View({
    this.pageTransitionBuilder,
    required this.generalStyles,
    required this.takePhotoDocumentStyle,
    required this.cropPhotoDocumentStyle,
    required this.onSave,
    required this.initialCameraLensDirection,
    required this.resolutionCamera,
  });

  final AnimatedSwitcherTransitionBuilder? pageTransitionBuilder;
  final GeneralStyles generalStyles;
  final TakePhotoDocumentStyle takePhotoDocumentStyle;
  final CropPhotoDocumentStyle cropPhotoDocumentStyle;
  final Function(Uint8List) onSave;
  final CameraLensDirection initialCameraLensDirection;
  final ResolutionPreset resolutionCamera;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return BlocSelector<AppBloc, AppState, AppPages>(
      selector: (state) => state.currentPage,
      builder: (context, state) {
        Widget page = const SizedBox.shrink();

        switch (state) {
          case AppPages.takePhoto:
            if (generalStyles.showCameraPreview) {
              page = TakePhotoDocumentPage(
                takePhotoDocumentStyle: takePhotoDocumentStyle,
                initialCameraLensDirection: initialCameraLensDirection,
                resolutionCamera: resolutionCamera,
              );
            } else {
              page = generalStyles.widgetInsteadOfCameraPreview ??
                  const SizedBox.shrink();
            }
            break;

          case AppPages.cropPhoto:
            page = CropPhotoDocumentPage(
              cropPhotoDocumentStyle: cropPhotoDocumentStyle,
              onSave: onSave,
            );
            break;
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: pageTransitionBuilder ??
              (child, animation) {
                const begin = Offset(-1, 0);
                const end = Offset.zero;
                final tween = Tween(begin: begin, end: end);
                final curvedAnimation = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                );
                return SlideTransition(
                  position: tween.animate(curvedAnimation),
                  child: child,
                );
              },
          child: page,
        );
      },
    );
  }
}