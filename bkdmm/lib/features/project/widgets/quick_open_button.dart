import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// Quick open project button
class QuickOpenProjectButton extends StatelessWidget {
  /// Callback when a project is selected
  final void Function(String filePath)? onProjectOpened;

  const QuickOpenProjectButton({
    super.key,
    this.onProjectOpened,
  });

  @override
  Widget build(BuildContext context) {
    return TDButton(
      icon: TDIcons.folder_open,
      type: TDButtonType.text,
      theme: TDButtonTheme.defaultTheme,
      onTap: () async {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['bkdmm.json'],
          dialogTitle: 'Open Project',
        );

        if (result != null && result.files.isNotEmpty) {
          final path = result.files.first.path;
          if (path != null) {
            onProjectOpened?.call(path);
          }
        }
      },
    );
  }
}