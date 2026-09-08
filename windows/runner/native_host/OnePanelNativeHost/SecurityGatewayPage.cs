using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace OnePanelNativeHost;

/// <summary>
/// Native Security Gateway page: a compact set that aggregates three
/// security-related views of the active server - the panel SSL info map,
/// the website certificate expiry overview and the OpenResty load status.
/// This is a client enhancement module without a single direct upstream
/// page: the 1Panel web frontend surfaces these facts across the panel
/// settings (SSL info), the website certificate list and the website
/// OpenResty views, and the client joins them into one security overview.
///
/// WRITE BOUNDARY: the Website Certificates card carries two gateway-policy
/// write operations. The header "Upload certificate" button (B21) opens a
/// paste form (certificate, private key, optional description), confirms
/// that the certificate will be imported into the panel and then calls
/// UploadCertificateAsync through the bridge; success silently refreshes
/// the certificates card and failure shows the error toast and keeps the
/// form. Each certificate row additionally carries a "Renew" action that
/// mirrors the upstream website_ssl_page apply/renew entry: a
/// non-destructive confirmation names the primary domain and states that
/// an ACME apply/renewal request will be sent, then ApplyCertificateAsync
/// runs through the bridge; success renders a dismissible "Renewal
/// requested." InfoBar on the certificates card via a silent refresh and
/// failure shows the error toast. The page keeps one older,
/// card-scoped write: the OpenResty "default HTTPS redirect" toggle inside
/// the OpenResty status card shows a confirmation dialog and calls
/// UpdateOpenrestyHttpsAsync ("enable"/"disable"); success silently
/// refreshes the status and failure shows the error toast and rolls the
/// toggle back. The CommandBar itself still carries only Refresh, and
/// gateway policy operations beyond upload and renewal (creating/updating/
/// deleting policies, enforcement toggles, certificate binding) belong to
/// a later batch.
///
/// Data flows through WindowsBridge (Dart business core over the method
/// channel); no direct HTTP from the native layer. The three sources are
/// fetched concurrently because each call crosses the method channel.
///
/// Bridge semantics (per call): null means the bridge itself failed; an
/// empty JSON object means no active server is configured. The page treats
/// the panel SSL map as the primary payload: null fails the page (full
/// error state on initial load, toast on refresh) and an empty map renders
/// the empty state (same rules as DashboardPage). Secondary sources degrade
/// per card instead of failing the whole page: unavailable certificates or
/// status collapse their card, and an OpenResty snapshot is reused for its
/// status map plus its top-level "https" object (the redirect toggle's
/// initial-state probe).
///
/// Certificate rows show the primary domain, the provider as a neutral tag
/// pill and the validity range (startDate to expireDate). The expiry pill
/// turns red when the certificate is expired and orange when it expires
/// within 30 days; when expireDate cannot be parsed as a date the pill
/// stays neutral.
/// </summary>
public sealed class SecurityGatewayPage : ModulePageBase
{
    /// <summary>Certificates at or inside this many days count as expiring soon.</summary>
    private const int ExpiringSoonDays = 30;

    private readonly ErrorToast _errorToast = new();

    /// <summary>Re-entrancy guard shared by loads and refresh.</summary>
    private bool _isBusy;

    /// <summary>
    /// Suppresses the HTTPS redirect switch Toggled handler while the state
    /// is changed programmatically (confirm-cancel revert, failure rollback,
    /// busy debounce).
    /// </summary>
    private bool _suppressHttpsToggleEvents;

    /// <summary>
    /// Pending renewal success notice ("Renewal requested."), set by the
    /// renew flow and rendered once as a dismissible InfoBar on the
    /// certificates card during the next content rebuild.
    /// </summary>
    private string? _renewalNotice;

    /// <summary>Expiry badge states for one website certificate.</summary>
    private enum CertificateExpiryState
    {
        Unknown,
        Valid,
        ExpiringSoon,
        Expired
    }

    public SecurityGatewayPage()
    {
        PageTitle = L10n.T("securityGatewayPageTitle", "Security Gateway");
    }

    protected override async void OnPageShown()
    {
        await LoadSnapshotAsync(showLoadingState: true);
    }

    protected override async void OnRefreshClicked()
    {
        await LoadSnapshotAsync(showLoadingState: true);
    }

