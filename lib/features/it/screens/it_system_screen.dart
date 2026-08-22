import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/it_system_config.dart';
import '../services/it_system_config_service.dart';

class ItSystemScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ItSystemScreen({super.key, this.onBack});

  @override
  State<ItSystemScreen> createState() => _ItSystemScreenState();
}

class _ItSystemScreenState extends State<ItSystemScreen> {
  final ItSystemConfigService _service = ItSystemConfigService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed:
                    widget.onBack ?? () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back,
                        color: AppThemeColors.textPrimary),
                  ),
                  const Icon(Icons.dns_rounded, color: AppThemeColors.textPrimary),
                  const SizedBox(width: 8),
                  const Text(
                    'System Configuration',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<ItSystemConfig>(
                stream: _service.watchConfig(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final config = snapshot.data!;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _ApiSettingsCard(config: config, service: _service),
                      const SizedBox(height: 16),
                      _AqiThresholdCard(
                          thresholds: config.thresholds, service: _service),
                      const SizedBox(height: 16),
                      _NotificationSettingsCard(
                          settings: config.notifications, service: _service),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- shared bits ---

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppThemeStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppThemeColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

InputDecoration _fieldDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppThemeColors.textSecondary),
    filled: true,
    fillColor: const Color(0xFFF1F3F6),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );
}

class _SaveButton extends StatelessWidget {
  final String label;
  final bool isSaving;
  final VoidCallback onPressed;

  const _SaveButton({
    required this.label,
    required this.isSaving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isSaving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppThemeColors.textPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: isSaving
            ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(Icons.save_outlined, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

void _showSaved(BuildContext context, String label) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$label saved!'), backgroundColor: const Color(0xFF10B981)),
  );
}

void _showSaveError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Save failed: $error'), backgroundColor: Colors.red),
  );
}

// --- API Settings ---

class _ApiSettingsCard extends StatefulWidget {
  final ItSystemConfig config;
  final ItSystemConfigService service;

  const _ApiSettingsCard({required this.config, required this.service});

  @override
  State<_ApiSettingsCard> createState() => _ApiSettingsCardState();
}

class _ApiSettingsCardState extends State<_ApiSettingsCard> {
  late final TextEditingController _apiKey =
  TextEditingController(text: widget.config.apiKey);
  late final TextEditingController _endpoint =
  TextEditingController(text: widget.config.apiEndpointUrl);
  late final TextEditingController _timeout =
  TextEditingController(text: '${widget.config.timeoutSeconds}');
  late final TextEditingController _maxRetries =
  TextEditingController(text: '${widget.config.maxRetries}');
  bool _isSaving = false;

