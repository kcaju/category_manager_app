import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/models/category_item.dart';
import '../../domain/models/category_search_result.dart';
import '../../domain/models/category_tree_node.dart';
import '../../domain/models/paginated_result.dart';

enum CategoryFilter {
  all('All Categories', Icons.grid_view_rounded),
  rootOnly('Root Categories Only', Icons.folder_special_outlined),
  withChildrenOnly('With Subcategories', Icons.account_tree_outlined),
  leafOnly('Leaf Categories (No Subcategories)', Icons.label_outline_rounded);

  final String label;
  final IconData icon;
  const CategoryFilter(this.label, this.icon);
}

abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {
  final String? message;
  const CategoryLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class CategoryLoaded extends CategoryState {
  final List<CategoryTreeNode> treeNodes;
  final List<CategoryItem> allCategoriesFlat;
  final String searchQuery;
  final PaginatedResult<CategorySearchResult>? searchResult;
  final int? selectedLimit;
  final int currentPage;
  final bool isSearchLoading;
  final String? snackbarMessage;
  final CategoryFilter? _activeFilter;

  CategoryFilter get activeFilter => _activeFilter ?? CategoryFilter.all;

  const CategoryLoaded({
    required this.treeNodes,
    this.allCategoriesFlat = const [],
    this.searchQuery = '',
    this.searchResult,
    this.selectedLimit,
    this.currentPage = 1,
    this.isSearchLoading = false,
    this.snackbarMessage,
    CategoryFilter? activeFilter = CategoryFilter.all,
  }) : _activeFilter = activeFilter;

  bool get isSearchActive => searchQuery.trim().isNotEmpty;

  List<CategoryTreeNode> get displayTreeNodes {
    final currentFilter = activeFilter;
    switch (currentFilter) {
      case CategoryFilter.all:
        return treeNodes;
      case CategoryFilter.rootOnly:
        return treeNodes.map((n) => n.copyWith(children: const [])).toList();
      case CategoryFilter.withChildrenOnly:
        return treeNodes.where((n) => n.hasChildren).toList();
      case CategoryFilter.leafOnly:
        final List<CategoryTreeNode> leaves = [];
        void findLeaves(List<CategoryTreeNode> list) {
          for (final n in list) {
            if (!n.hasChildren) {
              leaves.add(n.copyWith(children: const []));
            } else {
              findLeaves(n.children);
            }
          }
        }
        findLeaves(treeNodes);
        return leaves;
    }
  }

  List<CategorySearchResult> get displaySearchResults {
    if (searchResult == null) return const [];
    final items = searchResult!.items;
    final currentFilter = activeFilter;
    switch (currentFilter) {
      case CategoryFilter.all:
        return items;
      case CategoryFilter.rootOnly:
        return items.where((r) => r.category.parentId == null).toList();
      case CategoryFilter.withChildrenOnly:
        return items.where((r) => r.directChildren.isNotEmpty).toList();
      case CategoryFilter.leafOnly:
        return items.where((r) => r.directChildren.isEmpty).toList();
    }
  }

  CategoryLoaded copyWith({
    List<CategoryTreeNode>? treeNodes,
    List<CategoryItem>? allCategoriesFlat,
    String? searchQuery,
    PaginatedResult<CategorySearchResult>? Function()? searchResult,
    int? Function()? selectedLimit,
    int? currentPage,
    bool? isSearchLoading,
    String? Function()? snackbarMessage,
    CategoryFilter? activeFilter,
  }) {
    return CategoryLoaded(
      treeNodes: treeNodes ?? this.treeNodes,
      allCategoriesFlat: allCategoriesFlat ?? this.allCategoriesFlat,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResult: searchResult != null ? searchResult() : this.searchResult,
      selectedLimit: selectedLimit != null ? selectedLimit() : this.selectedLimit,
      currentPage: currentPage ?? this.currentPage,
      isSearchLoading: isSearchLoading ?? this.isSearchLoading,
      snackbarMessage: snackbarMessage != null ? snackbarMessage() : null,
      activeFilter: activeFilter ?? _activeFilter ?? CategoryFilter.all,
    );
  }

  @override
  List<Object?> get props => [
        treeNodes,
        allCategoriesFlat,
        searchQuery,
        searchResult,
        selectedLimit,
        currentPage,
        isSearchLoading,
        snackbarMessage,
        activeFilter,
      ];
}

class CategoryError extends CategoryState {
  final String message;
  const CategoryError(this.message);

  @override
  List<Object?> get props => [message];
}

