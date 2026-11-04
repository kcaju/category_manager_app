import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/debouncer.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../domain/models/category_item.dart';
import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';
import '../widgets/add_category_bottom_sheet.dart';
import '../widgets/category_relationship_bottom_sheet.dart';
import '../widgets/category_tree_node_widget.dart';
import '../widgets/search_result_card.dart';

class CategoryScreen extends StatefulWidget {
  final UserProfile user;

  const CategoryScreen({super.key, required this.user});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Debouncer _debouncer = Debouncer(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    context.read<CategoryCubit>().loadCategories(userId: widget.user.id);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debouncer.run(() {
      context.read<CategoryCubit>().search(value);
    });
  }

  void _confirmDelete(BuildContext context, CategoryItem item) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E28),
        title: const Text(
          'Delete Category',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${item.name}"?\nAll child subcategories will also be deleted.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<CategoryCubit>().deleteCategory(item.id, item.name);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D14),
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Category Manager',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Managed by ${widget.user.name}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            BlocBuilder<CategoryCubit, CategoryState>(
              builder: (context, state) {
                final activeFilter = state is CategoryLoaded
                    ? state.activeFilter
                    : CategoryFilter.all;
                final isFiltered = activeFilter != CategoryFilter.all;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Filter categories',
                      icon: Icon(
                        Icons.tune_rounded,
                        color: isFiltered
                            ? const Color(0xFF60A5FA)
                            : Colors.white70,
                        size: 22,
                      ),
                      onPressed: () => _showFilterBottomSheet(context),
                    ),
                    if (isFiltered)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF60A5FA),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<CategoryCubit, CategoryState>(
          listener: (context, state) {
            if (state is CategoryLoaded && state.snackbarMessage != null) {
              _searchFocusNode.unfocus();
              FocusManager.instance.primaryFocus?.unfocus();

              final messenger = ScaffoldMessenger.of(context);
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(state.snackbarMessage!),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
              context.read<CategoryCubit>().clearSnackbar();
            }
          },
          builder: (context, state) {
            if (state is CategoryLoading) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      state.message ?? 'Loading categories...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is CategoryError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<CategoryCubit>().loadCategories(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is CategoryLoaded) {
              return Column(
                children: [
                  // Search bar & Filters header
                  _buildSearchAndFiltersHeader(context, state),

                  // Content: Search Results OR Category Hierarchy Tree
                  Expanded(
                    child: state.isSearchActive
                        ? _buildSearchResultsView(context, state)
                        : _buildHierarchyTreeView(context, state),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
        floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
        floatingActionButton: ListenableBuilder(
          listenable: _searchFocusNode,
          builder: (context, _) {
            // When search input is focused or keyboard is visible, hide FAB so it never comes up with keyboard
            final isKeyboardOpen =
                _searchFocusNode.hasFocus ||
                MediaQuery.viewInsetsOf(context).bottom > 0 ||
                View.of(context).viewInsets.bottom > 0;

            if (isKeyboardOpen) {
              return const SizedBox.shrink();
            }

            return BlocBuilder<CategoryCubit, CategoryState>(
              builder: (context, state) {
                final flat = state is CategoryLoaded
                    ? state.allCategoriesFlat
                    : <CategoryItem>[];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            _searchFocusNode.unfocus();
                            FocusManager.instance.primaryFocus?.unfocus();
                            await AddCategoryBottomSheet.show(
                              context,
                              availableParents: flat,
                            );
                            if (context.mounted) {
                              _searchFocusNode.unfocus();
                              FocusManager.instance.primaryFocus?.unfocus();
                            }
                          },
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.22),
                                  Colors.white.withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.32),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Add Category',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchAndFiltersHeader(
    BuildContext context,
    CategoryLoaded state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Glassmorphic Search input
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: false,
                onTapOutside: (_) {
                  _searchFocusNode.unfocus();
                  FocusScope.of(context).unfocus();
                },
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  hintText: 'Search categories...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: state.isSearchActive
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            _searchController.clear();
                            context.read<CategoryCubit>().clearSearch();
                          },
                        )
                      : (state.isSearchLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : null),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Responsive Limit & Pagination chips when searching
          if (state.isSearchActive) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  const Text(
                    'Limit:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildLimitChip(context, state, label: 'All', value: null),
                  const SizedBox(width: 6),
                  _buildLimitChip(context, state, label: '5', value: 5),
                  const SizedBox(width: 6),
                  _buildLimitChip(context, state, label: '10', value: 10),
                  const SizedBox(width: 6),
                  _buildLimitChip(context, state, label: '20', value: 20),
                  const SizedBox(width: 12),
                  if (state.searchResult != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${state.searchResult!.totalCount} found',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF60A5FA),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLimitChip(
    BuildContext context,
    CategoryLoaded state, {
    required String label,
    required int? value,
  }) {
    final isSelected = state.selectedLimit == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? Colors.black87 : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.white,
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      onSelected: (selected) {
        if (selected) {
          context.read<CategoryCubit>().setLimit(value);
        } else {
          // Deselecting current filter reverts to All (null)
          context.read<CategoryCubit>().setLimit(null);
        }
      },
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.15),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    final cubit = context.read<CategoryCubit>();
    final currentState = cubit.state;
    if (currentState is! CategoryLoaded) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (bottomSheetCtx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161622).withValues(alpha: 0.96),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                color: Color(0xFF60A5FA),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Filter Categories',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          if (currentState.activeFilter != CategoryFilter.all)
                            TextButton(
                              onPressed: () {
                                cubit.setFilter(CategoryFilter.all);
                                Navigator.pop(bottomSheetCtx);
                              },
                              child: const Text(
                                'Reset',
                                style: TextStyle(
                                  color: Color(0xFF60A5FA),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else
                            IconButton(
                              onPressed: () => Navigator.pop(bottomSheetCtx),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 12),

                      // Options list
                      ...CategoryFilter.values.map((filter) {
                        final isSelected = currentState.activeFilter == filter;
                        return InkWell(
                          onTap: () {
                            cubit.setFilter(filter);
                            Navigator.pop(bottomSheetCtx);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF3B82F6)
                                        .withValues(alpha: 0.18)
                                  : Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF60A5FA)
                                    : Colors.white.withValues(alpha: 0.1),
                                width: isSelected ? 1.2 : 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  filter.icon,
                                  size: 20,
                                  color: isSelected
                                      ? const Color(0xFF60A5FA)
                                      : Colors.white70,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    filter.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white.withValues(
                                              alpha: 0.85,
                                            ),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 18,
                                    color: Color(0xFF60A5FA),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      _searchFocusNode.unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  Widget _buildHierarchyTreeView(BuildContext context, CategoryLoaded state) {
    if (state.treeNodes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 64,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Categories Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have not added any categories yet.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      children: [
        // Header using Wrap to prevent overflow
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            Text(
              'CATEGORY HIERARCHY (${state.allCategoriesFlat.length})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.55),
                letterSpacing: 0.5,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => context.read<CategoryCubit>().expandAll(),
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 6.0,
                    ),
                    child: Text(
                      'Expand All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF60A5FA),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => context.read<CategoryCubit>().collapseAll(),
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 6.0,
                    ),
                    child: Text(
                      'Collapse All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF60A5FA),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Active filter banner (if not all)
        if (state.activeFilter != CategoryFilter.all) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF60A5FA).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    state.activeFilter.icon,
                    size: 13,
                    color: const Color(0xFF60A5FA),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Filter: ${state.activeFilter.label}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF60A5FA),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => context.read<CategoryCubit>().setFilter(
                      CategoryFilter.all,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Color(0xFF60A5FA),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        if (state.displayTreeNodes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list_off,
                    size: 40,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No categories match "${state.activeFilter.label}"',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.read<CategoryCubit>().setFilter(
                      CategoryFilter.all,
                    ),
                    child: const Text(
                      'Reset Filter',
                      style: TextStyle(color: Color(0xFF60A5FA)),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...state.displayTreeNodes.map(
            (node) => CategoryTreeNodeWidget(
              node: node,
              onToggleExpansion: (id) =>
                  context.read<CategoryCubit>().toggleNodeExpansion(id),
              onAddSubcategory: (parent) async {
                _searchFocusNode.unfocus();
                FocusManager.instance.primaryFocus?.unfocus();
                await AddCategoryBottomSheet.show(
                  context,
                  initialParent: parent,
                  availableParents: state.allCategoriesFlat,
                );
                if (context.mounted) {
                  _searchFocusNode.unfocus();
                  FocusManager.instance.primaryFocus?.unfocus();
                }
              },
              onDelete: (item) => _confirmDelete(context, item),
              onViewDetails: (item) async {
                _searchFocusNode.unfocus();
                FocusManager.instance.primaryFocus?.unfocus();
                await CategoryRelationshipBottomSheet.show(
                  context,
                  category: item,
                  availableParents: state.allCategoriesFlat,
                );
                if (context.mounted) {
                  _searchFocusNode.unfocus();
                  FocusManager.instance.primaryFocus?.unfocus();
                }
              },
            ),
          ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSearchResultsView(BuildContext context, CategoryLoaded state) {
    final searchResult = state.searchResult;
    final items = state.displaySearchResults;

    if (searchResult == null || items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 56,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              state.activeFilter != CategoryFilter.all
                  ? 'No results match "${state.searchQuery}" with filter "${state.activeFilter.label}"'
                  : 'No categories match "${state.searchQuery}"',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            if (state.activeFilter != CategoryFilter.all) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    context.read<CategoryCubit>().setFilter(CategoryFilter.all),
                child: const Text(
                  'Reset Filter',
                  style: TextStyle(color: Color(0xFF60A5FA)),
                ),
              ),
            ] else ...[
              const SizedBox(height: 6),
              Text(
                'Try searching something else.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        // Result cards list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final result = items[index];
              return SearchResultCard(result: result);
            },
          ),
        ),

        // Pagination Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: const Color(0xFF14141C),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Page ${searchResult.page} of ${searchResult.totalPages.clamp(1, 9999)}  (Total: ${searchResult.totalCount})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white70),
                    visualDensity: VisualDensity.compact,
                    onPressed: searchResult.hasPreviousPage
                        ? () => context.read<CategoryCubit>().search(
                            state.searchQuery,
                            limit: state.selectedLimit,
                            page: searchResult.page - 1,
                          )
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_right,
                      color: Colors.white70,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: searchResult.hasNextPage
                        ? () => context.read<CategoryCubit>().search(
                            state.searchQuery,
                            limit: state.selectedLimit,
                            page: searchResult.page + 1,
                          )
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
