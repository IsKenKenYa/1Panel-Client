using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Windows.UI;

namespace OnePanelNativeHost;

/// <summary>
/// B1 网站配置中心 · HTTPS Tab。语义照搬上游
/// views/website/website/config/basic/https/index.vue 与
/// views/website/website/components/https/index.vue：
/// - enable 开关（关闭时若服务端已启用则弹禁用确认，上游 disableHTTPSHelper 语义；
///   开启时默认勾选 HSTS）；
/// - httpConfig 三选一：HTTPToHTTPS / HTTPAlso / HTTPSOnly；
/// - type=existed 选已有证书（GetWebsiteCertificatesAsync 数据源，
///   下拉展示 primaryDomain + expireDate）；type=manual 手动粘贴 certificate/privateKey；
/// - TLS 协议复选（默认 TLSv1.3 + TLSv1.2）；HSTS / 包含子域 / HTTP3 复选；
///   加密算法多行文本（空时回落客户端默认套组）；
/// - 保存 → ConfirmDialog 确认 → UpdateWebsiteHttpsAsync（契约 12 字段全量提交）。
/// 桌面布局为三张卡片（基本 / 证书 / 协议与算法）+ 底部保存行。
/// </summary>
public static class WebsiteConfigHttpsTab
{
    /// <summary>algorithm 空值时的客户端默认套组（主控指定的精简套组）。</summary>
    private const string DefaultAlgorithm =
        "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:" +
        "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384";

    public static FrameworkElement Build(int websiteId, string websiteName)
    {
        // ── 表单状态（闭包持有；Tab 切换即整体重建，无需生命周期管理） ──
        bool enable = false;
        bool loadedEnable = false;          // 服务端已保存的 enable（关闭确认判定，上游 resData.enable）
        string httpConfig = "HTTPToHTTPS";
        string type = "existed";
        long? websiteSSLId = null;
        var protocols = new List<string> { "TLSv1.3", "TLSv1.2" };
        bool hsts = true;
        bool hstsSub = false;
        bool http3 = false;
        var certs = new List<CertificateOption>();
        bool suppress = false;              // 编程赋值期间抑制事件（加载/回滚）

        var toast = new ErrorToast();
        var statusText = WebsiteConfigHelpers.StatusText();
        var loadErrorInfo = new InfoBar
        {
            Severity = InfoBarSeverity.Error,
            IsClosable = false,
            IsOpen = false,
            Message = L10n.T("hostHttpsLoadFailed", "Failed to load HTTPS configuration."),
        };
        var loadingRing = new ProgressRing
        {
            IsActive = true,
            Width = 32,
            Height = 32,
            HorizontalAlignment = HorizontalAlignment.Center,
            Margin = new Thickness(0, 24, 0, 0),
        };

        // ── 控件 ──
        var enableToggle = WebsiteConfigHelpers.BuildToggle(false);
        var portText = WebsiteConfigHelpers.StatusText();   // 只读展示 httpsPort（存在时）
        var ipWarnText = WebsiteConfigHelpers.StatusText(); // 上游 ipWebsiteWarn 提示

        var httpConfigRadios = new RadioButtons
        {
            Items =
            {
                L10n.T("hostHttpsHttpConfigToHttps", "Redirect to HTTPS"),
                L10n.T("hostHttpsHttpConfigAlso", "Allow direct HTTP requests"),
                L10n.T("hostHttpsHttpConfigOnly", "Block HTTP requests"),
            },
            SelectedIndex = 0,
        };
        var httpConfigLabel = new TextBlock
        {
            Text = L10n.T("hostHttpsHttpConfigLabel", "HTTP options"),
            FontSize = 13,
        };
        httpConfigRadios.SelectionChanged += (s, e) =>
        {
            if (suppress) return;
            httpConfig = httpConfigRadios.SelectedIndex switch
            {
                1 => "HTTPAlso",
                2 => "HTTPSOnly",
                _ => "HTTPToHTTPS",
            };
        };

        var typeCombo = new ComboBox
        {
            MinWidth = 320,
            Items =
            {
                L10n.T("hostHttpsTypeExisted", "Existing certificate"),
                L10n.T("hostHttpsTypeManual", "Import certificate manually"),
            },
            SelectedIndex = 0,
        };

        var certCombo = new ComboBox
        {
            MinWidth = 320,
            MaxDropDownHeight = 320,
            PlaceholderText = L10n.T("hostHttpsCertSelectPlaceholder", "Select certificate"),
        };
        var certEmptyText = WebsiteConfigHelpers.StatusText();
        var certInfoHost = new StackPanel { Orientation = Orientation.Vertical };
        var certPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 8 };
        certPanel.Children.Add(certCombo);
        certPanel.Children.Add(certEmptyText);
        certPanel.Children.Add(certInfoHost);

