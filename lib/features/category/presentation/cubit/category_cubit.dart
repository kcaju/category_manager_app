import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/models/category_search_result.dart';
import '../../domain/models/category_tree_node.dart';
import '../../domain/repositories/category_repository.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepository categoryRepository;
  int _currentUserId = 1;

  int get currentUserId => _currentUserId;

  CategoryCubit({required this.categoryRepository}) : super(CategoryInitial());

  Set<int> _collectExpandedIds(List<CategoryTreeNode> nodes) {
    final Set<int> ids = {};
    void traverse(List<CategoryTreeNode> list) {
      for (final node in list) {
        if (node.isExpanded) ids.add(node.category.id);
        traverse(node.children);
      }
    }

    traverse(nodes);
    return ids;
  }

  List<CategoryTreeNode> _applyExpandedIds(
    List<CategoryTreeNode> nodes,
    Set<int> expandedIds,
  ) {
    return nodes.map((node) {
      final isExpanded = expandedIds.contains(node.category.id);
      return node.copyWith(
        isExpanded: isExpanded,
        children: _applyExpandedIds(node.children, expandedIds),
      );
    }).toList();
  }

  Future<void> loadCategories({int? userId, bool showLoading = true}) async {
    if (userId != null) {
      _currentUserId = userId;
    }

    if (showLoading) {
      emit(const CategoryLoading(message: 'Loading categories...'));
    }
    try {
      final currentState = state;
      final Set<int> existingExpanded = currentState is CategoryLoaded
          ? _collectExpandedIds(currentState.treeNodes)
          : {};

      final flat = await categoryRepository.getAllCategoriesFlat(userId: _currentUserId);
      final rawTree = await categoryRepository.getCategoryTree(userId: _currentUserId);
      final tree = _applyExpandedIds(rawTree, existingExpanded);

      if (currentState is CategoryLoaded && currentState.isSearchActive) {
        // Re-execute search if active
        await search(
          currentState.searchQuery,
          limit: currentState.selectedLimit,
          page: currentState.currentPage,
        );
      } else {
        emit(CategoryLoaded(
          treeNodes: tree,
          allCategoriesFlat: flat,
          activeFilter: currentState is CategoryLoaded
              ? currentState.activeFilter
              : CategoryFilter.all,
        ));
      }
    } catch (e) {
      emit(CategoryError('Failed to load categories: ${e.toString()}'));
    }
  }

  void toggleNodeExpansion(int categoryId) {
    final currentState = state;
    if (currentState is! CategoryLoaded) return;

    final updatedTree = currentState.treeNodes
        .map((node) => node.toggleExpansion(categoryId))
        .toList();

    emit(currentState.copyWith(treeNodes: updatedTree));
  }

  void expandAll() {
    final currentState = state;
    if (currentState is! CategoryLoaded) return;

    final updatedTree = currentState.treeNodes
        .map((n) => n.setExpansionAll(true))
        .toList();
    emit(currentState.copyWith(treeNodes: updatedTree));
  }

  void collapseAll() {
    final currentState = state;
    if (currentState is! CategoryLoaded) return;

    final updatedTree = currentState.treeNodes
        .map((n) => n.setExpansionAll(false))
        .toList();
    emit(currentState.copyWith(treeNodes: updatedTree));
  }

  Future<void> search(
    String query, {
    int? limit,
    bool updateLimit = false,
    int page = 1,
  }) async {
    final currentState = state;
    if (currentState is! CategoryLoaded) return;

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      emit(
        currentState.copyWith(
          searchQuery: '',
          searchResult: () => null,
          isSearchLoading: false,
        ),
      );
      return;
    }

    // When updateLimit is true (e.g. user selected a chip or clicked 'All'),
    // we explicitly use `limit` (which can be null for All).
    // Otherwise, we keep `currentState.selectedLimit`.
    final targetLimit = updateLimit
        ? limit
        : (limit ?? currentState.selectedLimit);

    emit(
      currentState.copyWith(
        searchQuery: query,
        isSearchLoading: true,
        selectedLimit: () => targetLimit,
        currentPage: page,
      ),
    );

    try {
      final results = await categoryRepository.searchCategories(
        query: trimmed,
        limit: targetLimit,
        page: page,
        pageSize: 10,
        userId: _currentUserId,
      );

      final latestState = state;
      if (latestState is CategoryLoaded) {
        emit(
          latestState.copyWith(
            searchQuery: query,
            searchResult: () => results,
            selectedLimit: () => targetLimit,
            currentPage: page,
            isSearchLoading: false,
          ),
        );
      }
    } catch (e) {
      final latestState = state;
      if (latestState is CategoryLoaded) {
        emit(
          latestState.copyWith(
            isSearchLoading: false,
            snackbarMessage: () => 'Search failed: ${e.toString()}',
          ),
        );
      }
    }
  }

  void clearSearch() {
    final currentState = state;
    if (currentState is! CategoryLoaded) return;

    emit(
      currentState.copyWith(
        searchQuery: '',
        searchResult: () => null,
        isSearchLoading: false,
      ),
    );
  }

  Future<void> setLimit(int? limit) async {
    final currentState = state;
    if (currentState is! CategoryLoaded) return;

    if (currentState.isSearchActive) {
      await search(
        currentState.searchQuery,
        limit: limit,
        updateLimit: true,
        page: 1,
      );
    } else {
      emit(currentState.copyWith(selectedLimit: () => limit));
    }
  }

  void setFilter(CategoryFilter filter) {
    final currentState = state;
    if (currentState is! CategoryLoaded) return;
    emit(currentState.copyWith(activeFilter: filter));
  }

  Future<CategorySearchResult?> getCategoryDetails(int id) async {
    try {
      return await categoryRepository.getCategoryDetails(id, userId: _currentUserId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> addCategory({required String name, int? parentId}) async {
    try {
      await categoryRepository.createCategory(
        name: name,
        parentId: parentId,
        userId: _currentUserId,
      );

      final currentState = state;
      final Set<int> existingExpanded = currentState is CategoryLoaded
          ? _collectExpandedIds(currentState.treeNodes)
          : {};

      // If added under a parent, ensure only that parent is expanded so the user sees the new item
      if (parentId != null) {
        existingExpanded.add(parentId);
      }

      final rawTree = await categoryRepository.getCategoryTree(userId: _currentUserId);
      final tree = _applyExpandedIds(rawTree, existingExpanded);
      final flat = await categoryRepository.getAllCategoriesFlat(userId: _currentUserId);

      if (currentState is CategoryLoaded) {
        emit(
          currentState.copyWith(
            treeNodes: tree,
            allCategoriesFlat: flat,
            snackbarMessage: () => 'Category "$name" created successfully!',
          ),
        );
      } else {
        emit(
          CategoryLoaded(
            treeNodes: tree,
            allCategoriesFlat: flat,
            snackbarMessage: 'Category "$name" created successfully!',
            activeFilter: CategoryFilter.all,
          ),
        );
      }
      return true;
    } on ValidationFailure catch (vf) {
      final currentState = state;
      if (currentState is CategoryLoaded) {
        emit(currentState.copyWith(snackbarMessage: () => vf.message));
      }
      return false;
    } catch (e) {
      final currentState = state;
      if (currentState is CategoryLoaded) {
        emit(
          currentState.copyWith(
            snackbarMessage: () => 'Failed to create category: ${e.toString()}',
          ),
        );
      }
      return false;
    }
  }

  Future<void> deleteCategory(int id, String name) async {
    try {
      await categoryRepository.deleteCategory(id, userId: _currentUserId);

      final currentState = state;
      final Set<int> existingExpanded = currentState is CategoryLoaded
          ? _collectExpandedIds(currentState.treeNodes)
          : {};
      existingExpanded.remove(id);

      final rawTree = await categoryRepository.getCategoryTree(userId: _currentUserId);
      final tree = _applyExpandedIds(rawTree, existingExpanded);
      final flat = await categoryRepository.getAllCategoriesFlat(userId: _currentUserId);

      if (currentState is CategoryLoaded) {
        emit(
          currentState.copyWith(
            treeNodes: tree,
            allCategoriesFlat: flat,
            snackbarMessage: () =>
                'Category "$name" and its subcategories deleted.',
          ),
        );
      }
    } catch (e) {
      final currentState = state;
      if (currentState is CategoryLoaded) {
        emit(
          currentState.copyWith(
            snackbarMessage: () => 'Delete failed: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> clearAllCategories() async {
    emit(const CategoryLoading(message: 'Clearing all categories...'));
    try {
      await categoryRepository.clearAllCategories(userId: _currentUserId);
      await loadCategories(userId: _currentUserId, showLoading: false);
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> resetAndSeedSampleData() async {
    emit(
      const CategoryLoading(
        message: 'Resetting and seeding sample hierarchy...',
      ),
    );
    try {
      await categoryRepository.clearAllCategories(userId: _currentUserId);
      await categoryRepository.seedDefaultCategories(userId: _currentUserId);
      await loadCategories(userId: _currentUserId, showLoading: false);
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  void clearSnackbar() {
    final currentState = state;
    if (currentState is CategoryLoaded &&
        currentState.snackbarMessage != null) {
      emit(currentState.copyWith(snackbarMessage: () => null));
    }
  }
}
