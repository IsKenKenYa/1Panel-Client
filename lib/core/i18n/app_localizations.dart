import 'package:flutter/material.dart';

/// 应用程序本地化配置类
///
/// 此类负责管理应用程序的多语言支持，按照Flutter官方推荐的方式实现国际化。
/// 参考: https://docs.flutter.cn/ui/accessibility-and-internationalization/internationalization/
class AppLocalizations {
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // 通用文本
  final String appName;
  final String loading;
  final String retry;
  final String error;
  final String success;
  final String cancel;
  final String confirm;
  final String save;
  final String delete;
  final String edit;
  final String close;
  final String create;
  final String load;
  final String recreate;
  final String name;
  final String taskId;
  final String optional;
  final String force;
  final String refresh;
  final String notFound;

  // GPU相关文本
  final String gpu;
  final String temperature;
  final String fanSpeed;
  final String gpuUsage;
  final String memoryUsage;
  final String totalMemory;
  final String usedMemory;

  // 域名绑定相关文本
  final String domain;
  final String appId;
  final String requiredFields;
  final String bind;

  // AI管理页面
  final String aiManagement;
  final String ollamaModels;
  final String gpuInfo;
  final String domainBinding;

  // 错误信息
  final String configLoadError;
  final String networkError;
  final String unknownError;

  const AppLocalizations({
    required this.appName,
    required this.loading,
    required this.retry,
    required this.error,
    required this.success,
    required this.cancel,
    required this.confirm,
    required this.save,
    required this.delete,
    required this.edit,
    required this.close,
    required this.create,
    required this.load,
    required this.recreate,
    required this.name,
    required this.taskId,
    required this.optional,
    required this.force,
    required this.refresh,
    required this.notFound,
    required this.gpu,
    required this.temperature,
    required this.fanSpeed,
    required this.gpuUsage,
    required this.memoryUsage,
    required this.totalMemory,
    required this.usedMemory,
    required this.domain,
    required this.appId,
    required this.requiredFields,
    required this.bind,
    required this.aiManagement,
    required this.ollamaModels,
    required this.gpuInfo,
    required this.domainBinding,
    required this.configLoadError,
    required this.networkError,
    required this.unknownError,
  });
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // 支持的语言列表
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // 根据不同的语言环境加载不同的翻译
    switch (locale.languageCode) {
      case 'zh':
        return AppLocalizationsZh();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}

/// 英文翻译
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn()
      : super(
          appName: '1Panel Open',
          loading: 'Loading...',
          retry: 'Retry',
          error: 'Error',
          success: 'Success',
          cancel: 'Cancel',
          confirm: 'Confirm',
          save: 'Save',
          delete: 'Delete',
          edit: 'Edit',
          close: 'Close',
          create: 'Create',
          load: 'Load',
          recreate: 'Recreate',
          name: 'Name',
          taskId: 'Task ID',
          optional: 'Optional',
          force: 'Force',
          refresh: 'Refresh',
          notFound: 'Not found',
          gpu: 'GPU',
          temperature: 'Temperature',
          fanSpeed: 'Fan Speed',
          gpuUsage: 'GPU Usage',
          memoryUsage: 'Memory Usage',
          totalMemory: 'Total Memory',
          usedMemory: 'Used Memory',
          domain: 'Domain',
          appId: 'App ID',
          requiredFields: 'Please fill in required fields',
          bind: 'Bind',
          aiManagement: 'AI Management',
          ollamaModels: 'Ollama Models',
          gpuInfo: 'GPU Info',
          domainBinding: 'Domain Binding',
          configLoadError: 'Failed to load configuration',
          networkError: 'Network error',
          unknownError: 'Unknown error',
        );
}

/// 中文翻译
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh()
      : super(
          appName: '1Panel Open',
          loading: '正在加载...',
          retry: '重试',
          error: '错误',
          success: '成功',
          cancel: '取消',
          confirm: '确认',
          save: '保存',
          delete: '删除',
          edit: '编辑',
          close: '关闭',
          create: '创建',
          load: '加载',
          recreate: '重新创建',
          name: '名称',
          taskId: '任务ID',
          optional: '可选',
          force: '强制',
          refresh: '刷新',
          notFound: '未找到',
          gpu: 'GPU',
          temperature: '温度',
          fanSpeed: '风扇速度',
          gpuUsage: 'GPU使用率',
          memoryUsage: '内存使用率',
          totalMemory: '总内存',
          usedMemory: '已用内存',
          domain: '域名',
          appId: '应用ID',
          requiredFields: '请填写必填字段',
          bind: '绑定',
          aiManagement: 'AI管理',
          ollamaModels: 'Ollama模型',
          gpuInfo: 'GPU信息',
          domainBinding: '域名绑定',
          configLoadError: '无法加载配置',
          networkError: '网络错误',
          unknownError: '未知错误',
        );
}
