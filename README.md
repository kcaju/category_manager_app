# Local Hierarchical Category Manager

A robust, production-grade Flutter application built with **Clean Architecture (Presentation / Domain / Data)**, **BLoC / Cubit** for predictable state management, **SQLite (`sqflite`)** with recursive tree queries for offline-first persistence, and **Dio** for remote REST API communication.

---

## 📑 Table of Contents
1. [Project Architecture](#1-project-architecture)
2. [State Management Approach](#2-state-management-approach)
3. [Local Database Selection & Justification](#3-local-database-selection--justification)
4. [Category Hierarchy Implementation (Unlimited Depth)](#4-category-hierarchy-implementation-unlimited-depth)
5. [Search and Pagination Approach](#5-search-and-pagination-approach)
6. [Feature Implementation Details](#6-feature-implementation-details)
   - [6.1 How Login Locker & Session Persistence Works](#61-how-login-locker--session-persistence-works)
   - [6.2 How Add Category Works](#62-how-add-category-works)
   - [6.3 How View Details Works](#63-how-view-details-works)
   - [6.4 How Search Works](#64-how-search-works)
   - [6.5 How Filter Works](#65-how-filter-works)
   - [6.6 How Category Expanding & Collapsing Is Done](#66-how-category-expanding--collapsing-is-done)
7. [Setup and Execution Instructions](#7-setup-and-execution-instructions)
8. [Running Tests](#8-running-tests)

---

## 1. Project Architecture

The application strictly implements **Clean Architecture** with a **Feature-First** structure, ensuring loose coupling, high cohesion, and complete testability:

```
lib/
├── core/
│   ├── constants/       # App-wide constants, endpoints, and table names
│   ├── database/        # AppDatabase with sqflite initialization, indexes & schema migrations
│   ├── errors/          # Custom Failures and domain error handling
│   ├── network/         # ApiClient powered by Dio with interceptors & timeouts
│   ├── theme/           # Material 3 dark-mode design system
│   └── utils/           # Debouncer utility for live search
├── features/
│   ├── auth/
│   │   ├── domain/      # UserProfile entity and AuthRepository interface
│   │   ├── data/        # UserModel, Dio RemoteDataSource, SQLite LocalDataSource, RepositoryImpl
│   │   └── presentation/# AuthCubit, AuthState, LoginScreen, ProfileScreen (Bento Grid)
│   ├── category/
│   │   ├── domain/      # CategoryItem, CategoryTreeNode, CategorySearchResult, PaginatedResult
│   │   ├── data/        # CategoryModel, CategoryLocalDataSource (SQLite CTEs), RepositoryImpl
│   │   └── presentation/# CategoryCubit, CategoryState, CategoryScreen, Tree & Search Widgets
│   └── home/
│       └── presentation/# MainNavigationScreen (compact 54px Material 3 NavigationBar)
└── main.dart            # Pre-load session, Dependency Injection, MultiBlocProvider, AuthGate
```

### Layer Responsibilities:
- **Domain Layer**: 100% pure Dart. Contains business entities (`UserProfile`, `CategoryItem`, `CategoryTreeNode`), value objects, and abstract repository contracts. Has no dependencies on Flutter, SQLite, or Dio.
- **Data Layer**: Implements repository interfaces. Manages external data sources including Dio REST API clients (`AuthRemoteDataSource`), SQLite database access (`AuthLocalDataSource`, `CategoryLocalDataSource`), and recursive SQL CTEs.
- **Presentation Layer**: UI screens and reusable widgets driven by reactive **BLoC / Cubits** (`AuthCubit` and `CategoryCubit`). Utilizes declarative states and event handling.

---

## 2. State Management Approach

### Why BLoC / Cubit (`flutter_bloc`)?
1. **Predictable & Immutable States**: 
   - Uses explicit, immutable states (`CategoryLoading`, `CategoryLoaded`, `CategoryError`, `Authenticated`, `Unauthenticated`).
   - Prevents inconsistent UI states or accidental state mutation common with `ChangeNotifier`s.
2. **Selective & Optimal Rebuilding**:
   - UI rebuilds only when necessary through `BlocBuilder` and `BlocConsumer`.
   - Node expansion and collapse operations toggle state in $O(1)$ directly inside the state tree without triggering costly re-fetches from SQLite.
3. **Reactive Search & Debouncing**:
   - Live search input is debounced (350ms) to ensure smooth 60fps rendering without spamming database lookups.
4. **Separation of Concerns**:
   - Presentation widgets contain zero business logic. All actions (adding, deleting, filtering, searching) are dispatched to the Cubit.

---

## 3. Local Database Selection & Justification

**Selected Technology**: **SQLite via `sqflite`**

### Justification:
1. **Relational Schema with User-Scoped Sequential IDs**:
   Each user's category tree is completely isolated and starts from **ID: 1**:
   ```sql
   CREATE TABLE categories (
     db_id INTEGER PRIMARY KEY AUTOINCREMENT,
     id INTEGER NOT NULL,
     user_id INTEGER NOT NULL DEFAULT 1,
     name TEXT NOT NULL,
     parent_id INTEGER,
     created_at TEXT NOT NULL
   );

   CREATE UNIQUE INDEX idx_category_user_id_unique
   ON categories (user_id, id);
   ```
   When any user creates a category from scratch, `SELECT IFNULL(MAX(id), 0) + 1 WHERE user_id = ?` ensures their first category always starts at **ID: 1** (e.g. User 1: 1, 2, 3... and User 2: 1, 2, 3...).
2. **Guaranteed Uniqueness under Same Parent**:
   - *"Category names must be unique within the same parent"*
   - *"The same category name may exist under a different parent"*
   Enforced both at the database level with a composite unique index and in business validation:
   ```sql
   CREATE UNIQUE INDEX idx_category_user_parent_name
   ON categories (user_id, IFNULL(parent_id, 0), LOWER(name));
   ```
3. **Recursive SQL Support (`WITH RECURSIVE`)**:
   SQLite natively supports Common Table Expressions (CTEs), allowing retrieval of full ancestry paths (`Electronics > Mobile > Android > Samsung`) in a single fast query scoped per user.
4. **Cascading Deletions**:
   Deleting a parent node recursively purges all its nested descendants for that specific user, keeping other users' categories completely intact.

---

## 4. Category Hierarchy Implementation (Unlimited Depth)

- **Data Structure**:
  - `CategoryItem`: Flat entity containing `id`, `name`, `parentId`, and `createdAt`.
  - `CategoryTreeNode`: Hierarchical node containing `category`, `depth`, `parent`, `isExpanded`, and `children: List<CategoryTreeNode>`.

- **Tree Construction Algorithm**:
  Flat SQLite records are converted to a recursive tree structure in **$O(N)$ time**:
  1. All records are grouped by `parentId` into an adjacency map (`Map<int?, List<CategoryItem>>`).
  2. Root nodes (`parentId == null`) are identified.
  3. A recursive tree builder walks the map, assigning depth levels (`0, 1, 2, ... N`) and constructing nested child nodes.

- **Recursive UI Rendering**:
  - `CategoryTreeNodeWidget` dynamically renders itself and recursively maps its `children`.
  - Displays hierarchical branch indicators (`└──`), folder/tag icons, child count badges, and expand/collapse toggles (`▼` / `▶`).
  - Unlimited nesting depth is supported without any hardcoded level restrictions (e.g., `Chain-A ➔ Chain-B ➔ Chain-C ➔ Chain-D ➔ Chain-E ➔ Chain-F`).

---

## 5. Search and Pagination Approach

### Recursive Search:
When a category name is searched:
1. **Matching**: SQLite filters categories using `LOWER(name) LIKE ?`.
2. **Ancestry Path Reconstruction**: A recursive query ascends parent pointers up to the root to produce the full hierarchical breadcrumb path:
   `Electronics  ➔  Mobile  ➔  Android  ➔  Samsung`
3. **Direct Children Retrieval**: Fetches all immediate child subcategories.
4. **Parent Information**: Fetches the direct parent category name or marks as `Root Category`.

### Limit & Pagination:
- **Limit Parameter**:
  - The UI provides quick limit chips: `[All, 5, 10, 20]`.
  - When specified, queries apply SQL `LIMIT ?`.
- **Structured Pagination Metadata**:
  ```json
  {
    "page": 1,
    "page_size": 10,
    "total_count": 125
  }
  ```
- Includes page navigation (`Previous` / `Next`) and total match counters.

---

## 6. Feature Implementation Details

### 6.1 How Login Locker & Session Persistence Works
- **Public REST API**: Authenticates users against the JSONPlaceholder API (`https://jsonplaceholder.typicode.com/users`).
- **Session Persistence**:
  - When a user logs in, their profile is stored in the local SQLite `user_session` table.
- **Zero-Flash Startup (Login Locker)**:
  - In `main()`, `await authRepository.getActiveSession()` is called **before** `runApp()`.
  - `AuthCubit` is initialized immediately with `Authenticated(initialUser)` if a session exists.
  - The application's very first frame renders `MainNavigationScreen` directly. **The login screen never flashes on startup.**
- **Logout Flow**:
  - User taps the logout action in `ProfileScreen`.
  - A confirmation dialog appears.
  - Upon confirmation, `authRepository.logout()` clears `user_session` from SQLite, and `AuthGate` transitions smoothly back to `LoginScreen`.

---

### 6.2 How Add Category Works
- **Trigger**: Glassmorphic Floating Action Button (`+ Add Category`) on the Category screen.
- **Keyboard Protection**:
  - Wrapped in a `ListenableBuilder` listening to `_searchFocusNode`.
  - When the search keyboard opens, the button is instantly hidden (`SizedBox.shrink()`) with `FloatingActionButtonAnimator.noAnimation`, ensuring it never moves up with the keyboard.
- **Creation Dialog (`AddCategoryBottomSheet`)**:
  1. **Category Name Input**: Text field with validation (cannot be empty or whitespace).
  2. **Parent Selector**: Dropdown showing all available categories with depth indentation (`-- Subcategory`).
  3. **Root Option**: Option to select `[None - Create as Root Category]`.
  4. **Duplicate Prevention**: Before insertion, queries SQLite for existing names under the selected parent (case-insensitive). If a duplicate is found, an inline error banner informs the user.
  5. **Instant UI Refresh**: On successful creation, the new category appears immediately in the hierarchy.

---

### 6.3 How View Details Works
- **Trigger**: Tapping the info icon or `View Details` action on any category node or search result card.
- **Modal Sheet (`CategoryRelationshipBottomSheet`)**:
  - Displays complete metadata:
    - **Category Name & ID**
    - **Depth Level** (e.g. `Depth 0 (Root)`, `Depth 2 (Subcategory)`)
    - **Creation Timestamp**
    - **Direct Parent** (name and ID or "None (Root Category)")
    - **Direct Subcategories** (list of all direct children with count)
    - **Full Ancestor Path**: Step-by-step breadcrumb trail (`Electronics > Mobile > Android > Samsung`).
  - Includes a quick action to add a subcategory directly under this item.

---

### 6.4 How Search Works
- **Real-Time Live Search**:
  - The search input triggers queries using a 350ms debouncer to minimize database hits.
  - When characters are entered, the screen automatically switches from **Hierarchy Tree View** to **Search Results View**.
- **Search Result Cards (`search_result_card.dart`)**:
  - Displays category name with matching term highlights.
  - Shows parent category pill and direct subcategory count.
  - Displays full breadcrumb hierarchy path.
  - Provides quick action buttons: `Add Subcategory`, `View Details`, and `Delete`.
- **Clearing Search**: Tapping the `✕` icon or clearing the text field instantly restores the Hierarchy Tree View.

---

### 6.5 How Filter Works
- **Trigger**: The filter icon (`tune`) in the Category screen AppBar.
- **Active Filter Indicator**: A blue dot badge appears on the filter icon whenever a filter other than "All" is active.
- **4 Filter Modes**:
  1. **All Categories**: Shows the complete category hierarchy.
  2. **Root Only**: Shows only top-level categories (`parent_id IS NULL`).
  3. **Leaf Only**: Shows only terminal categories that have no subcategories.
  4. **With Subcategories**: Shows categories that have at least one child subcategory.
- **Dual Compatibility**: Filtering applies simultaneously to both the Tree Hierarchy and live Search Results.

---

### 6.6 How Category Expanding & Collapsing Is Done
- **Branch-Level Toggle**:
  - Tapping the chevron icon (`▼` / `▶`) on any category node with children expands or collapses only that specific branch.
- **Global Actions**:
  - **Expand All**: Expands all categories across all nesting depths simultaneously.
  - **Collapse All**: Collapses all categories back to top-level roots.
- **State Preservation**:
  - The `CategoryCubit` tracks expanded node IDs in an in-memory `Set<int>`.
  - When categories are added, deleted, or searched, existing expanded node states are preserved so open folders remain open without resetting.

---

## 7. Setup and Execution Instructions

### Prerequisites:
- Flutter SDK (v3.13.0 or higher)
- Dart SDK (v3.1.0 or higher)
- Android Studio / VS Code with Flutter extension
- An Android device/emulator or iOS device/simulator

### Installation & Run:
1. Clone or open the repository:
   ```bash
   cd category_manager_app
   ```
2. Get packages:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

---

## 8. Running Tests

Automated unit and integration tests are included covering:
- Unlimited depth tree building (`A ➔ B ➔ C ➔ D ➔ E ➔ F`)
- Recursive search and ancestry path formatting (`Electronics > Mobile > Android > Samsung`)
- Duplicate category prevention under the same parent
- Limit parameter handling (explicit limit vs. All)
- Widget smoke testing and login UI verification

Run tests with:
```bash
flutter test
```
Result:
```
00:01 +4: All tests passed!
```
