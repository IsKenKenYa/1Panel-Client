part of 'website_ssl_accounts_page.dart';

extension _WebsiteSslAccountsActions on _WebsiteSslAccountsBody {
  Future<void> _showDnsDialog(
    BuildContext context,
    WebsiteSslAccountsProvider provider, {
    Map<String, dynamic>? existing,
  }) async {
    final l10n = context.l10n;
    final isEdit = existing != null;
    final id = isEdit ? provider.resolveAccountId(existing) : null;
    final initialAuthorization = _normalizeAuthorizationMap(
      existing?['authorization'],
    );

    final nameController = TextEditingController(
      text:
          _readString(existing ?? const <String, dynamic>{}, const ['name']) ==
                  '-'
              ? ''
              : _readString(existing!, const ['name']),
    );
    final typeController = TextEditingController(
      text:
          _readString(existing ?? const <String, dynamic>{}, const ['type']) ==
                  '-'
              ? ''
              : _readString(existing!, const ['type']),
    );
    final authorizationController =
        TextEditingController(text: jsonEncode(initialAuthorization));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isEdit
                ? l10n.websitesSslAccountsEditDnsAction
                : l10n.websitesSslAccountsCreateDnsAction,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.commonName),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: typeController,
                  decoration: InputDecoration(
                    labelText: l10n.websitesSslAccountsTypeLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorizationController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: l10n.websitesSslAccountsAuthorizationLabel,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final type = typeController.text.trim();
                if (name.isEmpty) {
                  _showError(
                    context,
                    l10n.websitesSslAccountsValidationNameRequired,
                  );
                  return;
                }
                if (type.isEmpty) {
                  _showError(
                    context,
                    l10n.websitesSslAccountsValidationTypeRequired,
                  );
                  return;
                }

                final authorization = _parseAuthorization(
                  authorizationController.text,
                );
                if (authorization == null) {
                  _showError(
                    context,
                    l10n.websitesSslAccountsValidationAuthorizationInvalid,
                  );
                  return;
                }
                if (authorization.isEmpty) {
                  _showError(
                    context,
                    l10n.websitesSslAccountsValidationAuthorizationRequired,
                  );
                  return;
                }

                late final bool ok;
                if (isEdit) {
                  if (id == null) {
                    _showError(context, l10n.websitesSslAccountsMissingId);
                    return;
                  }
                  ok = await provider.updateDnsAccount(
                    id: id,
                    name: name,
                    type: type,
                    authorization: authorization,
                  );
                } else {
                  ok = await provider.createDnsAccount(
                    name: name,
                    type: type,
                    authorization: authorization,
                  );
                }

                if (!context.mounted) {
                  return;
                }
                if (ok) {
                  Navigator.of(dialogContext).pop();
                  _showSuccess(context, l10n.websitesOperateSuccess);
                  return;
                }
                _showError(
                  context,
                  provider.operationError ?? l10n.websitesOperateFailed,
                );
              },
              child: Text(l10n.commonSave),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    typeController.dispose();
    authorizationController.dispose();
  }

  Future<void> _showAcmeDialog(
    BuildContext context,
    WebsiteSslAccountsProvider provider, {
    Map<String, dynamic>? existing,
  }) async {
    final l10n = context.l10n;
    final isEdit = existing != null;
    final id = isEdit ? provider.resolveAccountId(existing) : null;

    final emailController = TextEditingController(
      text:
          _readString(existing ?? const <String, dynamic>{}, const ['email']) ==
                  '-'
              ? ''
              : _readString(existing!, const ['email']),
    );

    var type =
        _readString(existing ?? const <String, dynamic>{}, const ['type']);
    if (type == '-') {
      type = 'letsencrypt';
    }
    var keyType = '2048';
    var useProxy =
        _readBool(existing ?? const <String, dynamic>{}, const ['useProxy']);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                isEdit
                    ? l10n.websitesSslAccountsEditAcmeAction
                    : l10n.websitesSslAccountsCreateAcmeAction,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      enabled: !isEdit,
                      decoration: InputDecoration(
                          labelText: l10n.websitesSslAccountsEmailLabel),
                    ),
                    const SizedBox(height: 12),
                    if (!isEdit)
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: InputDecoration(
                          labelText: l10n.websitesSslAccountsTypeLabel,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'letsencrypt',
                            child: Text('letsencrypt'),
                          ),
                          DropdownMenuItem(
                            value: 'zerossl',
                            child: Text('zerossl'),
                          ),
                          DropdownMenuItem(
                            value: 'buypass',
                            child: Text('buypass'),
                          ),
                          DropdownMenuItem(
                            value: 'google',
                            child: Text('google'),
                          ),
                          DropdownMenuItem(
                            value: 'custom',
                            child: Text('custom'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => type = value);
                        },
                      )
                    else
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.websitesSslAccountsTypeLabel),
                        subtitle: Text(type),
                      ),
                    const SizedBox(height: 12),
                    if (!isEdit)
                      DropdownButtonFormField<String>(
                        initialValue: keyType,
                        decoration: InputDecoration(
                          labelText: l10n.websitesSslAccountsKeyTypeLabel,
                        ),
                        items: const [
                          DropdownMenuItem(value: '2048', child: Text('2048')),
                          DropdownMenuItem(value: '3072', child: Text('3072')),
                          DropdownMenuItem(value: '4096', child: Text('4096')),
                          DropdownMenuItem(value: '8192', child: Text('8192')),
                          DropdownMenuItem(value: 'P256', child: Text('P256')),
                          DropdownMenuItem(value: 'P384', child: Text('P384')),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => keyType = value);
                        },
                      ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: useProxy,
                      onChanged: (value) => setState(() => useProxy = value),
                      title: Text(l10n.websitesSslAccountsUseProxyLabel),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.commonCancel),
                ),
                FilledButton(
                  onPressed: () async {
                    final email = emailController.text.trim();
                    if (!isEdit && email.isEmpty) {
                      _showError(
                        context,
                        l10n.websitesSslAccountsValidationEmailRequired,
                      );
                      return;
                    }

                    late final bool ok;
                    if (isEdit) {
                      if (id == null) {
                        _showError(context, l10n.websitesSslAccountsMissingId);
                        return;
                      }
                      ok = await provider.updateAcmeAccount(
                        id: id,
                        useProxy: useProxy,
                      );
                    } else {
                      ok = await provider.createAcmeAccount(
                        email: email,
                        type: type,
                        keyType: keyType,
                        useProxy: useProxy,
                      );
                    }

                    if (!context.mounted) {
                      return;
                    }
                    if (ok) {
                      Navigator.of(dialogContext).pop();
                      _showSuccess(context, l10n.websitesOperateSuccess);
                      return;
                    }
                    _showError(
                      context,
                      provider.operationError ?? l10n.websitesOperateFailed,
                    );
                  },
                  child: Text(l10n.commonSave),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
  }

  Future<void> _showCertificateAuthorityDialog(
    BuildContext context,
    WebsiteSslAccountsProvider provider,
  ) async {
    final l10n = context.l10n;
    final nameController = TextEditingController();
    final commonNameController = TextEditingController();
    final countryController = TextEditingController();
    final organizationController = TextEditingController();
    final organizationUintController = TextEditingController();
    final provinceController = TextEditingController();
    final cityController = TextEditingController();
    var keyType = '2048';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.websitesSslAccountsCreateCaAction),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: l10n.commonName),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commonNameController,
                      decoration: InputDecoration(
                        labelText: l10n.websitesSslAccountsCommonNameLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: countryController,
                      decoration: InputDecoration(
                        labelText: l10n.websitesSslAccountsCountryLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: organizationController,
                      decoration: InputDecoration(
                        labelText: l10n.websitesSslAccountsOrganizationLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: organizationUintController,
                      decoration: InputDecoration(
                        labelText:
                            l10n.websitesSslAccountsOrganizationUnitLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: keyType,
                      decoration: InputDecoration(
                        labelText: l10n.websitesSslAccountsKeyTypeLabel,
                      ),
                      items: const [
                        DropdownMenuItem(value: '2048', child: Text('2048')),
                        DropdownMenuItem(value: '3072', child: Text('3072')),
                        DropdownMenuItem(value: '4096', child: Text('4096')),
                        DropdownMenuItem(value: '8192', child: Text('8192')),
                        DropdownMenuItem(value: 'P256', child: Text('P256')),
                        DropdownMenuItem(value: 'P384', child: Text('P384')),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => keyType = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: provinceController,
                      decoration: InputDecoration(
                        labelText: l10n.websitesSslAccountsProvinceLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cityController,
                      decoration: InputDecoration(
                        labelText: l10n.websitesSslAccountsCityLabel,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.commonCancel),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final commonName = commonNameController.text.trim();
                    final country = countryController.text.trim();
                    final organization = organizationController.text.trim();
                    if (name.isEmpty) {
                      _showError(
                        context,
                        l10n.websitesSslAccountsValidationNameRequired,
                      );
                      return;
                    }
                    if (commonName.isEmpty ||
                        country.isEmpty ||
                        organization.isEmpty) {
                      _showError(
                        context,
                        l10n.websitesSslAccountsValidationRequiredFields,
                      );
                      return;
                    }

                    final ok = await provider.createCertificateAuthority(
                      name: name,
                      commonName: commonName,
                      country: country,
                      organization: organization,
                      keyType: keyType,
                      organizationUint: organizationUintController.text.trim(),
                      province: provinceController.text.trim(),
                      city: cityController.text.trim(),
                    );

                    if (!context.mounted) {
                      return;
                    }
                    if (ok) {
                      Navigator.of(dialogContext).pop();
                      _showSuccess(context, l10n.websitesOperateSuccess);
                      return;
                    }
                    _showError(
                      context,
                      provider.operationError ?? l10n.websitesOperateFailed,
                    );
                  },
                  child: Text(l10n.commonSave),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    commonNameController.dispose();
    countryController.dispose();
    organizationController.dispose();
    organizationUintController.dispose();
    provinceController.dispose();
    cityController.dispose();
  }

  Future<void> _showObtainDialog(
    BuildContext context,
    WebsiteSslAccountsProvider provider,
    Map<String, dynamic> item,
  ) async {
    final l10n = context.l10n;
    final id = provider.resolveAccountId(item);
    if (id == null) {
      _showError(context, l10n.websitesSslAccountsMissingId);
      return;
    }

    final domainsController = TextEditingController();
    final timeController = TextEditingController(text: '1');
    var unit = 'year';
    var keyType = '2048';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.websitesSslAccountsObtainAction),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: domainsController,
                      decoration: InputDecoration(
                        labelText: l10n.websitesSslAccountsDomainsLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: keyType,
                      decoration: InputDecoration(
                        labelText: l10n.websitesSslAccountsKeyTypeLabel,
                      ),
                      items: const [
                        DropdownMenuItem(value: '2048', child: Text('2048')),
                        DropdownMenuItem(value: '3072', child: Text('3072')),
                        DropdownMenuItem(value: '4096', child: Text('4096')),
                        DropdownMenuItem(value: '8192', child: Text('8192')),
                        DropdownMenuItem(value: 'P256', child: Text('P256')),
                        DropdownMenuItem(value: 'P384', child: Text('P384')),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => keyType = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: timeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.websitesSslAccountsTimeLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: unit,
                      decoration: InputDecoration(
                        labelText: l10n.websitesSslAccountsUnitLabel,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'day', child: Text('day')),
                        DropdownMenuItem(value: 'month', child: Text('month')),
                        DropdownMenuItem(value: 'year', child: Text('year')),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => unit = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.commonCancel),
                ),
                FilledButton(
                  onPressed: () async {
                    final domains = domainsController.text.trim();
                    final time = int.tryParse(timeController.text.trim());
                    if (domains.isEmpty) {
                      _showError(
                        context,
                        l10n.websitesSslAccountsValidationDomainsRequired,
                      );
                      return;
                    }
                    if (time == null || time <= 0) {
                      _showError(
                        context,
                        l10n.websitesSslAccountsValidationTimeInvalid,
                      );
                      return;
                    }
                    final ok = await provider.obtainCertificateByAuthority(
                      id: id,
                      domains: domains,
                      keyType: keyType,
                      time: time,
                      unit: unit,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    if (ok) {
                      Navigator.of(dialogContext).pop();
                      _showSuccess(context, l10n.websitesOperateSuccess);
                      return;
                    }
                    _showError(
                      context,
                      provider.operationError ?? l10n.websitesOperateFailed,
                    );
                  },
                  child: Text(l10n.commonConfirm),
                ),
              ],
            );
          },
        );
      },
    );

    domainsController.dispose();
    timeController.dispose();
  }

  Future<void> _renewCertificate(
    BuildContext context,
    WebsiteSslAccountsProvider provider,
    Map<String, dynamic> item,
  ) async {
    final l10n = context.l10n;
    final sslId = provider.resolveCertificateSslId(item);
    if (sslId == null) {
      _showError(context, l10n.websitesSslAccountsMissingSslId);
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.websitesSslAccountsRenewAction),
            content: Text(l10n.websitesSslAccountsRenewConfirmMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.commonConfirm),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    final ok = await provider.renewCertificateByAuthority(sslId);
    if (!context.mounted) {
      return;
    }
    if (ok) {
      _showSuccess(context, l10n.websitesOperateSuccess);
      return;
    }
    _showError(context, provider.operationError ?? l10n.websitesOperateFailed);
  }

  Future<void> _downloadCertificate(
    BuildContext context,
    WebsiteSslAccountsProvider provider,
    Map<String, dynamic> item,
  ) async {
    final l10n = context.l10n;
    final id = provider.resolveAccountId(item);
    if (id == null) {
      _showError(context, l10n.websitesSslAccountsMissingId);
      return;
    }

    final link = await provider.downloadCertificateAuthorityFile(id);
    if (!context.mounted) {
      return;
    }
    if (link == null) {
      _showError(
          context, provider.operationError ?? l10n.websitesOperateFailed);
      return;
    }
    _showSuccess(context, l10n.websitesSslAccountsDownloadSuccess);
  }

  Future<void> _confirmDeleteDns(
    BuildContext context,
    WebsiteSslAccountsProvider provider,
    Map<String, dynamic> item,
  ) async {
    final l10n = context.l10n;
    final id = provider.resolveAccountId(item);
    if (id == null) {
      _showError(context, l10n.websitesSslAccountsMissingId);
      return;
    }

    final name = _readString(item, const ['name']);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.commonDelete),
            content: Text(l10n.websitesSslAccountsDeleteDnsMessage(name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.commonDelete),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    final ok = await provider.deleteDnsAccount(id);
    if (!context.mounted) {
      return;
    }
    if (ok) {
      _showSuccess(context, l10n.websitesOperateSuccess);
      return;
    }
    _showError(context, provider.operationError ?? l10n.websitesOperateFailed);
  }

  Future<void> _confirmDeleteAcme(
    BuildContext context,
    WebsiteSslAccountsProvider provider,
    Map<String, dynamic> item,
  ) async {
    final l10n = context.l10n;
    final id = provider.resolveAccountId(item);
    if (id == null) {
      _showError(context, l10n.websitesSslAccountsMissingId);
      return;
    }

    final email = _readString(item, const ['email']);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.commonDelete),
            content: Text(l10n.websitesSslAccountsDeleteAcmeMessage(email)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.commonDelete),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    final ok = await provider.deleteAcmeAccount(id);
    if (!context.mounted) {
      return;
    }
    if (ok) {
      _showSuccess(context, l10n.websitesOperateSuccess);
      return;
    }
    _showError(context, provider.operationError ?? l10n.websitesOperateFailed);
  }

  Future<void> _confirmDeleteCertificateAuthority(
    BuildContext context,
    WebsiteSslAccountsProvider provider,
    Map<String, dynamic> item,
  ) async {
    final l10n = context.l10n;
    final id = provider.resolveAccountId(item);
    if (id == null) {
      _showError(context, l10n.websitesSslAccountsMissingId);
      return;
    }

    final name = _readString(item, const ['name']);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.commonDelete),
            content: Text(l10n.websitesSslAccountsDeleteCaMessage(name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.commonDelete),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    final ok = await provider.deleteCertificateAuthority(id);
    if (!context.mounted) {
      return;
    }
    if (ok) {
      _showSuccess(context, l10n.websitesOperateSuccess);
      return;
    }
    _showError(context, provider.operationError ?? l10n.websitesOperateFailed);
  }

  Map<String, dynamic>? _parseAuthorization(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        return null;
      }
      return decoded.map(
        (key, dynamic value) => MapEntry(key.toString(), value.toString()),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _normalizeAuthorizationMap(dynamic value) {
    if (value is! Map) {
      return <String, dynamic>{};
    }
    return value.map(
      (dynamic key, dynamic value) => MapEntry(
        key.toString(),
        value.toString(),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
