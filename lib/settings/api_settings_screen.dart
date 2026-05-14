// Angel One SmartAPI credentials setup screen.
//
// The user enters these once. They are saved to SharedPreferences.
// How to get each value:
//   API Key      → smartapi.angelone.in → My Apps → Create App → API Key
//   Client ID    → Your Angel One trading login ID (e.g. A123456)
//   PIN          → Your 4-digit Angel One trading PIN
//   TOTP Secret  → Angel One app → Profile → Enable TOTP → copy the base32 secret

import 'package:flutter/material.dart';
import 'package:tradexa/data/angel_session.dart';
import 'package:tradexa/data/live_data.dart';
import 'package:tradexa/theme/app_colors.dart';

class ApiSettingsScreen extends StatefulWidget {
  final bool isFirstTime;
  const ApiSettingsScreen({super.key, this.isFirstTime = false});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyCtrl = TextEditingController();
  final _clientIdCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _totpCtrl = TextEditingController();

  bool _saving = false;
  bool _obscurePin = true;
  bool _obscureTotp = true;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final creds = await loadCredentials();
    if (creds != null && mounted) {
      setState(() {
        _apiKeyCtrl.text = creds.apiKey;
        _clientIdCtrl.text = creds.clientId;
        _pinCtrl.text = creds.pin;
        _totpCtrl.text = creds.totpSecret;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final creds = AngelCredentials(
      apiKey: _apiKeyCtrl.text.trim(),
      clientId: _clientIdCtrl.text.trim().toUpperCase(),
      pin: _pinCtrl.text.trim(),
      totpSecret: _totpCtrl.text.trim().toUpperCase().replaceAll(' ', ''),
    );

    await saveCredentials(creds);
    invalidateApiClient(); // Force re-init with new credentials.

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Credentials saved. Live data is now active.'),
        duration: Duration(seconds: 3),
      ),
    );

    if (widget.isFirstTime) {
      Navigator.of(context).pop(true); // Signal that setup is done.
    }
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _clientIdCtrl.dispose();
    _pinCtrl.dispose();
    _totpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        title: const Text(
          'Angel One API Setup',
          style: TextStyle(
            color: AppColors.activeText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoCard(),
              const SizedBox(height: 20),
              _FieldLabel('API Key'),
              _Field(
                controller: _apiKeyCtrl,
                hint: 'Paste from SmartAPI developer console',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _FieldLabel('Client ID'),
              _Field(
                controller: _clientIdCtrl,
                hint: 'e.g. A123456',
                caps: true,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _FieldLabel('Trading PIN'),
              _Field(
                controller: _pinCtrl,
                hint: '4-digit PIN',
                obscure: _obscurePin,
                keyboardType: TextInputType.number,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePin ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.inactiveText,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _FieldLabel('TOTP Secret (base32)'),
              _Field(
                controller: _totpCtrl,
                hint: 'e.g. JBSWY3DPEHPK3PXP',
                obscure: _obscureTotp,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureTotp ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.inactiveText,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureTotp = !_obscureTotp),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              const Text(
                'Find in Angel One app → Profile → Security → TOTP → '
                'Setup → copy the base32 secret (not the QR code).',
                style: TextStyle(
                  color: AppColors.inactiveText,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save & Enable Live Data',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Credentials are stored only on your device.',
                  style:
                      TextStyle(color: AppColors.inactiveText, fontSize: 11.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, size: 16, color: AppColors.primaryBlue),
              SizedBox(width: 6),
              Text(
                'Where to get these values',
                style: TextStyle(
                  color: AppColors.activeText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Bullet('API Key → smartapi.angelone.in → My Apps → Create App'),
          _Bullet('Client ID → your Angel One login ID (e.g. A123456)'),
          _Bullet('PIN → your 4-6 digit Angel One trading PIN'),
          _Bullet('TOTP Secret → Angel One app → Profile → Security → '
              'Enable TOTP → copy base32 key'),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.inactiveText)),
          Expanded(
            child: Text(
              text,
              style:
                  const TextStyle(color: AppColors.inactiveText, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.activeText,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final bool caps;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.caps = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization:
          caps ? TextCapitalization.characters : TextCapitalization.none,
      validator: validator,
      style: const TextStyle(
        color: AppColors.activeText,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.inactiveText, fontSize: 13),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
    );
  }
}
