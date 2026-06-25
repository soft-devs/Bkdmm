/// Data type icon utility
library;

import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// Gets the appropriate icon for a data type based on its name
IconData getTypeIcon(String typeName) {
  switch (typeName.toLowerCase()) {
    case 'idorkey':
      return TDIcons.key;
    case 'name':
      return TDIcons.edit;
    case 'intro':
      return TDIcons.edit;
    case 'longtext':
      return TDIcons.article;
    case 'integer':
      return TDIcons.filter_1;
    case 'long':
      return TDIcons.filter;
    case 'money':
      return TDIcons.money;
    case 'datetime':
      return TDIcons.time;
    case 'yesno':
      return TDIcons.check;
    case 'dict':
      return TDIcons.book;
    default:
      return TDIcons.data;
  }
}
