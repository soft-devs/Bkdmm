/// Data type dialogs
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../shared/models/models.dart';
import '../providers/datatype_provider.dart';
import '../views/datatype_edit_dialog.dart';

/// Shows the add data type dialog
void showAddDataTypeDialog(BuildContext context, WidgetRef ref, VoidCallback onUpdate) {
  showDialog(
    context: context,
    builder: (context) => DataTypeEditDialog(
      onSave: (newType) {
        final notifier = ref.read(dataTypeNotifierProvider.notifier);
        final created = notifier.createNewDataType(
          name: newType.name,
          chnname: newType.chnname,
          remark: newType.remark,
          apply: newType.apply,
          java: newType.java,
        );
        if (notifier.addDataType(created)) {
          onUpdate();
        }
      },
    ),
  );
}

/// Shows the edit data type dialog
void showEditDataTypeDialog(
  BuildContext context,
  WidgetRef ref,
  DataType type,
  VoidCallback onUpdate,
) {
  showDialog(
    context: context,
    builder: (context) => DataTypeEditDialog(
      existingType: type,
      onSave: (updated) {
        if (ref.read(dataTypeNotifierProvider.notifier).updateDataType(type.id, updated)) {
          onUpdate();
        }
      },
    ),
  );
}

/// Shows the delete data type dialog
void showDeleteDataTypeDialog(
  BuildContext context,
  WidgetRef ref,
  DataType type,
  List<Module> modules,
  VoidCallback onUpdate,
) {
  showDialog(
    context: context,
    builder: (context) => TDAlertDialog(
      title: 'Delete Data Type',
      content: 'Are you sure you want to delete "${type.name}"? This action cannot be undone.',
      leftBtn: TDDialogButtonOptions(
        title: 'Cancel',
        theme: TDButtonTheme.defaultTheme,
        type: TDButtonType.text,
        action: () => Navigator.pop(context),
      ),
      rightBtn: TDDialogButtonOptions(
        title: 'Delete',
        theme: TDButtonTheme.danger,
        type: TDButtonType.fill,
        action: () {
          final usage = ref
              .read(dataTypeNotifierProvider.notifier)
              .deleteDataType(type.id, modules);

          if (usage != null && usage.isNotEmpty) {
            // Type is in use, show warning
            Navigator.pop(context);
            showUsageWarningDialog(context, ref, type, usage, onUpdate);
          } else if (usage == null) {
            // Deleted successfully
            Navigator.pop(context);
            onUpdate();
          }
        },
      ),
    ),
  );
}

/// Shows the usage warning dialog when a type is in use
void showUsageWarningDialog(
  BuildContext context,
  WidgetRef ref,
  DataType type,
  Map<String, List<String>> usage,
  VoidCallback onUpdate,
) {
  showDialog(
    context: context,
    builder: (context) => TDAlertDialog(
      title: 'Type In Use',
      content:
          'The type "${type.name}" is used in the following fields: ${usage.entries.map((e) => "${e.key}: ${e.value.join(', ')}").join("; ")}. Do you want to delete it anyway? Fields using this type may break.',
      leftBtn: TDDialogButtonOptions(
        title: 'Cancel',
        theme: TDButtonTheme.defaultTheme,
        type: TDButtonType.text,
        action: () => Navigator.pop(context),
      ),
      rightBtn: TDDialogButtonOptions(
        title: 'Delete Anyway',
        theme: TDButtonTheme.danger,
        type: TDButtonType.fill,
        action: () {
          ref.read(dataTypeNotifierProvider.notifier).forceDeleteDataType(type.id);
          Navigator.pop(context);
          onUpdate();
        },
      ),
    ),
  );
}

/// Shows the restore defaults dialog
void showRestoreDefaultsDialog(BuildContext context, WidgetRef ref, VoidCallback onUpdate) {
  showDialog(
    context: context,
    builder: (context) => TDAlertDialog(
      title: 'Restore Defaults',
      content:
          'This will restore all default data types to their original values. Custom types will not be affected.',
      leftBtn: TDDialogButtonOptions(
        title: 'Cancel',
        theme: TDButtonTheme.defaultTheme,
        type: TDButtonType.text,
        action: () => Navigator.pop(context),
      ),
      rightBtn: TDDialogButtonOptions(
        title: 'Restore',
        theme: TDButtonTheme.primary,
        type: TDButtonType.fill,
        action: () {
          ref.read(dataTypeNotifierProvider.notifier).restoreDefaults();
          Navigator.pop(context);
          onUpdate();
        },
      ),
    ),
  );
}
