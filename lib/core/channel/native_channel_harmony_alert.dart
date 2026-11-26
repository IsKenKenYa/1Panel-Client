import 'dart:convert';

import '../../data/models/alert_models.dart';
import '../../data/repositories/website_repository.dart';
import '../../features/alert/alert_service.dart';
import '../../features/alert/alert_types.dart';
import '../../features/websites/services/website_certificate_service.dart';
import 'native_alert_payloads.dart';

class NativeChannelHarmonyAlert {
  static Future<Object> handle(
    String method,
    Map<String, dynamic> fields,
  ) async {
    final service = AlertService();
    switch (method) {
      case 'getAlertRuleTargets':
        switch (fields['type'] as String) {
          case 'disk':
            return [
              for (final item in await service.listDisks())
                {'id': item.path, 'label': item.path},
            ];
          case 'ssl':
            return [
              for (final item
                  in await WebsiteCertificateService().listCertificates(
                    orderBy: 'updated_at',
                  ))
                if (item.id != null)
                  {
                    'id': '${item.id}',
                    'label': item.primaryDomain ?? '${item.id}',
                  },
            ];
          case 'siteEndTime':
            final earliestExpiry = DateTime.utc(1970, 1, 2);
            return [
              for (final item in await WebsiteRepository().listWebsites())
                if (item.id != null &&
                    (DateTime.tryParse(
                          item.expireDate ?? '',
                        )?.isBefore(earliestExpiry) !=
                        true))
                  {
                    'id': '${item.id}',
                    'label': item.primaryDomain ?? '${item.id}',
                  },
            ];
          case 'clams':
            return [
              for (final item in await service.listClams())
                {'id': '${item.id}', 'label': item.name},
            ];
          case 'cronJob':
            return [
              for (final item in await service.listCronJobs())
                {'id': '${item.id}', 'label': item.name, 'type': item.type},
            ];
        }
        throw ArgumentError.value(fields['type'], 'type');
      case 'saveAlertRule':
        final id = fields['id'] as int?;
        final methods = (fields['methods'] as List).cast<String>();
        final request = <String, dynamic>{
          ...fields,
          'method': methods.join(','),
        };
        final mode = fields['alertTriggerMode'] as String?;
        if (mode != null) {
          final raw = fields['advancedParams'] as String?;
          final existing = raw == null || raw.isEmpty
              ? <String, dynamic>{}
              : Map<String, dynamic>.from(jsonDecode(raw) as Map);
          request['advancedParams'] = jsonEncode({
            ...existing,
            'alertTriggerMode': mode,
          });
        }
        if (id == null) {
          await service.createAlert(AlertCreate.fromJson(request));
        } else {
          await service.updateAlert(AlertUpdate.fromJson(request));
        }
      case 'getAlertWebhookPresets':
        return {
          for (final preset in AlertWebhookPresets.values)
            if (preset != 'custom')
              (preset == 'teams' ? 'teamsWorkflows' : preset):
                  AlertWebhookPresets.template(preset),
        };
      case 'saveAlertWebhook':
        final displayName = (fields['title'] as String).trim();
        await service.saveConfig(
          AlertConfigUpdate(
            id: fields['id'] as int? ?? 0,
            type: 'custom',
            title: displayName,
            config: _webhookConfig(fields, displayName),
            status: fields['status'] as String? ?? 'Enable',
            displayName: displayName,
            revision: fields['revision'] as String?,
          ),
        );
      case 'testAlertWebhook':
        final displayName = (fields['title'] as String).trim();
        return alertConfigTestResultPayload(
          await service.testConfig(
            AlertConfigTest(
              id: fields['id'] as int?,
              type: 'custom',
              config: _webhookConfig(fields, displayName),
            ),
          ),
        );
      default:
        throw ArgumentError.value(method, 'method');
    }
    return {'success': true};
  }

  static String _webhookConfig(
    Map<String, dynamic> fields,
    String displayName,
  ) {
    final bodyType = fields['bodyType'] as String;
    final urlAction = fields['urlAction'] as String;
    return jsonEncode({
      'schemaVersion': 1,
      'displayName': displayName,
      'preset': fields['preset'] as String,
      'method': 'POST',
      'url': {
        'action': urlAction,
        if (urlAction == 'replace') 'value': fields['webhookUrl'] as String,
      },
      'body': {
        'type': bodyType,
        if (bodyType == 'form')
          'fields': fields['formPairs'] as List
        else
          'template': fields['template'] as String,
      },
      'headers': fields['headers'] as List,
    });
  }
}
