import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';
import '../../data/models/file_models.dart';

class FileV2Api {
  final DioClient _client;

  FileV2Api(this._client);

  /// 搜索文件
  ///
  /// 在指定目录下搜索文件
  /// @param request 文件搜索请求
  /// @return 文件信息响应（包含items数组）
  Future<Response<FileSearchResponse>> searchFiles(FileSearch request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/files/search'),
      data: request.toJson(),
    );
    return Response(
      data: FileSearchResponse.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取文件列表
  ///
  /// 获取指定目录下的文件列表
  /// @param request 文件搜索请求
  /// @return 文件列表
  Future<Response<List<FileInfo>>> getFiles(FileSearch request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/files/search'),
      data: request.toJson(),
    );
    final fileResponse = FileSearchResponse.fromJson(response.data as Map<String, dynamic>);
    return Response(
      data: fileResponse.items,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 创建文件或目录
  ///
  /// 创建一个新的文件或目录
  /// @param request 文件创建请求
  /// @return 创建结果
  Future<Response> createFile(FileCreate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/files'),
      data: request.toJson(),
    );
  }

  /// 创建目录 (兼容旧方法)
  @Deprecated('Use createFile instead')
  Future<Response> createDirectory(FileCreate request) async {
    return createFile(request);
  }

  /// 删除文件或目录（单个）
  ///
  /// 删除指定的文件或目录
  /// @param request 文件删除请求
  /// @return 删除结果
  Future<Response> deleteFile(FileDelete request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/files/del'),
      data: request.toJson(),
    );
  }

