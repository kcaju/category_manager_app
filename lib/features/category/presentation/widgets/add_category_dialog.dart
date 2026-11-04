import 'package:flutter/material.dart';
import '../../domain/models/category_item.dart';
import 'add_category_bottom_sheet.dart';

/// Legacy dialog wrapper that forwards to [AddCategoryBottomSheet]
class AddCategoryDialog {
  static Future<void> show(
    BuildContext context, {
    CategoryItem? initialParent,
    required List<CategoryItem> availableParents,
  }) {
    return AddCategoryBottomSheet.show(
      context,
      initialParent: initialParent,
      availableParents: availableParents,
    );
  }
}