    /// <summary>Guarded entry point used by page shown and the refresh action.</summary>
    private async Task LoadSnapshotAsync(bool showLoadingState)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            await LoadSnapshotCoreAsync(showLoadingState);
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Unguarded load body. With <paramref name="showLoadingState"/> the page
    /// swaps to the loading spinner; otherwise the current content stays
    /// visible and failures surface via the error toast.
    /// </summary>
    private async Task LoadSnapshotCoreAsync(bool showLoadingState)
    {
        if (showLoadingState) SetState(PageState.Loading);

        // Fetch all three sources concurrently: each call crosses the method
        // channel into the Dart core, so parallel awaits cut the total wait.
        var panelSslTask = WindowsBridge.GetPanelSslInfoAsync();
        var certificatesTask = WindowsBridge.GetWebsiteCertificatesAsync();
        var openrestyTask = WindowsBridge.GetOpenrestySnapshotAsync();
        await Task.WhenAll(panelSslTask, certificatesTask, openrestyTask);

        var panelSsl = panelSslTask.Result;
        var certificates = ParseCertificates(certificatesTask.Result);
        var openrestySnapshot = openrestyTask.Result ?? default;
        var openrestyStatus = GetMapProperty(openrestySnapshot, "status");
        // The redirect flag lives under the snapshot's top-level "https"
        // object ("https"/"sslRejectHandshake" booleans), not in "status";
        // it only feeds the defensive initial-state probe of the toggle.
        var openrestyHttps = GetMapProperty(openrestySnapshot, "https");

        if (panelSsl == null)
        {
            // Bridge failure: full error state on initial load, toast on
            // refresh. Secondary sources degrade per card (collapsed) and
            // never fail the page on their own.
            if (showLoadingState)
            {
                SetState(PageState.Error);
            }
            else
            {
                _errorToast.Show(L10n.T("hostGatewayRefreshFailed", "Failed to refresh the security gateway snapshot."));
            }
            return;
        }

        // Bridge semantics: an empty panel SSL map means no active server is
        // configured, which maps to the empty state (same as DashboardPage).
        if (!HasAnyProperty(panelSsl.Value))
        {
            SetState(PageState.Empty);
            return;
        }

        BuildContent(panelSsl.Value, certificates, openrestyStatus, openrestyHttps);
        SetState(PageState.Content);
    }

