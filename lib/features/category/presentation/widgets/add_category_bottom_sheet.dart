import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/category_item.dart';
import '../cubit/category_cubit.dart';

class AddCategoryBottomSheet extends StatefulWidget {
  final CategoryItem? initialParent;
  final List<CategoryItem> availableParents;

  const AddCategoryBottomSheet({
    super.key,
    this.initialParent,
    required this.availableParents,
  });

  static Future<void> show(
    BuildContext context, {
    CategoryItem? initialParent,
    required List<CategoryItem> availableParents,
  }) {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    final categoryCubit = context.read<CategoryCubit>();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => BlocProvider.value(
        value: categoryCubit,
        child: AddCategoryBottomSheet(
          initialParent: initialParent,
          availableParents: availableParents,
        ),
      ),
    ).whenComplete(() {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  State<AddCategoryBottomSheet> createState() => _AddCategoryBottomSheetState();
}

class _AddCategoryBottomSheetState extends State<AddCategoryBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  int? _selectedParentId;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedParentId = widget.initialParent?.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Unfocus keyboard first
    _nameFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await context.read<CategoryCubit>().addCategory(
          name: _nameController.text.trim(),
          parentId: _selectedParentId,
        );

    if (mounted) {
      if (success) {
        _nameFocusNode.unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
        Navigator.pop(context);
      } else {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final parent = widget.availableParents
        .where((c) => c.id == _selectedParentId)
        .firstOrNull;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161622).withValues(alpha: 0.96),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.16),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Drag Handle
                        Center(
                          child: Container(
                            width: 38,
                            height: 4.5,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),

                        // Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.initialParent != null
                                        ? 'Add Subcategory'
                                        : 'Add New Category',
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  if (widget.initialParent != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Text(
                                        'Parent: ${widget.initialParent!.name}',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: const Color(0xFF60A5FA).withValues(alpha: 0.9),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Error message
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            ),
                          ),

                        // Category Name Input
                        TextFormField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          autofocus: false, // Active ONLY when user clicks
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            labelText: 'Category Name *',
                            labelStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                            hintText: 'e.g. Mobile, Gaming',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.drive_file_rename_outline,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a category name';
                            }
                            final trimmed = value.trim().toLowerCase();
                            final isDuplicate = widget.availableParents.any((c) =>
                                (c.parentId ?? 0) == (_selectedParentId ?? 0) &&
                                c.name.trim().toLowerCase() == trimmed);
                            if (isDuplicate) {
                              return 'A category named "$value" already exists here';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Parent Category Dropdown
                        Text(
                          'Parent Category',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int?>(
                          initialValue: _selectedParentId,
                          dropdownColor: const Color(0xFF22222E),
                          isExpanded: true,
                          isDense: true,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            prefixIcon: Icon(
                              Icons.account_tree_outlined,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                'None (Root Category)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF60A5FA),
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            ...widget.availableParents.map(
                              (cat) => DropdownMenuItem<int?>(
                                value: cat.id,
                                child: Text(
                                  '${cat.name} (ID: ${cat.id})',
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            FocusScope.of(context).unfocus();
                            setState(() {
                              _selectedParentId = val;
                            });
                          },
                        ),

                        if (parent != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Will be created as a subcategory of "${parent.name}".',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],

                        const SizedBox(height: 22),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextButton(
                                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white60,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                  ),
                                  onPressed: _isSubmitting ? null : _submit,
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.black87,
                                          ),
                                        )
                                      : const Text(
                                          'Add Category',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

