/// Data type dialogs
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../core/i18n/i18n.dart';
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
  final l10n = context.l10n;
  showDialog(
    context: context,
    builder: (context) => TDAlertDialog(
      title: l10n.deleteDataType,
      content: l10n.deleteConfirmMessage(type.name),
      leftBtn: TDDialogButtonOptions(
        title: l10n.cancel,
        theme: TDButtonTheme.defaultTheme,
        type: TDButtonType.text,
        action: () => Navigator.pop(context),
      ),
      rightBtn: TDDialogButtonOptions(
        title: l10n.delete,
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
  final l10n = context.l10n;
  final usageStr = usage.entries.map((e) => "${e.key}: ${e.value.join(', ')}").join("; ");
  showDialog(
    context: context,
    builder: (context) => TDAlertDialog(
      title: l10n.dataTypeInUse,
      content: l10n.typeInUseDeleteWarning(type.name, usageStr),
      leftBtn: TDDialogButtonOptions(
        title: l10n.cancel,
        theme: TDButtonTheme.defaultTheme,
        type: TDButtonType.text,
        action: () => Navigator.pop(context),
      ),
      rightBtn: TDDialogButtonOptions(
        title: l10n.deleteAnyway,
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
  final l10n = context.l10n;
  showDialog(
    context: context,
    builder: (context) => TDAlertDialog(
      title: l10n.restoreDefaults,
      content: l10n.restoreDefaultsWarning,
      leftBtn: TDDialogButtonOptions(
        title: l10n.cancel,
        theme: TDButtonTheme.defaultTheme,
        type: TDButtonType.text,
        action: () => Navigator.pop(context),
      ),
      rightBtn: TDDialogButtonOptions(
        title: l10n.restore,
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