    private void BuildContent(
        JsonElement panelSslMap,
        List<CertificateEntry>? certificates,
        JsonElement openrestyStatusMap,
        JsonElement openrestyHttpsMap)
    {
        // Root layout: CommandBar on top, scrollable content below (relative rows).
        var root = new Grid();
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });

        var commandBar = BuildCommandBar();
        Grid.SetRow(commandBar, 0);
        root.Children.Add(commandBar);

        var scrollViewer = new ScrollViewer
        {
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            Padding = new Thickness(0, 0, 0, 8),
        };
        Grid.SetRow(scrollViewer, 1);

        var content = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Margin = new Thickness(8, 0, 8, 0),
            Spacing = 12,
        };
        content.Children.Add(BuildPanelSslCard(panelSslMap));
        content.Children.Add(BuildCertificatesCard(certificates));
        content.Children.Add(BuildOpenRestyStatusCard(openrestyStatusMap, openrestyHttpsMap));
        scrollViewer.Content = content;
        root.Children.Add(scrollViewer);

        // Failure toast floats above the content, bottom-aligned (kept in the
        // visual tree so Show() actually renders).
        _errorToast.VerticalAlignment = VerticalAlignment.Bottom;
        Grid.SetRow(_errorToast, 1);
        AttachToast(root, _errorToast);

        ModuleContentPresenter.Content = root;
    }

    private CommandBar BuildCommandBar()
    {
        var bar = new CommandBar
        {
            HorizontalAlignment = HorizontalAlignment.Left,
            DefaultLabelPosition = CommandBarDefaultLabelPosition.Right,
            Background = null, // Stay transparent on the LayerFill card surface.
        };

        // The bar carries only Refresh; write actions live inline in their
        // cards: certificate upload in the certificates card header,
        // per-row certificate renewal in the same card and the default
        // HTTPS redirect toggle in the OpenResty card (see class header).
        var refreshButton = new AppBarButton
        {
            Label = L10n.T("commonRefresh", "Refresh"),
            Icon = new FontIcon { Glyph = "\uE72C" },
        };
        refreshButton.Click += (s, e) => _ = LoadSnapshotAsync(showLoadingState: true);
        bar.PrimaryCommands.Add(refreshButton);

        return bar;
    }

    /// <summary>
    /// Panel SSL card: the server-side dynamic key/value map rendered as an
    /// InfoBag-style label/value grid (blank values as "--", booleans as
    /// Yes/No). The whole card collapses when the map is empty.
    /// </summary>
    private FrameworkElement BuildPanelSslCard(JsonElement panelSslMap)
    {
        var card = CreateCard(L10n.T("securityGatewayPanelTlsSection", "Panel SSL"), out var panel);

        if (!HasAnyProperty(panelSslMap))
        {
            card.Visibility = Visibility.Collapsed;
            return card;
        }

        panel.Children.Add(BuildInfoBag(panelSslMap));
        return card;
    }

    /// <summary>
    /// Website certificates card: one row per certificate with the primary
    /// domain as the main text, the provider as a neutral tag pill and the
    /// expiry state as a colored pill. The card header carries the
    /// "Upload certificate" action (paste form like the upstream certificate
    /// upload) and each row carries its own "Renew" action (apply/renewal,
    /// see RenewCertificateAsync). A pending renewal success notice renders
    /// once as a dismissible InfoBar above the list. Unavailable (null)
    /// collapses the card; an empty list keeps the card and shows a "no
    /// certificates" hint so an empty but reachable source stays
    /// distinguishable.
    /// </summary>
    private FrameworkElement BuildCertificatesCard(List<CertificateEntry>? certificates)
    {
        // Header action: opens the paste-form upload dialog. The handler is
        // busy-guarded so a second click during the dialog lifetime is a
        // no-op.
        var uploadButton = new Button
        {
            Padding = new Thickness(10, 4, 10, 4),
            VerticalAlignment = VerticalAlignment.Center,
            Content = new StackPanel
            {
                Orientation = Orientation.Horizontal,
                Spacing = 6,
                Children =
                {
                    new FontIcon { Glyph = "\uE710", FontSize = 14 },
                    new TextBlock
                    {
                        Text = L10n.T("websitesSslUploadAction", "Upload certificate"),
                        FontSize = 12,
                        VerticalAlignment = VerticalAlignment.Center,
                    },
                },
            },
        };
        uploadButton.Click += (s, e) => _ = ShowUploadCertificateDialogAsync();

        var card = CreateCard(L10n.T("securityGatewayWebsiteCertsSection", "Website Certificates"), out var panel, uploadButton);

        // Consume the pending renewal notice exactly once so it cannot leak
        // into an unrelated later rebuild.
        var renewalNotice = _renewalNotice;
        _renewalNotice = null;
        if (renewalNotice != null)
        {
            panel.Children.Add(new InfoBar
            {
                Title = renewalNotice,
                Severity = InfoBarSeverity.Success,
                IsOpen = true,
            });
        }

        if (certificates == null)
        {
            card.Visibility = Visibility.Collapsed;
            return card;
        }

        if (certificates.Count == 0)
        {
            panel.Children.Add(new TextBlock
            {
                Text = L10n.T("websitesSslListEmpty", "No certificates yet."),
                FontSize = 12,
                Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
                TextWrapping = TextWrapping.Wrap,
            });
            return card;
        }

        foreach (var certificate in certificates)
        {
            panel.Children.Add(BuildCertificateRow(certificate));
        }

        return card;
    }

    /// <summary>
    /// OpenResty status card: reuses the OpenResty snapshot bridge and takes
    /// only its status map, rendered as an InfoBag grid like the upstream
    /// website views. Above the read-only counters sits the "default HTTPS
    /// redirect" control row - the page's single write action. The whole
    /// card collapses when the map is empty or the snapshot was unavailable.
    /// </summary>
    private FrameworkElement BuildOpenRestyStatusCard(JsonElement statusMap, JsonElement httpsMap)
    {
        var card = CreateCard(L10n.T("hostGatewayOpenrestyStatus", "OpenResty Status"), out var panel);

        if (!HasAnyProperty(statusMap))
        {
            card.Visibility = Visibility.Collapsed;
            return card;
        }

        // Write action first (upstream website settings place the switch
        // above the raw facts), then the read-only status grid.
        panel.Children.Add(BuildHttpsRedirectRow(statusMap, httpsMap));
        panel.Children.Add(BuildInfoBag(statusMap));
        return card;
    }

    /// <summary>
    /// "Default HTTPS redirect" control row: a header with a caption on the
    /// leading edge and the ToggleSwitch (On=Enable / Off=Disable) trailing.
    /// The initial switch state comes from the defensive probe; when the
    /// state cannot be derived the switch stays Off and an extra
    /// "Current state unknown" caption says so explicitly.
    /// </summary>
    private FrameworkElement BuildHttpsRedirectRow(JsonElement statusMap, JsonElement httpsMap)
    {
        var initialState = ProbeHttpsRedirectState(statusMap, httpsMap);

        var textPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 2 };
        textPanel.Children.Add(new TextBlock
        {
            Text = L10n.T("hostGatewayHttpsRedirectTitle", "Default HTTPS redirect"),
            FontSize = 13,
            FontWeight = Microsoft.UI.Text.FontWeights.Medium,
            TextWrapping = TextWrapping.Wrap,
        });
        textPanel.Children.Add(new TextBlock
        {
            Text = L10n.T("hostGatewayHttpsRedirectDescription", "Redirect HTTP to HTTPS for all websites"),
            FontSize = 12,
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            TextWrapping = TextWrapping.Wrap,
        });
        if (initialState == null)
        {
            textPanel.Children.Add(new TextBlock
            {
                Text = L10n.T("hostGatewayStateUnknown", "Current state unknown"),
                FontSize = 12,
                Foreground = TryGetThemeBrush("TextFillColorTertiaryBrush", Microsoft.UI.Colors.Gray),
                TextWrapping = TextWrapping.Wrap,
            });
        }

        var toggle = new ToggleSwitch
        {
            OnContent = L10n.T("commonEnable", "Enable"),
            OffContent = L10n.T("hostGatewayDisable", "Disable"),
            IsOn = initialState == true,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(12, 0, 0, 0),
        };
        toggle.Toggled += OnHttpsRedirectToggled;

        var row = new Grid { ColumnSpacing = 8 };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        Grid.SetColumn(textPanel, 0);
        Grid.SetColumn(toggle, 1);
        row.Children.Add(textPanel);
        row.Children.Add(toggle);
        return row;
    }

    /// <summary>
    /// Defensively locates the current redirect state. The real snapshot
    /// keeps it under the top-level "https" object ("https": bool,
    /// "sslRejectHandshake": bool) while the "status" map carries only stub
    /// counters - so both are probed: the https object's "https" boolean
    /// first, then a literal "https" boolean on the status map, then any
    /// boolean status key whose name mentions "https". Returns null when
    /// nothing matches (unknown state).
    /// </summary>
    private static bool? ProbeHttpsRedirectState(JsonElement statusMap, JsonElement httpsMap)
    {
        if (httpsMap.ValueKind == JsonValueKind.Object)
        {
            foreach (var property in httpsMap.EnumerateObject())
            {
                if (property.Name.Equals("https", StringComparison.OrdinalIgnoreCase) &&
                    TryGetBool(property.Value, out var value))
                {
                    return value;
                }
            }
        }

        if (statusMap.ValueKind != JsonValueKind.Object) return null;

        // Literal "https" key on the status map (contract evolution safety).
        if (statusMap.TryGetProperty("https", out var direct) &&
            TryGetBool(direct, out var directValue))
        {
            return directValue;
        }

        // Fallback: first boolean key whose name mentions https.
        foreach (var property in statusMap.EnumerateObject())
        {
            if (property.Name.IndexOf("https", StringComparison.OrdinalIgnoreCase) >= 0 &&
                TryGetBool(property.Value, out var value))
            {
                return value;
            }
        }

        return null;
    }

    private static bool TryGetBool(JsonElement element, out bool value)
    {
        if (element.ValueKind == JsonValueKind.True) { value = true; return true; }
        if (element.ValueKind == JsonValueKind.False) { value = false; return true; }
        value = false;
        return false;
    }

    /// <summary>
    /// Toggled handler for the default HTTPS redirect switch: confirm the
    /// action, write through the bridge, then silently refresh the status
    /// on success or show the error toast and roll the switch back on
    /// failure. Cancel and programmatic changes (state suppression and the
    /// busy debounce) never reach the bridge.
    /// </summary>
    private async void OnHttpsRedirectToggled(object? sender, RoutedEventArgs e)
    {
        if (_suppressHttpsToggleEvents) return;
        if (sender is not ToggleSwitch toggle) return;

        // Debounce: the switch is disabled while a write is in flight; any
        // event slipping through during a busy window reverts instead of
        // stacking a second operation.
        if (_isBusy)
        {
            SetToggleSilently(toggle, !toggle.IsOn);
            return;
        }

        var enable = toggle.IsOn;
        var confirmed = await ConfirmDialog.ShowAsync(
            XamlRoot,
            enable
                ? L10n.T("hostGatewayHttpsRedirectEnableTitle", "Enable Default HTTPS Redirect")
                : L10n.T("hostGatewayHttpsRedirectDisableTitle", "Disable Default HTTPS Redirect"),
            enable
                ? L10n.T("hostGatewayHttpsRedirectEnableMessage", "Enable HTTP\u2192HTTPS redirect for all websites?")
                : L10n.T("hostGatewayHttpsRedirectDisableMessage", "Disable HTTP\u2192HTTPS redirect?"),
            enable ? L10n.T("commonEnable", "Enable") : L10n.T("hostGatewayDisable", "Disable"),
            L10n.T("commonCancel", "Cancel"));

        if (!confirmed)
        {
            // User backed out: restore the pre-toggle state.
            SetToggleSilently(toggle, !enable);
            return;
        }

        _isBusy = true;
        toggle.IsEnabled = false;
        bool success;
        try
        {
            success = await WindowsBridge.UpdateOpenrestyHttpsAsync(
                enable ? "enable" : "disable", sslRejectHandshake: null);
            if (!success)
            {
                _errorToast.Show(enable
                    ? L10n.T("hostGatewayHttpsRedirectEnableFailed", "Failed to enable the default HTTPS redirect.")
                    : L10n.T("hostGatewayHttpsRedirectDisableFailed", "Failed to disable the default HTTPS redirect."));
                // Roll the switch back; the content is not rebuilt on failure.
                SetToggleSilently(toggle, !enable);
            }
        }
        finally
        {
            _isBusy = false;
            toggle.IsEnabled = true;
        }

        if (success)
        {
            // Success stays silent: rebuild the snapshot (and this switch
            // with the fresh state) without the loading spinner. The load
            // owns the busy guard, hence the release above.
            await LoadSnapshotAsync(showLoadingState: false);
        }
    }

    /// <summary>Applies a switch state without re-triggering Toggled.</summary>
    private void SetToggleSilently(ToggleSwitch toggle, bool isOn)
    {
        _suppressHttpsToggleEvents = true;
        try
        {
            toggle.IsOn = isOn;
        }
        finally
        {
            _suppressHttpsToggleEvents = false;
        }
    }

    /// <summary>
    /// Upload certificate dialog (paste form, upstream website_ssl_page
    /// paste mode): the PEM certificate and its private key are required
    /// multi-line monospace fields with inline validation, the description
    /// is optional. Because two ContentDialogs cannot stack on one XamlRoot,
    /// a valid form first closes this dialog, an explicit confirmation
    /// states that the certificate will be imported into the panel, and a
    /// declined confirmation or a failed upload reopens the same form with
    /// the pasted content intact. _isBusy is held across the whole dialog
    /// lifetime so the card button cannot open a second dialog and the
    /// refresh stays blocked while the bridge call runs.
    /// </summary>
    private async Task ShowUploadCertificateDialogAsync()
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            var certificateBox = new TextBox
            {
                Header = L10n.T("panelTlsCertificatePemLabel", "Certificate (PEM)"),
                PlaceholderText = L10n.T("hostGatewayCertificatePlaceholder", "Paste the full PEM certificate chain"),
                AcceptsReturn = true,
                Height = 140,
                FontFamily = new FontFamily("Consolas"),
                IsSpellCheckEnabled = false,
                TextWrapping = TextWrapping.NoWrap,
            };
            ScrollViewer.SetVerticalScrollBarVisibility(certificateBox, ScrollBarVisibility.Auto);

            var privateKeyBox = new TextBox
            {
                Header = L10n.T("panelTlsPrivateKeyPemLabel", "Private key (PEM)"),
                PlaceholderText = L10n.T("hostGatewayPrivateKeyPlaceholder", "Paste the matching PEM private key"),
                AcceptsReturn = true,
                Height = 120,
                FontFamily = new FontFamily("Consolas"),
                IsSpellCheckEnabled = false,
                TextWrapping = TextWrapping.NoWrap,
            };
            ScrollViewer.SetVerticalScrollBarVisibility(privateKeyBox, ScrollBarVisibility.Auto);

            var descriptionBox = new TextBox
            {
                Header = L10n.T("hostGatewayDescriptionOptional", "Description (optional)"),
                PlaceholderText = L10n.T("hostGatewayDescriptionPlaceholder", "e.g. *.example.com issued 2026-09"),
            };

            var errorText = new TextBlock
            {
                FontSize = 12,
                TextWrapping = TextWrapping.Wrap,
                Foreground = TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.Red),
                Visibility = Visibility.Collapsed,
            };

            // Any edit clears the pending inline validation error.
            certificateBox.TextChanged += (s, e) => SetFormError(errorText, null);
            privateKeyBox.TextChanged += (s, e) => SetFormError(errorText, null);
            descriptionBox.TextChanged += (s, e) => SetFormError(errorText, null);

            var form = new StackPanel { Orientation = Orientation.Vertical, Spacing = 12 };
            form.Children.Add(certificateBox);
            form.Children.Add(privateKeyBox);
            form.Children.Add(descriptionBox);
            form.Children.Add(errorText);

            var dialog = new ContentDialog
            {
                Title = L10n.T("sslSettingsUpload", "Upload Certificate"),
                Content = form,
                PrimaryButtonText = L10n.T("commonUpload", "Upload"),
                CloseButtonText = L10n.T("commonCancel", "Cancel"),
                DefaultButton = ContentDialogButton.Primary,
                XamlRoot = XamlRoot,
            };

            bool confirmPending = false;

            dialog.Closing += (s, args) =>
            {
                // Programmatic close on the way to the confirmation passes
                // through.
                if (confirmPending) return;
                if (args.Result != ContentDialogResult.Primary) return;

                // Inline validation: on invalid input cancel the close so
                // the dialog stays open and the error shows next to the
                // fields.
                if (string.IsNullOrWhiteSpace(certificateBox.Text))
                {
                    args.Cancel = true;
                    SetFormError(errorText, L10n.T("hostGatewayCertificateRequired", "Certificate is required."));
                    return;
                }
                if (string.IsNullOrWhiteSpace(privateKeyBox.Text))
                {
                    args.Cancel = true;
                    SetFormError(errorText, L10n.T("panelTlsValidationPrivateKeyRequired", "Private key is required."));
                    return;
                }

                // Close first so the confirmation dialog can open on top
                // (two ContentDialogs cannot stack on one XamlRoot).
                args.Cancel = true;
                confirmPending = true;
                dialog.Hide();
            };

            while (true)
            {
                confirmPending = false;
                await dialog.ShowAsync();
                if (!confirmPending) return; // Closed via Cancel.

                var confirmed = await ConfirmDialog.ShowAsync(
                    XamlRoot,
                    L10n.T("sslSettingsUpload", "Upload Certificate"),
                    L10n.T("hostGatewayUploadConfirmMessage", "The certificate will be imported into the panel and becomes available to websites. Continue?"),
                    L10n.T("commonUpload", "Upload"),
                    L10n.T("commonCancel", "Cancel"));
                if (!confirmed) continue; // Back to the form, content kept.

                // Paste semantics per the bridge contract: certificate and
                // private key are required (validated above); a blank
                // description is sent as null.
                var success = await WindowsBridge.UploadCertificateAsync(
                    certificateBox.Text.Trim(),
                    privateKeyBox.Text.Trim(),
                    string.IsNullOrWhiteSpace(descriptionBox.Text) ? null : descriptionBox.Text.Trim());

                if (success)
                {
                    // Release the dialog-lifetime guard so the guarded
                    // silent refresh below can actually run.
                    _isBusy = false;
                    await LoadSnapshotAsync(showLoadingState: false);
                    return;
                }

                _errorToast.Show(L10n.T("hostGatewayUploadFailed", "Failed to upload the certificate."));
                SetFormError(errorText, L10n.T("hostGatewayUploadFormError", "Upload failed. The form reopens with your content; try again."));
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>Shows or hides the inline form validation error.</summary>
    private static void SetFormError(TextBlock target, string? message)
    {
        if (string.IsNullOrEmpty(message))
        {
            target.Text = string.Empty;
            target.Visibility = Visibility.Collapsed;
        }
        else
        {
            target.Text = message;
            target.Visibility = Visibility.Visible;
        }
    }

    /// <summary>
    /// Renew flow for one certificate row (upstream website_ssl_page apply
    /// entry): a non-destructive confirmation names the primary domain and
    /// states that an ACME apply/renewal request will be sent, then the
    /// bridge triggers the async apply task. Success renders the
    /// "Renewal requested." InfoBar on the certificates card through a
    /// silent snapshot refresh; failure shows the error toast and keeps the
    /// list as-is. The shared _isBusy guard makes clicks during an in-flight
    /// write or dialog a no-op.
    /// </summary>
    private async Task RenewCertificateAsync(CertificateEntry certificate)
    {
        if (_isBusy) return;

        // ParseCertificates falls back to -1 when the bridge entry has no
        // usable id; such a row cannot be renewed.
        if (certificate.Id < 0)
        {
            _errorToast.Show(L10n.T("hostGatewayRenewNoId", "This certificate has no id and cannot be renewed."));
            return;
        }

        var domain = string.IsNullOrWhiteSpace(certificate.PrimaryDomain)
            ? "--"
            : certificate.PrimaryDomain.Trim();
        var confirmed = await ConfirmDialog.ShowAsync(
            XamlRoot,
            L10n.T("websitesSslAccountsRenewAction", "Renew Certificate"),
            $"An ACME apply/renewal request will be sent for \"{domain}\". Continue?",
            L10n.T("hostGatewayRenew", "Renew"),
            L10n.T("commonCancel", "Cancel"));
        if (!confirmed) return;

        _isBusy = true;
        bool success;
        try
        {
            success = await WindowsBridge.ApplyCertificateAsync(certificate.Id);
        }
        finally
        {
            // Release before the refresh: the guarded load owns the busy
            // guard from here on.
            _isBusy = false;
        }

        if (success)
        {
            // The notice is rendered once by the next silent rebuild of the
            // certificates card (see BuildCertificatesCard).
            _renewalNotice = L10n.T("hostGatewayRenewalRequested", "Renewal requested.");
            await LoadSnapshotAsync(showLoadingState: false);
        }
        else
        {
            _errorToast.Show($"Failed to request the renewal of \"{domain}\".");
        }
    }

    /// <summary>
    /// One certificate row: relative columns only - the domain stretches in
    /// a Star column, the provider and expiry pills sit in Auto columns at
    /// the trailing edge, the "Renew" action sits in the last Auto column
    /// (the row's apply/renewal write, see RenewCertificateAsync) and the
    /// validity range spans the full width below.
    /// </summary>
    private FrameworkElement BuildCertificateRow(CertificateEntry certificate)
    {
        var (expiryState, daysLeft) = EvaluateExpiry(certificate.ExpireDate);

        var row = new Grid { ColumnSpacing = 8, RowSpacing = 2, Margin = new Thickness(0, 0, 0, 6) };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        row.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        row.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

        var domainBlock = new TextBlock
        {
            Text = string.IsNullOrWhiteSpace(certificate.PrimaryDomain)
                ? "--"
                : certificate.PrimaryDomain.Trim(),
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            TextTrimming = TextTrimming.CharacterEllipsis,
            VerticalAlignment = VerticalAlignment.Center,
        };
        Grid.SetRow(domainBlock, 0);
        Grid.SetColumn(domainBlock, 0);
        row.Children.Add(domainBlock);

        if (!string.IsNullOrWhiteSpace(certificate.Provider))
        {
            var providerPill = CreatePill(
                certificate.Provider.Trim(),
                TryGetThemeBrush("SystemFillColorNeutralBrush", Microsoft.UI.Colors.Gray));
            Grid.SetRow(providerPill, 0);
            Grid.SetColumn(providerPill, 1);
            row.Children.Add(providerPill);
        }

        var expiryPill = CreatePill(
            FormatExpiryLabel(expiryState, daysLeft),
            GetExpiryBrush(expiryState));
        Grid.SetRow(expiryPill, 0);
        Grid.SetColumn(expiryPill, 2);
        row.Children.Add(expiryPill);

        // Row write action: compact icon-only button (sync glyph) with a
        // tooltip, matching the card's small-font row density. The handler
        // is busy-guarded so clicks during an in-flight write are no-ops.
        var renewButton = new Button
        {
            Padding = new Thickness(8, 2, 8, 2),
            VerticalAlignment = VerticalAlignment.Center,
            Content = new FontIcon { Glyph = "\uE895", FontSize = 14 },
        };
        ToolTipService.SetToolTip(renewButton, L10n.T("hostGatewayRenew", "Renew"));
        renewButton.Click += (s, e) => _ = RenewCertificateAsync(certificate);
        Grid.SetRow(renewButton, 0);
        Grid.SetColumn(renewButton, 3);
        row.Children.Add(renewButton);

        var validityBlock = new TextBlock
        {
            Text = FormatValidityRange(certificate.StartDate, certificate.ExpireDate),
            FontSize = 12,
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            TextTrimming = TextTrimming.CharacterEllipsis,
        };
        Grid.SetRow(validityBlock, 1);
        Grid.SetColumn(validityBlock, 0);
        Grid.SetColumnSpan(validityBlock, 4);
        row.Children.Add(validityBlock);

        return row;
    }

    /// <summary>
    /// Classifies the certificate expiry: expired turns the badge red,
    /// within the expiring-soon window turns it orange, everything else
    /// (including an unparsable date) stays neutral.
    /// </summary>
    private static (CertificateExpiryState State, int DaysLeft) EvaluateExpiry(string expireDate)
    {
        if (TryParseDate(expireDate, out var expiry))
        {
            // Day-granularity comparison so a certificate expiring today is
            // "expiring soon", not "expired".
            var daysLeft = (int)Math.Floor((expiry.Date - DateTime.Now.Date).TotalDays);
            if (daysLeft < 0)
            {
                return (CertificateExpiryState.Expired, daysLeft);
            }
            if (daysLeft <= ExpiringSoonDays)
            {
                return (CertificateExpiryState.ExpiringSoon, daysLeft);
            }
            return (CertificateExpiryState.Valid, daysLeft);
        }

        return (CertificateExpiryState.Unknown, 0);
    }

    /// <summary>
    /// Date parsing for bridge-provided timestamps: invariant culture first
    /// (covers ISO 8601 and "yyyy-MM-dd HH:mm:ss"), current culture as the
    /// fallback. Any failure keeps the badge neutral.
    /// </summary>
    private static bool TryParseDate(string? text, out DateTime value)
    {
        value = default;
        if (string.IsNullOrWhiteSpace(text)) return false;

        return DateTime.TryParse(
                   text.Trim(),
                   CultureInfo.InvariantCulture,
                   DateTimeStyles.AllowWhiteSpaces | DateTimeStyles.AssumeLocal,
                   out value)
               || DateTime.TryParse(text.Trim(), out value);
    }

    private static Brush GetExpiryBrush(CertificateExpiryState state)
    {
        return state switch
        {
            CertificateExpiryState.Expired
                => TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.IndianRed),
            CertificateExpiryState.ExpiringSoon
                => TryGetThemeBrush("SystemFillColorCautionBrush", Microsoft.UI.Colors.DarkOrange),
            _ => TryGetThemeBrush("SystemFillColorNeutralBrush", Microsoft.UI.Colors.Gray),
        };
    }

    private static string FormatExpiryLabel(CertificateExpiryState state, int daysLeft)
    {
        return state switch
        {
            CertificateExpiryState.Expired => L10n.T("websitesSslHealthExpired", "Expired"),
            CertificateExpiryState.ExpiringSoon
                => daysLeft == 0 ? L10n.T("hostGatewayExpiresToday", "Expires today") : $"Expires in {daysLeft}d",
            CertificateExpiryState.Valid => L10n.T("hostGatewayValid", "Valid"),
            _ => L10n.T("websitesSslHealthUnknown", "Unknown"),
        };
    }

    /// <summary>Validity line "startDate → expireDate"; blanks render "--".</summary>
    private static string FormatValidityRange(string startDate, string expireDate)
    {
        var start = string.IsNullOrWhiteSpace(startDate) ? "--" : startDate.Trim();
        var expire = string.IsNullOrWhiteSpace(expireDate) ? "--" : expireDate.Trim();
        return $"{start} \u2192 {expire}";
    }

    /// <summary>
    /// Colored tag pill with a translucent tint of the accent so it stays
    /// readable over Mica/LayerFill in both themes.
    /// </summary>
    private static FrameworkElement CreatePill(string text, Brush accent)
    {
        var accentColor = GetBrushColor(accent, Microsoft.UI.Colors.Gray);

        return new Border
        {
            CornerRadius = new CornerRadius(10),
            Padding = new Thickness(10, 3, 10, 3),
            VerticalAlignment = VerticalAlignment.Center,
            Background = new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(26, accentColor.R, accentColor.G, accentColor.B)),
            Child = new TextBlock
            {
                Text = text,
                FontSize = 12,
                Foreground = accent,
                VerticalAlignment = VerticalAlignment.Center,
            },
        };
    }

    /// <summary>
    /// Card shell shared by all cards: rounded border with a faint translucent
    /// tint of the theme card stroke plus a semi-bold title line. An optional
    /// trailing header action (the certificates card's upload button) is
    /// aligned opposite the title. The caller fills <paramref name="panel"/>
    /// with the card body.
    /// </summary>
    private static FrameworkElement CreateCard(
        string title, out StackPanel panel, FrameworkElement? headerAction = null)
    {
        var card = new Border
        {
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(16, 12, 16, 12),
            BorderBrush = TryGetThemeBrush("CardStrokeColorDefaultBrush", Microsoft.UI.Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = CreateSubtleFill(),
        };

        panel = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 10,
        };

        var titleBlock = new TextBlock
        {
            Text = title,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            VerticalAlignment = VerticalAlignment.Center,
        };

        if (headerAction != null)
        {
            var header = new Grid { ColumnSpacing = 8 };
            header.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            Grid.SetColumn(titleBlock, 0);
            Grid.SetColumn(headerAction, 1);
            header.Children.Add(titleBlock);
            header.Children.Add(headerAction);
            panel.Children.Add(header);
        }
        else
        {
            panel.Children.Add(titleBlock);
        }

        card.Child = panel;
        return card;
    }

    /// <summary>
    /// InfoBag grid over a dynamic map: two label+value pairs per row with
    /// relative columns only. Blank values render "--", booleans render as
    /// Yes/No.
    /// </summary>
    private static Grid BuildInfoBag(JsonElement map)
    {
        var bag = new Grid();
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(24) });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        var entries = new List<KeyValuePair<string, string>>();
        foreach (var property in EnumerateMapProperties(map))
        {
            entries.Add(new KeyValuePair<string, string>(property.Name, FormatScalar(property.Value)));
        }

        for (int i = 0; i < entries.Count; i += 2)
        {
            var rowIndex = bag.RowDefinitions.Count;
            bag.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            AddInfoPair(bag, rowIndex, 0, entries[i].Key, entries[i].Value);
            if (i + 1 < entries.Count)
            {
                AddInfoPair(bag, rowIndex, 1, entries[i + 1].Key, entries[i + 1].Value);
            }
        }

        return bag;
    }

    /// <summary>
    /// Places one label+value pair into the InfoBag grid.
    /// <paramref name="pairIndex"/> 0 uses columns 0/1, 1 uses columns 3/4.
    /// Blank values render "--".
    /// </summary>
    private static void AddInfoPair(Grid bag, int row, int pairIndex, string label, string value)
    {
        var labelColumn = pairIndex == 0 ? 0 : 3;
        var valueColumn = pairIndex == 0 ? 1 : 4;

        var labelBlock = new TextBlock
        {
            Text = label,
            FontSize = 12,
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            VerticalAlignment = VerticalAlignment.Top,
            Margin = new Thickness(0, 0, 12, 0),
        };
        Grid.SetRow(labelBlock, row);
        Grid.SetColumn(labelBlock, labelColumn);
        bag.Children.Add(labelBlock);

        var valueBlock = new TextBlock
        {
            Text = string.IsNullOrWhiteSpace(value) ? "--" : value,
            FontSize = 13,
            TextWrapping = TextWrapping.Wrap,
            TextTrimming = TextTrimming.CharacterEllipsis,
            VerticalAlignment = VerticalAlignment.Top,
            Margin = new Thickness(0, 0, 0, 8),
        };
        Grid.SetRow(valueBlock, row);
        Grid.SetColumn(valueBlock, valueColumn);
        bag.Children.Add(valueBlock);
    }

    /// <summary>
    /// Parses the website certificate array from the bridge. Returns null
    /// when the source is unavailable (not an array) so the card collapses;
    /// an empty array yields an empty list so the card can show its
    /// "no certificates" hint. Non-object entries are skipped.
    /// </summary>
    private static List<CertificateEntry>? ParseCertificates(JsonElement? element)
    {
        if (element == null || element.Value.ValueKind != JsonValueKind.Array)
        {
            return null;
        }

        var certificates = new List<CertificateEntry>();
        foreach (var item in element.Value.EnumerateArray())
        {
            if (item.ValueKind != JsonValueKind.Object) continue;

            certificates.Add(new CertificateEntry
            {
                Id = TryGetLong(item, "id"),
                PrimaryDomain = TryGetString(item, "primaryDomain") ?? "",
                Provider = TryGetString(item, "provider") ?? "",
                StartDate = TryGetString(item, "startDate") ?? "",
                ExpireDate = TryGetString(item, "expireDate") ?? "",
            });
        }

        return certificates;
    }

    /// <summary>
    /// Translucent card fill derived from the theme card stroke (~4% alpha)
    /// so cards read over Mica/LayerFill in both light and dark themes
    /// without an opaque background.
    /// </summary>
    private static Brush CreateSubtleFill()
    {
        var stroke = TryGetThemeBrush("CardStrokeColorDefaultBrush", Microsoft.UI.Colors.Gray);
        var color = GetBrushColor(stroke, Microsoft.UI.Colors.Gray);
        return new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(10, color.R, color.G, color.B));
    }

    /// <summary>Scalar rendering for dynamic map values: strings pass through
    /// ("--" when blank), numbers use their raw text, booleans render as
    /// Yes/No, and nested arrays/objects fall back to their raw JSON text.</summary>
    private static string FormatScalar(JsonElement value)
    {
        switch (value.ValueKind)
        {
            case JsonValueKind.String:
                var text = value.GetString();
                return string.IsNullOrWhiteSpace(text) ? "--" : text.Trim();
            case JsonValueKind.Number:
                return value.GetRawText();
            case JsonValueKind.True:
                return L10n.T("commonYes", "Yes");
            case JsonValueKind.False:
                return L10n.T("commonNo", "No");
            case JsonValueKind.Array:
            case JsonValueKind.Object:
                return value.GetRawText();
            default:
                return "--";
        }
    }

    /// <summary>Returns the named object property, or a default (Undefined)
    /// element when absent or malformed. Callers guard on HasAnyProperty /
    /// EnumerateMapProperties, so an Undefined element simply collapses the
    /// card instead of being dereferenced.</summary>
    private static JsonElement GetMapProperty(JsonElement root, string property)
    {
        if (root.ValueKind == JsonValueKind.Object &&
            root.TryGetProperty(property, out var value) &&
            value.ValueKind == JsonValueKind.Object)
        {
            return value;
        }
        return default;
    }

    /// <summary>Enumerates the map as dynamic key/value pairs; safe on non-objects.</summary>
    private static IEnumerable<JsonProperty> EnumerateMapProperties(JsonElement map)
    {
        if (map.ValueKind != JsonValueKind.Object) yield break;

        using var enumerator = map.EnumerateObject();
        while (enumerator.MoveNext())
        {
            yield return enumerator.Current;
        }
    }

    private static bool HasAnyProperty(JsonElement json)
    {
        if (json.ValueKind != JsonValueKind.Object) return false;

        using var enumerator = json.EnumerateObject();
        return enumerator.MoveNext();
    }

    private static string? TryGetString(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.String)
        {
            return prop.GetString();
        }
        return null;
    }

    private static long TryGetLong(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.Number &&
            prop.TryGetInt64(out var value))
        {
            return value;
        }
        return -1;
    }

    private static Brush TryGetThemeBrush(string key, Color fallback)
    {
        if (Application.Current.Resources.TryGetValue(key, out var value) && value is Brush brush)
        {
            return brush;
        }
        return new SolidColorBrush(fallback);
    }

    private static Color GetBrushColor(Brush brush, Color fallback)
        => brush is SolidColorBrush solid ? solid.Color : fallback;
}

/// <summary>Immutable view over one website certificate from the bridge.</summary>
internal sealed class CertificateEntry
{
    public long Id { get; set; } = -1;
    public string PrimaryDomain { get; set; } = "";
    public string Provider { get; set; } = "";
    public string StartDate { get; set; } = "";
    public string ExpireDate { get; set; } = "";
}
