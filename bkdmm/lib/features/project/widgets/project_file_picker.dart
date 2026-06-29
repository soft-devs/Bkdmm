import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// Project file picker widget for embedding in other views
class ProjectFilePicker extends StatefulWidget {
  /// Currently selected file path
  final String? selectedPath;

  /// Callback when a file is selected
  final void Function(String? path)? onPathChanged;

  /// Label for the picker
  final String label;

  const ProjectFilePicker({
    super.key,
    this.selectedPath,
    this.onPathChanged,
    this.label = 'Project File',
  });

  @override
  State<ProjectFilePicker> createState() => _ProjectFilePickerState();
}

class _ProjectFilePickerState extends State<ProjectFilePicker> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.selectedPath);
  }

  @override
  void didUpdateWidget(ProjectFilePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPath != widget.selectedPath) {
      _controller.text = widget.selectedPath ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TDInput(
            controller: _controller,
            leftLabel: widget.label,
            leftIcon: const Icon(TDIcons.file),
            backgroundColor: Colors.transparent,
            readOnly: true,
          ),
        ),
        const SizedBox(width: 8),
        TDButton(
          icon: TDIcons.folder_open,
          type: TDButtonType.outline,
          theme: TDButtonTheme.defaultTheme,
          onTap: _pickFile,
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bkdmm.json'],
      dialogTitle: 'Select ${widget.label}',
    );

    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) {
        _controller.text = path;
        widget.onPathChanged?.call(path);
      }
    }
  }
}