  @override
  void dispose() {
    _apiKey.dispose();
    _endpoint.dispose();
    _timeout.dispose();
    _maxRetries.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.service.saveApiSettings(
        apiKey: _apiKey.text.trim(),
        apiEndpointUrl: _endpoint.text.trim(),
        timeoutSeconds: int.tryParse(_timeout.text.trim()) ?? 30,
        maxRetries: int.tryParse(_maxRetries.text.trim()) ?? 3,
      );
      if (mounted) _showSaved(context, 'API settings');
    } catch (e) {
      if (mounted) _showSaveError(context, e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.vpn_key_outlined,
      title: 'API Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('API Key'),
          TextField(controller: _apiKey, decoration: _fieldDecoration()),
          const SizedBox(height: 14),
          const _FieldLabel('API Endpoint URL'),
          TextField(controller: _endpoint, decoration: _fieldDecoration()),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('Timeout (seconds)'),
                    TextField(
                      controller: _timeout,
                      keyboardType: TextInputType.number,
                      decoration: _fieldDecoration(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('Max Retries'),
                    TextField(
                      controller: _maxRetries,
                      keyboardType: TextInputType.number,
                      decoration: _fieldDecoration(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SaveButton(
            label: 'Save API Settings',
            isSaving: _isSaving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

// --- AQI Threshold Settings ---

class _AqiThresholdCard extends StatefulWidget {
  final AqiThresholds thresholds;
  final ItSystemConfigService service;

  const _AqiThresholdCard({required this.thresholds, required this.service});

  @override
  State<_AqiThresholdCard> createState() => _AqiThresholdCardState();
}

class _AqiThresholdCardState extends State<_AqiThresholdCard> {
  late final TextEditingController _good =
  TextEditingController(text: '${widget.thresholds.good}');
  late final TextEditingController _moderate =
  TextEditingController(text: '${widget.thresholds.moderate}');
  late final TextEditingController _sensitive =
  TextEditingController(text: '${widget.thresholds.unhealthyForSensitive}');
  late final TextEditingController _unhealthy =
  TextEditingController(text: '${widget.thresholds.unhealthy}');
  late final TextEditingController _veryUnhealthy =
  TextEditingController(text: '${widget.thresholds.veryUnhealthy}');
  bool _isSaving = false;

  @override
  void dispose() {
    _good.dispose();
    _moderate.dispose();
    _sensitive.dispose();
    _unhealthy.dispose();
    _veryUnhealthy.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.service.saveAqiThresholds(
        AqiThresholds(
          good: int.tryParse(_good.text.trim()) ?? 50,
          moderate: int.tryParse(_moderate.text.trim()) ?? 100,
          unhealthyForSensitive: int.tryParse(_sensitive.text.trim()) ?? 150,
          unhealthy: int.tryParse(_unhealthy.text.trim()) ?? 200,
          veryUnhealthy: int.tryParse(_veryUnhealthy.text.trim()) ?? 300,
        ),
      );
      if (mounted) _showSaved(context, 'AQI thresholds');
    } catch (e) {
      if (mounted) _showSaveError(context, e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _thresholdRow({
    required String label,
    required TextEditingController controller,
    required Color dotColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration(),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.tune_rounded,
      title: 'AQI Threshold Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thresholdRow(
            label: 'Good (0 - ?)',
            controller: _good,
            dotColor: const Color(0xFF22C55E),
          ),
          _thresholdRow(
            label: 'Moderate (${widget.thresholds.good} - ?)',
            controller: _moderate,
            dotColor: const Color(0xFFF59E0B),
          ),
          _thresholdRow(
            label: 'Unhealthy for Sensitive (${widget.thresholds.moderate} - ?)',
            controller: _sensitive,
            dotColor: const Color(0xFFF97316),
          ),
          _thresholdRow(
            label:
            'Unhealthy (${widget.thresholds.unhealthyForSensitive} - ?)',
            controller: _unhealthy,
            dotColor: const Color(0xFFEF4444),
          ),
          _thresholdRow(
            label: 'Very Unhealthy (${widget.thresholds.unhealthy} - ?)',
            controller: _veryUnhealthy,
            dotColor: const Color(0xFF8B5CF6),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F0FE),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 18, color: Color(0xFF2D7EF7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AQI values above ${widget.thresholds.veryUnhealthy} are considered "Hazardous"',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          _SaveButton(
            label: 'Save AQI Thresholds',
            isSaving: _isSaving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

// --- Notification Settings ---

class _NotificationSettingsCard extends StatefulWidget {
  final ItNotificationSettings settings;
  final ItSystemConfigService service;

  const _NotificationSettingsCard({
    required this.settings,
    required this.service,
  });

  @override
  State<_NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState extends State<_NotificationSettingsCard> {
  late bool _push = widget.settings.pushEnabled;
  late bool _email = widget.settings.emailEnabled;
  late bool _sms = widget.settings.smsEnabled;
  late final TextEditingController _frequency =
  TextEditingController(text: '${widget.settings.updateFrequencyMinutes}');
  late final TextEditingController _criticalThreshold = TextEditingController(
      text: '${widget.settings.criticalAlertThreshold}');
  bool _isSaving = false;

  @override
  void dispose() {
    _frequency.dispose();
    _criticalThreshold.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.service.saveNotificationSettings(
        ItNotificationSettings(
          pushEnabled: _push,
          emailEnabled: _email,
          smsEnabled: _sms,
          updateFrequencyMinutes: int.tryParse(_frequency.text.trim()) ?? 15,
          criticalAlertThreshold:
          int.tryParse(_criticalThreshold.text.trim()) ?? 200,
        ),
      );
      if (mounted) _showSaved(context, 'Notification settings');
    } catch (e) {
      if (mounted) _showSaveError(context, e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppThemeColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppThemeColors.textPrimary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE5EAF3),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.notifications_none_rounded,
      title: 'Notification Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _toggleRow(
            title: 'Push Notifications',
            subtitle: 'Send push notifications to mobile devices',
            value: _push,
            onChanged: (v) => setState(() => _push = v),
          ),
          _toggleRow(
            title: 'Email Notifications',
            subtitle: 'Send email alerts to users',
            value: _email,
            onChanged: (v) => setState(() => _email = v),
          ),
          _toggleRow(
            title: 'SMS Notifications',
            subtitle: 'Send SMS alerts for critical events',
            value: _sms,
            onChanged: (v) => setState(() => _sms = v),
          ),
          const Divider(height: 24),
          const _FieldLabel('Update Frequency (minutes)'),
          TextField(
            controller: _frequency,
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration(),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 14),
            child: Text(
              'How often to check for AQI updates',
              style: TextStyle(fontSize: 12, color: AppThemeColors.textSecondary),
            ),
          ),
          const _FieldLabel('Critical Alert Threshold'),
          TextField(
            controller: _criticalThreshold,
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration(),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 16),
            child: Text(
              'AQI level that triggers immediate alerts',
              style: TextStyle(fontSize: 12, color: AppThemeColors.textSecondary),
            ),
          ),
          _SaveButton(
            label: 'Save Notification Settings',
            isSaving: _isSaving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}