        var certBox = WebsiteConfigHelpers.BuildTextBox(
            L10n.T("hostHttpsCertificateLabel", "Certificate"), multiline: true, minHeight: 120);
        var keyBox = WebsiteConfigHelpers.BuildTextBox(
            L10n.T("hostHttpsPrivateKeyLabel", "Private key"), multiline: true, minHeight: 120);
        var manualPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 8 };
        manualPanel.Children.Add(certBox);
        manualPanel.Children.Add(keyBox);

        // TLS 协议复选组（value, 显示文案），上游 supportProtocol 复选组。
        var protocolChecks = new List<(string Value, CheckBox Box)>
        {
            ("TLSv1.3", new CheckBox { Content = "TLS 1.3" }),
            ("TLSv1.2", new CheckBox { Content = "TLS 1.2" }),
            ("TLSv1.1", new CheckBox { Content = "TLS 1.1 " + L10n.T("hostHttpsInsecureSuffix", "(not safe)") }),
            ("TLSv1", new CheckBox { Content = "TLS 1.0 " + L10n.T("hostHttpsInsecureSuffix", "(not safe)") }),
        };
        var protocolPanel = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 12 };
        foreach (var (value, box) in protocolChecks)
        {
            var protocolValue = value;
            box.Checked += (s, e) => { if (!protocols.Contains(protocolValue)) protocols.Add(protocolValue); };
            box.Unchecked += (s, e) => protocols.Remove(protocolValue);
            protocolPanel.Children.Add(box);
        }

        var hstsCheck = new CheckBox { Content = L10n.T("websiteHttpsHsts", "HSTS") };
        var hstsSubCheck = new CheckBox
        {
            Content = L10n.T("hostHttpsHstsSubDomainsLabel", "HSTS include subdomains"),
        };
        var http3Check = new CheckBox { Content = L10n.T("hostHttpsHttp3Label", "HTTP3") };
        hstsCheck.Checked += (s, e) => hsts = true;
        hstsCheck.Unchecked += (s, e) => hsts = false;
        hstsSubCheck.Checked += (s, e) => hstsSub = true;
        hstsSubCheck.Unchecked += (s, e) => hstsSub = false;
        http3Check.Checked += (s, e) => http3 = true;
        http3Check.Unchecked += (s, e) => http3 = false;

        var algorithmBox = WebsiteConfigHelpers.BuildTextBox(
            L10n.T("hostHttpsAlgorithmLabel", "Encryption algorithm"), DefaultAlgorithm, multiline: true, minHeight: 88);

        var saveButton = new Button
        {
            Content = L10n.T("commonSave", "Save"),
            Style = (Style)Application.Current.Resources["AccentButtonStyle"],
        };

        // ── 布局（须先于局部函数声明：局部函数引用这些容器变量） ──
        var helperInfo = new InfoBar
        {
            Severity = InfoBarSeverity.Informational,
            IsClosable = false,
            IsOpen = true,
            Message = L10n.T("hostHttpsHelper",
                "Note: Do not use SSL certificates for illegal websites.\n" +
                "If HTTPS access cannot be used after enabling, check whether the firewall has released port 443."),
        };

        var basicCard = WebsiteConfigHelpers.BuildCard(
            L10n.T("hostHttpsSectionBasic", "Basic"), out var basicPanel);
        basicPanel.Children.Add(enableToggle);
        basicPanel.Children.Add(portText);
        basicPanel.Children.Add(ipWarnText);
        basicPanel.Children.Add(httpConfigLabel);
        basicPanel.Children.Add(httpConfigRadios);

        var certCardHost = WebsiteConfigHelpers.BuildCard(
            L10n.T("hostHttpsSectionCert", "Certificate settings"), out var certSettingsPanel);
        certSettingsPanel.Children.Add(new TextBlock
        {
            Text = L10n.T("hostHttpsTypeLabel", "SSL options"),
            FontSize = 13,
        });
        certSettingsPanel.Children.Add(typeCombo);
        certSettingsPanel.Children.Add(certPanel);
        certSettingsPanel.Children.Add(manualPanel);

        var advancedCardHost = WebsiteConfigHelpers.BuildCard(
            L10n.T("hostHttpsSectionAdvanced", "Protocol settings"), out var advancedPanel);
        advancedPanel.Children.Add(new TextBlock
        {
            Text = L10n.T("hostHttpsProtocolLabel", "Protocol version"),
            FontSize = 13,
        });
        advancedPanel.Children.Add(protocolPanel);
        advancedPanel.Children.Add(hstsCheck);
        advancedPanel.Children.Add(new TextBlock
        {
            Text = L10n.T("hostHttpsHstsHelper", "Enabling HSTS can increase website security"),
            FontSize = 12,
            Foreground = new Microsoft.UI.Xaml.Media.SolidColorBrush(Colors.Gray),
        });
        advancedPanel.Children.Add(hstsSubCheck);
        advancedPanel.Children.Add(http3Check);
        advancedPanel.Children.Add(new TextBlock
        {
            Text = L10n.T("hostHttpsHttp3Helper",
                "HTTP/3 offers faster connections, but not all browsers support it; " +
                "enabling it may make the site unreachable for some browsers."),
            FontSize = 12,
            Foreground = new Microsoft.UI.Xaml.Media.SolidColorBrush(Colors.Gray),
        });
        advancedPanel.Children.Add(algorithmBox);

        var saveRow = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 12 };
        saveRow.Children.Add(saveButton);
        saveRow.Children.Add(statusText);

        var formHost = new StackPanel { Orientation = Orientation.Vertical, Spacing = 12 };
        formHost.Children.Add(basicCard);
        formHost.Children.Add(certCardHost);
        formHost.Children.Add(advancedCardHost);
        formHost.Children.Add(saveRow);

        var column = new StackPanel { Orientation = Orientation.Vertical, Spacing = 12 };
        column.Children.Add(helperInfo);
        column.Children.Add(loadErrorInfo);
        column.Children.Add(loadingRing);
        column.Children.Add(formHost);

        var scroll = new ScrollViewer
        {
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            Padding = new Thickness(4, 0, 12, 12),
            Content = column,
        };

        // 根网格两行：内容 + 底部浮动 toast（与其他模块页同型）。
        var root = new Grid();
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        Grid.SetRow(scroll, 0);
        root.Children.Add(scroll);
        toast.VerticalAlignment = VerticalAlignment.Bottom;
        Grid.SetRow(toast, 1);
        root.Children.Add(toast);

        // ── 展示状态推导 ──
        // enable 决定配置区/证书/协议/保存行是否可见（上游 collapse-transition 语义）；
        // type 决定已有证书下拉 or 手动粘贴。
        void UpdateVisibility()
        {
            var basicOn = enable ? Visibility.Visible : Visibility.Collapsed;
            portText.Visibility = basicOn;
            ipWarnText.Visibility = basicOn;
            httpConfigLabel.Visibility = basicOn;
            httpConfigRadios.Visibility = basicOn;
            certPanel.Visibility = type == "existed" ? Visibility.Visible : Visibility.Collapsed;
            manualPanel.Visibility = type == "manual" ? Visibility.Visible : Visibility.Collapsed;
            hstsSubCheck.Visibility = hsts ? Visibility.Visible : Visibility.Collapsed;
            certCardHost.Visibility = basicOn;
            advancedCardHost.Visibility = basicOn;
            saveRow.Visibility = basicOn;
        }

        void UpdateCertInfo()
        {
            certInfoHost.Children.Clear();
            if (type != "existed" || websiteSSLId is null || websiteSSLId <= 0) return;

            var selected = certs.Find(c => c.Id == websiteSSLId.Value);
            if (selected == null) return;

            certInfoHost.Children.Add(WebsiteConfigHelpers.BuildInfoBag(new[]
            {
                new KeyValuePair<string, string>(
                    L10n.T("websitesSslPrimaryDomain", "Primary domain"), selected.PrimaryDomain),
                new KeyValuePair<string, string>(
                    L10n.T("websitesSslExpireDate", "Expires"), selected.ExpireDate),
            }));
        }

        void RebuildCertItems()
        {
            suppress = true;
            certCombo.Items.Clear();
            foreach (var cert in certs)
            {
                var itemContent = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 10 };
                itemContent.Children.Add(new TextBlock { Text = cert.PrimaryDomain });
                if (!string.IsNullOrWhiteSpace(cert.ExpireDate))
                {
                    itemContent.Children.Add(new TextBlock
                    {
                        Text = cert.ExpireDate,
                        FontSize = 12,
                        Foreground = new Microsoft.UI.Xaml.Media.SolidColorBrush(Colors.Gray),
                    });
                }
                certCombo.Items.Add(new ComboBoxItem { Content = itemContent, Tag = cert.Id });
            }
            certEmptyText.Text = certs.Count == 0
                ? L10n.T("hostHttpsCertEmpty", "No certificates available. Import one from the SSL certificate page first.")
                : string.Empty;
            certEmptyText.Visibility = certs.Count == 0 ? Visibility.Visible : Visibility.Collapsed;

            var matchIndex = certs.FindIndex(c => c.Id == websiteSSLId);
            certCombo.SelectedIndex = matchIndex;
            suppress = false;
        }

        void ApplyLoadedState()
        {
            suppress = true;
            enableToggle.IsOn = enable;
            httpConfigRadios.SelectedIndex = httpConfig switch
            {
                "HTTPAlso" => 1,
                "HTTPSOnly" => 2,
                _ => 0,
            };
            typeCombo.SelectedIndex = type == "manual" ? 1 : 0;
            hstsCheck.IsChecked = hsts;
            hstsSubCheck.IsChecked = hstsSub;
            http3Check.IsChecked = http3;
            suppress = false;

            foreach (var (value, box) in protocolChecks)
            {
                box.IsChecked = protocols.Contains(value);
            }

            RebuildCertItems();
            UpdateVisibility();
            UpdateCertInfo();
        }

        // ── 事件 ──
        typeCombo.SelectionChanged += (s, e) =>
        {
            if (suppress) return;
            type = typeCombo.SelectedIndex == 1 ? "manual" : "existed";
            if (type != "existed")
            {
                websiteSSLId = null; // 上游 handleTypeChange：切离 existed 清空已选证书
            }
            UpdateVisibility();
            UpdateCertInfo();
        };

        certCombo.SelectionChanged += (s, e) =>
        {
            if (suppress) return;
            websiteSSLId = (certCombo.SelectedItem as ComboBoxItem)?.Tag as long?;
            UpdateCertInfo();
        };

        enableToggle.Toggled += async (s, e) =>
        {
            if (suppress) return;
            if (enableToggle.IsOn)
            {
                enable = true;
                hsts = true;              // 上游 changeEnable：开启时默认勾选 HSTS
                hstsCheck.IsChecked = true;
                UpdateVisibility();
                return;
            }

            // 服务端本就未启用时，直接隐藏表单即可（无 disable 确认场景）。
            if (!loadedEnable)
            {
                enable = false;
                UpdateVisibility();
                return;
            }

            // 上游 disableHTTPSHelper：关闭 HTTPS 删除证书相关配置，需确认。
            var xamlRoot = WebsiteConfigHelpers.GetXamlRoot(enableToggle);
            if (xamlRoot == null)
            {
                suppress = true;
                enableToggle.IsOn = true;
                suppress = false;
                return;
            }

            suppress = true;
            var confirmed = await ConfirmDialog.ShowAsync(
                xamlRoot,
                L10n.T("hostHttpsDisableTitle", "Disable HTTPS"),
                L10n.T("hostHttpsDisableConfirm",
                    "Disabling HTTPS will delete the certificate related configuration. Continue?"),
                L10n.T("commonConfirm", "Confirm"),
                L10n.T("commonCancel", "Cancel"),
                isDestructive: true);

            if (!confirmed)
            {
                enableToggle.IsOn = true; // 取消：回滚开关
                suppress = false;
                return;
            }
            suppress = false;

            enable = false;
            UpdateVisibility();
            await SubmitAsync(disabling: true);
        };

        saveButton.Click += async (s, e) => await SubmitAsync(disabling: false);

        async Task SubmitAsync(bool disabling)
        {
            if (!disabling)
            {
                var validationError = Validate();
                if (validationError != null)
                {
                    WebsiteConfigHelpers.SetStatus(statusText, validationError, error: true);
                    return;
                }
            }
            WebsiteConfigHelpers.SetStatus(statusText, null);

            var xamlRoot = WebsiteConfigHelpers.GetXamlRoot(saveButton);
            if (xamlRoot == null) return;

            // 保存门禁：ConfirmDialog 确认后全量提交（与上游表单整体提交同型）。
            var confirmed = await ConfirmDialog.ShowAsync(
                xamlRoot,
                L10n.T("hostHttpsSaveConfirmTitle", "Save HTTPS settings"),
                string.Format(
                    L10n.T("hostHttpsSaveConfirm", "Apply the HTTPS configuration to \"{0}\"?"), websiteName),
                L10n.T("commonSave", "Save"),
                L10n.T("commonCancel", "Cancel"));
            if (!confirmed) return;

            saveButton.IsEnabled = false;
            try
            {
                var ok = await WindowsBridge.UpdateWebsiteHttpsAsync(
                    websiteId,
                    disabling ? false : enable,
                    disabling ? "existed" : type,
                    httpConfig,
                    algorithmBox.Text.Trim(),
                    new List<object>(protocols),
                    disabling || type != "existed" ? null : websiteSSLId,
                    !disabling && type == "manual" ? certBox.Text : null,
                    !disabling && type == "manual" ? keyBox.Text : null,
                    hsts,
                    hstsSub,
                    http3);

                if (ok)
                {
                    WebsiteConfigHelpers.SetStatus(
                        statusText, L10n.T("commonSaveSuccess", "Saved successfully"));
                    await LoadAsync(firstLoad: false);
                }
                else
                {
                    toast.Show(L10n.T("websiteHttpsUpdateFailed", "Failed to update HTTPS config"));
                    if (disabling)
                    {
                        // 禁用失败回滚开关与表单可见性。
                        suppress = true;
                        enableToggle.IsOn = true;
                        suppress = false;
                        enable = true;
                        UpdateVisibility();
                    }
                }
            }
            finally
            {
                saveButton.IsEnabled = true;
            }
        }

        string? Validate()
        {
            if (type == "manual" &&
                (string.IsNullOrWhiteSpace(certBox.Text) || string.IsNullOrWhiteSpace(keyBox.Text)))
            {
                return L10n.T("hostHttpsCertRequired", "Certificate and private key are required.");
            }
            if (type == "existed" && (websiteSSLId is null || websiteSSLId <= 0))
            {
                return L10n.T("hostHttpsSelectCertRequired", "Please select a certificate.");
            }
            if (protocols.Count == 0)
            {
                return L10n.T("hostHttpsProtocolRequired", "Select at least one TLS protocol version.");
            }
            if (string.IsNullOrWhiteSpace(algorithmBox.Text))
            {
                return L10n.T("hostHttpsAlgorithmRequired", "Encryption algorithm is required.");
            }
            return null;
        }

        // ── 数据加载（语义照搬上游 get()：仅覆盖非空字段，证书 id>0 时选中 existed） ──
        async Task LoadAsync(bool firstLoad)
        {
            if (firstLoad)
            {
                loadingRing.Visibility = Visibility.Visible;
                formHost.Visibility = Visibility.Collapsed;
                loadErrorInfo.IsOpen = false;
            }

            var config = await WindowsBridge.GetWebsiteHttpsConfigAsync(websiteId);
            if (config == null || config.Value.ValueKind != JsonValueKind.Object)
            {
                if (firstLoad)
                {
                    loadingRing.Visibility = Visibility.Collapsed;
                    loadErrorInfo.IsOpen = true;
                }
                else
                {
                    toast.Show(L10n.T("hostHttpsLoadFailed", "Failed to load HTTPS configuration."));
                }
                return;
            }

            var obj = config.Value;
            enable = WebsiteConfigHelpers.TryGetBool(obj, "enable", false);
            loadedEnable = enable;

            var httpConfigValue = WebsiteConfigHelpers.TryGetString(obj, "httpConfig");
            if (!string.IsNullOrEmpty(httpConfigValue))
            {
                httpConfig = httpConfigValue;
            }

            // 契约透传键为 sslProtocol，上游前端/请求风格为 SSLProtocol：两键兼容。
            var protocolList = ReadStringArray(obj, "sslProtocol") ?? ReadStringArray(obj, "SSLProtocol");
            if (protocolList is { Count: > 0 })
            {
                protocols = protocolList;
            }

            var algorithmValue = WebsiteConfigHelpers.TryGetString(obj, "algorithm");
            algorithmBox.Text = string.IsNullOrWhiteSpace(algorithmValue) ? DefaultAlgorithm : algorithmValue.Trim();

            hsts = WebsiteConfigHelpers.TryGetBool(obj, "hsts", hsts);
            hstsSub = WebsiteConfigHelpers.TryGetBool(obj, "hstsIncludeSubDomains", false);
            http3 = WebsiteConfigHelpers.TryGetBool(obj, "http3", false);

            // 已绑定证书：契约键 ssl / 上游风格 SSL，两键兼容；id>0 时走 existed。
            websiteSSLId = null;
            type = "existed"; // 上游 get() 固定回置 existed（读取响应不含 type）
            foreach (var sslKey in new[] { "ssl", "SSL" })
            {
                if (obj.TryGetProperty(sslKey, out var ssl) && ssl.ValueKind == JsonValueKind.Object)
                {
                    var sslId = WebsiteConfigHelpers.TryGetLong(ssl, "id", 0);
                    if (sslId > 0)
                    {
                        websiteSSLId = sslId;
                    }
                    break;
                }
            }

            // httpsPort 只读展示（存在时），上游以纯文本展示该端口。
            var portValue = WebsiteConfigHelpers.TryGetString(obj, "httpsPort");
            if (string.IsNullOrEmpty(portValue) &&
                obj.TryGetProperty("httpsPort", out var portProp) &&
                portProp.ValueKind == JsonValueKind.Number)
            {
                portValue = portProp.GetRawText();
            }
            portText.Text = string.IsNullOrEmpty(portValue)
                ? string.Empty
                : L10n.T("hostHttpsPortLabel", "HTTPS port") + ": " + portValue;
            portText.Visibility = string.IsNullOrEmpty(portValue) ? Visibility.Collapsed : Visibility.Visible;
            ipWarnText.Text = L10n.T("hostHttpsIpWarn",
                "Websites with IP as domain names need to be set as default site to be accessed normally.");

            loadingRing.Visibility = Visibility.Collapsed;
            loadErrorInfo.IsOpen = false;
            formHost.Visibility = Visibility.Visible;
            ApplyLoadedState();

            await LoadCertificatesAsync();
        }

        async Task LoadCertificatesAsync()
        {
            var result = await WindowsBridge.GetWebsiteCertificatesAsync();
            certs.Clear();
            if (result is JsonElement array && array.ValueKind == JsonValueKind.Array)
            {
                foreach (var item in array.EnumerateArray())
                {
                    if (item.ValueKind != JsonValueKind.Object) continue;
                    certs.Add(new CertificateOption
                    {
                        Id = WebsiteConfigHelpers.TryGetLong(item, "id", 0),
                        PrimaryDomain = WebsiteConfigHelpers.TryGetString(item, "primaryDomain") ?? "",
                        ExpireDate = WebsiteConfigHelpers.TryGetString(item, "expireDate") ?? "",
                    });
                }
            }
            else if (result == null)
            {
                toast.Show(L10n.T("hostHttpsCertLoadFailed", "Failed to load certificates."));
            }
            RebuildCertItems();
            UpdateCertInfo();
        }

        _ = LoadAsync(firstLoad: true);
        return root;
    }

    /// <summary>读取字符串数组属性；缺属性或非数组返回 null。</summary>
    private static List<string>? ReadStringArray(JsonElement obj, string property)
    {
        if (obj.ValueKind != JsonValueKind.Object ||
            !obj.TryGetProperty(property, out var array) ||
            array.ValueKind != JsonValueKind.Array)
        {
            return null;
        }

        var values = new List<string>();
        foreach (var item in array.EnumerateArray())
        {
            if (item.ValueKind == JsonValueKind.String)
            {
                values.Add(item.GetString() ?? "");
            }
        }
        return values;
    }

    /// <summary>证书下拉项（primaryDomain + expireDate，来自 GetWebsiteCertificatesAsync）。</summary>
    private sealed class CertificateOption
    {
        public long Id { get; init; }
        public string PrimaryDomain { get; init; } = "";
        public string ExpireDate { get; init; } = "";
    }
}