  /// 批量删除文件或目录
  ///
  /// 批量删除指定的文件或目录
  /// @param request 批量删除请求
  /// @return 删除结果
  Future<Response> deleteFiles(FileBatchDelete request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/files/batch/del'),
      data: request.toJson(),
    );
  }

  /// 重命名文件或目录
  ///
  /// 重命名指定的文件或目录
  /// @param request 文件重命名请求
  /// @return 重命名结果
  Future<Response> renameFile(FileRename request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/files/rename'),
      data: request.toJson(),
    );
  }

  /// 移动文件或目录
  ///
  /// 移动指定的文件或目录
  /// @param request 文件移动请求
  /// @return 移动结果
  Future<Response> moveFiles(FileMove request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/files/move'),
      data: request.toJson(),
    );
  }

  /// 上传文件
  ///
  /// 上传文件到指定目录
  /// @param path 目标目录路径
  /// @param file 文件对象
  /// @return 上传结果
  Future<Response> uploadFile(String path, dynamic file) async {
    final formData = FormData.fromMap({
      'path': path,
      'file': file,
    });
    return await _client.post(
      ApiConstants.buildApiPath('/files/upload'),
      data: formData,
    );
  }

  /// 下载文件
  ///
  /// 下载指定的文件 (GET 方法)
  /// @param path 文件路径
  /// @return 文件内容（字节）
  Future<Response<List<int>>> downloadFile(String path) async {
    return await _client.get<List<int>>(
      ApiConstants.buildApiPath('/files/download'),
      queryParameters: {'path': path},
      options: Options(
        responseType: ResponseType.bytes,
      ),
    );
  }

  /// 下载文件 (POST 方法，兼容旧版本)
  @Deprecated('Use downloadFile with path parameter instead')
  Future<Response> downloadFileWithRequest(FileDownload request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/files/download'),
      data: request.toJson(),
    );
  }

  /// 获取文件内容
  ///
  /// 获取指定文件的内容
  /// @param path 文件路径
  /// @return 文件内容
  Future<Response<String>> getFileContent(String path) async {
    final data = {
      'path': path,
    };
    final response = await _client.post(
      ApiConstants.buildApiPath('/files/content'),
      data: data,
    );
    String content = '';
    if (response.data != null) {
      if (response.data is Map<String, dynamic>) {
        final dataWrapper = response.data as Map<String, dynamic>;
        final dataField = dataWrapper['data'];
        if (dataField is Map<String, dynamic>) {
          content = dataField['content'] as String? ?? '';
        } else {
          content = dataField?.toString() ?? '';
        }
      } else {
        content = response.data.toString();
      }
    }
    return Response(
      data: content,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新文件内容
  ///
  /// 更新指定文件的内容
  /// @param request 文件内容更新请求
  /// @return 更新结果
  Future<Response> updateFileContent(FileContent request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/files/save'),
      data: request.toJson(),
    );
  }

  /// 压缩文件或目录
  ///
  /// 压缩指定的文件或目录
  /// @param request 文件压缩请求
  /// @return 压缩结果
  Future<Response> compressFiles(FileCompress request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/files/compress'),
      data: request.toJson(),
    );
  }

  /// 解压文件
  ///
  /// 解压指定的压缩文件
  /// @param request 文件解压请求
  /// @return 解压结果
  Future<Response> decompressFile(FileExtract request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/files/decompress'),
      data: request.toJson(),
    );
  }

  /// 解压文件 (兼容旧方法名)
  @Deprecated('Use decompressFile instead')
  Future<Response> extractFile(FileExtract request) async {
    return decompressFile(request);
  }

  /// 更新文件权限模式
  ///
  /// 更新指定文件的权限模式
  /// @param request 权限模式更新请求
  /// @return 更新结果
  Future<Response> updateFileMode(FileModeChange request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/files/mode'),
      data: request.toJson(),
    );
  }

  /// 更新文件所有者
  ///
  /// 更新指定文件的所有者
  /// @param request 所有者更新请求
  /// @return 更新结果
  Future<Response> updateFileOwner(FileOwnerChange request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/files/owner'),
      data: request.toJson(),
    );
  }

  /// 批量删除文件
  ///
  /// 批量删除文件或目录
  /// @param request 批量删除请求
  /// @return 删除结果
  Future<Response> batchDeleteFiles(FileBatchOperate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/files/batch/del'),
      data: request.toJson(),
    );
  }

  /// 批量修改文件角色
  ///
  /// 批量修改文件或目录的角色
  /// @param request 批量角色修改请求
  /// @return 修改结果
  Future<Response> batchChangeFileRole(FileBatchRoleRequest request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/files/batch/role'),
      data: request.toJson(),
    );
  }

  /// 检查文件
  ///
  /// 检查文件是否存在或可访问
  /// @param request 文件检查请求
  /// @return 检查结果
  Future<Response<FileCheckResult>> checkFile(FileCheck request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/files/check'),
      data: request.toJson(),
    );
    return Response(
      data: FileCheckResult.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 分块下载文件
  ///
  /// 分块下载大文件
  /// @param request 分块下载请求
  /// @return 分块内容
  Future<Response<FileChunkData>> chunkDownload(FileChunkDownload request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/files/chunkdownload'),
      data: request.toJson(),
    );
    return Response(
      data: FileChunkData.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 分块上传文件
  ///
  /// 分块上传大文件
  /// @param request 分块上传请求
  /// @return 上传结果
  Future<Response<FileChunkResult>> chunkUpload(FileChunkUpload request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/files/chunkupload'),
      data: request.toJson(),
    );
    return Response(
      data: FileChunkResult.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 收藏文件
  ///
  /// 收藏文件或目录
  /// @param request 收藏请求
  /// @return 收藏结果
  Future<Response> favoriteFile(FileFavorite request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/files/favorite'),
      data: request.toJson(),
    );
  }

  /// 取消收藏文件
  ///
  /// 取消收藏文件或目录
  /// @param request 取消收藏请求
  /// @return 取消结果
  Future<Response> unfavoriteFile(FileUnfavorite request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/files/favorite/del'),
      data: request.toJson(),
    );
  }

  /// 搜索收藏文件
  ///
  /// 搜索收藏的文件或目录
  /// @param request 搜索请求
  /// @return 收藏文件列表
  Future<Response<List<FileInfo>>> searchFavoriteFiles(FileSearch request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/files/favorite/search'),
      data: request.toJson(),
    );
    final responseData = response.data;
    List<FileInfo> files = [];
    
    if (responseData is Map<String, dynamic>) {
      final dataWrapper = responseData['data'];
      if (dataWrapper is Map<String, dynamic>) {
        final itemsRaw = dataWrapper['items'];
        if (itemsRaw is List) {
          files = itemsRaw.map((item) => FileInfo.fromJson(item as Map<String, dynamic>)).toList();
        }
      } else if (dataWrapper is List) {
        files = dataWrapper.map((item) => FileInfo.fromJson(item as Map<String, dynamic>)).toList();
      }
    } else if (responseData is List) {
      files = responseData.map((item) => FileInfo.fromJson(item as Map<String, dynamic>)).toList();
    }
    return Response(
      data: files,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 修改文件模式
  ///
  /// 修改文件或目录的访问模式
  /// @param request 模式修改请求
  /// @return 修改结果
  Future<Response> changeFileMode(FileModeChange request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/files/mode'),
      data: request.toJson(),
    );
  }

  /// 修改文件所有者
  ///
  /// 修改文件或目录的所有者
  /// @param request 所有者修改请求
  /// @return 修改结果
  Future<Response> changeFileOwner(FileOwnerChange request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/files/owner'),
      data: request.toJson(),
    );
  }

  /// 读取文件
  ///
  /// 读取文件内容
  /// @param request 文件读取请求
  /// @return 文件内容
  Future<Response<String>> readFile(FileRead request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/files/read'),
      data: request.toJson(),
    );
    return Response(
      data: response.data?.toString() ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<FileReadByLineResponse>> readFileByLine(
    FileReadByLineRequest request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/files/read'),
      data: request.toJson(),
    );
    final wrapper = response.data ?? const <String, dynamic>{};
    final data = wrapper['data'] as Map<String, dynamic>? ?? wrapper;
    return Response<FileReadByLineResponse>(
      data: FileReadByLineResponse.fromJson(data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 清空回收站
  ///
  /// 清空回收站中的所有文件
  /// @return 清空结果
  Future<Response> clearRecycleBin() async {
    return await _client.post(
      ApiConstants.buildApiPath('/files/recycle/clear'),
    );
  }

  /// 减少回收站
  ///
  /// 减少回收站大小（删除最旧的文件）
  /// @param request 减少请求
  /// @return 减少结果
  Future<Response<FileRecycleResult>> reduceRecycleBin(FileRecycleReduce request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/files/recycle/reduce'),
      data: request.toJson(),
    );
    return Response(
      data: FileRecycleResult.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 恢复回收站文件
  ///
  /// 从回收站恢复文件到原路径
  /// @param request 恢复请求
  /// @return 恢复结果
  Future<Response> restoreRecycleBinFile(RecycleBinReduceRequest request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/files/recycle/reduce'),
      data: request.toJson(),
    );
  }

  /// 搜索回收站
  ///
  /// 搜索回收站中的文件
  /// @param request 搜索请求
  /// @return 回收站文件列表
  Future<Response<List<FileInfo>>> searchRecycleBin(FileSearch request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/files/recycle/search'),
      data: request.toJson(),
    );
    final data = response.data;
    List<FileInfo> files = [];
    if (data is List) {
      files = data.map((item) => FileInfo.fromJson(item as Map<String, dynamic>)).toList();
    } else if (data is Map<String, dynamic>) {
      final dataWrapper = data['data'];
      if (dataWrapper is Map<String, dynamic>) {
        final itemsRaw = dataWrapper['items'];
        if (itemsRaw is List) {
          files = itemsRaw.map((item) => FileInfo.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
      if (files.isEmpty) {
        final itemsRaw = data['items'] ?? data['files'];
        if (itemsRaw is List) {
          files = itemsRaw.map((item) => FileInfo.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
    }
    return Response(
      data: files,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取回收站状态
  ///
  /// 获取回收站状态信息
  /// @return 回收站状态
  Future<Response<FileRecycleStatus>> getRecycleBinStatus() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/files/recycle/status'),
    );
    return Response(
      data: FileRecycleStatus.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 保存文件
  ///
  /// 保存文件内容
  /// @param request 文件保存请求
  /// @return 保存结果
  Future<Response> saveFile(FileSave request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/files/save'),
      data: request.toJson(),
    );
  }

  /// 获取文件大小
  ///
  /// 获取文件或目录的大小
  /// @param request 大小查询请求
  /// @return 文件大小信息
  Future<Response<FileSizeInfo>> getFileSize(FileSizeRequest request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/files/size'),
      data: request.toJson(),
    );
    return Response(
      data: FileSizeInfo.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取文件树
  ///
  /// 获取目录的文件树结构
  /// @param request 文件树请求
  /// @return 文件树结构
  Future<Response<FileTree>> getFileTree(FileTreeRequest request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/files/tree'),
      data: request.toJson(),
    );
    return Response(
      data: FileTree.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 搜索上传文件
  ///
  /// 搜索已上传的文件
  /// @param request 搜索请求
  /// @return 上传文件列表
  Future<Response<List<FileInfo>>> searchUploadedFiles(FileSearch request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/files/upload/search'),
      data: request.toJson(),
    );
    // 处理API返回可能是Map或List的情况
    final data = response.data;
    List<FileInfo> files = [];
    if (data is List) {
      files = data.map((item) => FileInfo.fromJson(item as Map<String, dynamic>)).toList();
    } else if (data is Map<String, dynamic>) {
      var itemsRaw = data['items'] ?? data['data'];
      
      if (itemsRaw is List) {
        files = itemsRaw.map((item) => FileInfo.fromJson(item as Map<String, dynamic>)).toList();
      } else if (itemsRaw is Map<String, dynamic>) {
         // Handle case where items might be wrapped in another object or pagination
         // Try to find a list inside
         if (itemsRaw['items'] is List) {
           files = (itemsRaw['items'] as List).map((item) => FileInfo.fromJson(item as Map<String, dynamic>)).toList();
         } else if (itemsRaw['data'] is List) {
           files = (itemsRaw['data'] as List).map((item) => FileInfo.fromJson(item as Map<String, dynamic>)).toList();
         }
      }
    }
    return Response(
      data: files,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 使用Wget下载文件
  ///
  /// 使用Wget命令下载文件
  /// @param request Wget下载请求
  /// @return 下载结果
  Future<Response<FileWgetResult>> wgetDownload(FileWgetRequest request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/files/wget'),
      data: request.toJson(),
    );
    return Response(
      data: FileWgetResult.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 创建文件链接
  ///
  /// 创建文件或目录的符号链接
  /// @param request 链接创建请求
  /// @return 创建结果
  Future<Response> createFileLink(FileLinkCreate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/files'),
      data: FileCreate(
        path: request.linkPath,
        linkPath: request.sourcePath,
        isLink: true,
        isSymlink: request.linkType == 'symbolic',
      ).toJson(),
    );
  }

  /// 转换文件日志
  ///
  /// 获取文件转换日志
  /// @param request 转换日志请求
  /// @return 转换日志
  Future<Response<String>> convertFileLog(FileConvertLogRequest request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/files/convert/log'),
      data: request.toJson(),
    );
    return Response(
      data: response.data?.toString() ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取多文件大小
  ///
  /// 获取多个文件或目录的大小
  /// @param request 多文件大小请求
  /// @return 多文件大小信息
  Future<Response<FileDepthSizeInfo>> getDepthSize(FileDepthSizeRequest request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/files/depth/size'),
      data: request.toJson(),
    );
    return Response(
      data: FileDepthSizeInfo.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取系统挂载信息
  ///
  /// 获取系统磁盘挂载信息
  /// @return 挂载信息列表
  Future<Response<List<FileMountInfo>>> getMountInfo() async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/files/mount'),
    );
    final data = response.data;
    List<FileMountInfo> mounts = [];
    if (data is List) {
      mounts = data.map((item) => FileMountInfo.fromJson(item as Map<String, dynamic>)).toList();
    } else if (data is Map<String, dynamic>) {
      final items = data['items'] as List? ?? data['data'] as List?;
      mounts = items?.map((item) => FileMountInfo.fromJson(item as Map<String, dynamic>)).toList() ?? [];
    }
    return Response(
      data: mounts,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 预览文件
  ///
  /// 预览文件内容
  /// @param request 预览请求
  /// @return 文件预览内容
  Future<Response<String>> previewFile(FilePreviewRequest request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/files/preview'),
      data: request.toJson(),
    );
    return Response(
      data: response.data?.toString() ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取系统用户和组
  ///
  /// 获取系统用户和组列表
  /// @return 用户和组信息
  Future<Response<FileUserGroupResponse>> getUserGroup() async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/files/user/group'),
    );
    return Response(
      data: FileUserGroupResponse.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 批量检查文件
  ///
  /// 批量检查文件是否存在
  /// @param request 批量检查请求
  /// @return 批量检查结果
  Future<Response<FileBatchCheckResult>> batchCheckFiles(FileBatchCheckRequest request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/files/batch/check'),
      data: request.toJson(),
    );
    return Response(
      data: FileBatchCheckResult.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }
}
