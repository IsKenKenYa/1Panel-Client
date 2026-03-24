import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'wget_download_status.dart';

class FilesData {
  final List<FileInfo> files;
  final String currentPath;
  final List<String> pathHistory;
  final bool isLoading;
  final String? error;
  final Set<String> selectedFiles;
  final String? sortBy;
  final String? sortOrder;
  final String? searchQuery;
  final ApiConfig? currentServer;
  final List<FileMountInfo>? mountInfo;
  final FileRecycleStatus? recycleBinStatus;
  final List<FileInfo> favorites;
  final Set<String> favoritePaths;
  final WgetDownloadStatus? wgetStatus;
  final bool isDownloading;
  final double downloadProgress;
  final String? downloadingFileName;

  const FilesData({
    this.files = const [],
    this.currentPath = '/',
    this.pathHistory = const ['/'],
    this.isLoading = false,
    this.error,
    this.selectedFiles = const {},
    this.sortBy,
    this.sortOrder,
    this.searchQuery,
    this.currentServer,
    this.mountInfo,
    this.recycleBinStatus,
    this.favorites = const [],
    this.favoritePaths = const {},
    this.wgetStatus,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.downloadingFileName,
  });

  FilesData copyWith({
    List<FileInfo>? files,
    String? currentPath,
    List<String>? pathHistory,
    bool? isLoading,
    String? error,
    Set<String>? selectedFiles,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
    ApiConfig? currentServer,
    List<FileMountInfo>? mountInfo,
    FileRecycleStatus? recycleBinStatus,
    List<FileInfo>? favorites,
    Set<String>? favoritePaths,
    WgetDownloadStatus? wgetStatus,
    bool? isDownloading,
    double? downloadProgress,
    String? downloadingFileName,
  }) {
    return FilesData(
      files: files ?? this.files,
      currentPath: currentPath ?? this.currentPath,
      pathHistory: pathHistory ?? this.pathHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedFiles: selectedFiles ?? this.selectedFiles,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      searchQuery: searchQuery ?? this.searchQuery,
      currentServer: currentServer ?? this.currentServer,
      mountInfo: mountInfo ?? this.mountInfo,
      recycleBinStatus: recycleBinStatus ?? this.recycleBinStatus,
      favorites: favorites ?? this.favorites,
      favoritePaths: favoritePaths ?? this.favoritePaths,
      wgetStatus: wgetStatus,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadingFileName: downloadingFileName ?? this.downloadingFileName,
    );
  }

  bool get hasSelection => selectedFiles.isNotEmpty;
  int get selectionCount => selectedFiles.length;
  bool isSelected(String path) => selectedFiles.contains(path);
  bool get isSearching => searchQuery != null && searchQuery!.isNotEmpty;
  bool get hasServer => currentServer != null;
  bool isFavorite(String path) => favoritePaths.contains(path);
}
