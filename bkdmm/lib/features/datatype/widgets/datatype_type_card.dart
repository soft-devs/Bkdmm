/// Data type card widget
library;

import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../core/i18n/i18n.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/models.dart';
import '../../../shared/constants/default_data_types.dart';
import '../../../shared/widgets/td_popup_menu.dart';
import '../utils/datatype_utils.dart';

/// Callback for type action selection
typedef TypeActionCallback = void Function(DataType type, String action);

/// A card widget displaying a data type with its details
class DataTypeCard extends StatelessWidget {
  /// The data type to display
  final DataType type;

  /// Whether this card is selected
  final bool isSelected;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  /// Callback when an action is selected from the menu
  final TypeActionCallback? onAction;

  /// Creates a data type card
  const DataTypeCard({
    super.key,
    required this.type,
    this.isSelected = false,
    this.onTap,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);
    final isDefault = DefaultDataTypes.isDefaultType(type.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? tdTheme.brandLightColor : tdTheme.whiteColor1,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? tdTheme.brandNormalColor : tdTheme.componentStrokeColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: tdTheme.grayColor4.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderRow(tdTheme, isDefault, context),
              if (isSelected) ...[
                const SizedBox(height: 16),
                DataTypeMappings(type: type),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(TDThemeData tdTheme, bool isDefault, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDefault ? tdTheme.brandLightColor : tdTheme.grayColor3,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            getTypeIcon(type.name),
            size: 20,
            color: isDefault ? tdTheme.brandNormalColor : tdTheme.fontGyColor1,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: TDText(
                      type.name,
                      font: tdTheme.fontTitleSmall,
                      fontWeight: FontWeight.w600,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: TDText(
                      type.chnname,
                      font: tdTheme.fontBodyMedium,
                      textColor: tdTheme.fontGyColor2,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              if (type.remark != null && type.remark!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TDText(
                    type.remark!,
                    font: tdTheme.fontBodySmall,
                    textColor: tdTheme.fontGyColor3,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
            ],
          ),
        ),
        _buildActionsMenu(tdTheme, isDefault, context),
      ],
    );
  }

  Widget _buildActionsMenu(TDThemeData tdTheme, bool isDefault, BuildContext context) {
    final l10n = context.l10n;
    return TDPopupMenuButton(
      icon: TDIcons.more,
      iconColor: tdTheme.fontGyColor1,
      items: [
        TDPopupMenuItem(
          value: 'edit',
          icon: TDIcons.edit,
          label: l10n.edit,
        ),
        TDPopupMenuItem(
          value: 'duplicate',
          icon: TDIcons.copy,
          label: l10n.duplicate,
        ),
        if (!isDefault)
          TDPopupMenuItem(
            value: 'delete',
            icon: TDIcons.delete,
            label: l10n.delete,
            iconColor: tdTheme.errorColor6,
            textColor: tdTheme.errorColor6,
          ),
      ],
      onSelected: (action) => onAction?.call(type, action),
    );
  }
}

/// Widget displaying database mappings for a data type
class DataTypeMappings extends StatelessWidget {
  /// The data type whose mappings to display
  final DataType type;

  /// Creates a data type mappings widget
  const DataTypeMappings({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TDText(
          l10n.databaseMappings,
          font: tdTheme.fontBodySmall,
          textColor: tdTheme.fontGyColor2,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: DatabaseCodes.all.map((dbCode) {
            final dbType = type.apply[dbCode];
            return _buildMappingItem(tdTheme, dbCode, dbType);
          }).toList(),
        ),
        if (type.java != null) ...[
          const SizedBox(height: 16),
          _buildJavaMapping(tdTheme, l10n),
        ],
      ],
    );
  }

  Widget _buildMappingItem(TDThemeData tdTheme, String dbCode, String? dbType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tdTheme.grayColor2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TDText(
            DatabaseCodes.getDisplayName(dbCode),
            font: tdTheme.fontBodySmall,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(width: 8),
          Text(
            dbType ?? '-',
            style: TextStyle(
              fontSize: tdTheme.fontBodySmall?.size,
              color: tdTheme.fontGyColor2,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJavaMapping(TDThemeData tdTheme, AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TDText(
          '${l10n.java}: ',
          font: tdTheme.fontBodySmall,
          textColor: tdTheme.fontGyColor2,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: tdTheme.grayColor2,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            type.java!,
            style: TextStyle(
              fontSize: tdTheme.fontBodySmall?.size,
              color: tdTheme.fontGyColor1,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}
