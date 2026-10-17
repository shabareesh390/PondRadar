import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../l10n/translations.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_banners.dart';

class RolePickerScreen extends StatefulWidget {
  final AuthService authService;
  final LanguageNotifier languageNotifier;

  const RolePickerScreen({
    super.key,
    required this.authService,
    required this.languageNotifier,
  });

  @override
  State<RolePickerScreen> createState() => _RolePickerScreenState();
}

class _RolePickerScreenState extends State<RolePickerScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _showPinInput = false;
  String? _pinError;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _onOfficerSelected() {
    setState(() {
      _showPinInput = true;
      _pinError = null;
    });
  }

  Future<void> _submitPin() async {
    final pin = _pinController.text;
    final success = await widget.authService.verifyAndSelectOfficerRole(pin);
    if (!success) {
      if (mounted) {
        setState(() {
          _pinError = AppStrings.get(
            'invalidPin',
            widget.languageNotifier.currentLanguage,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.languageNotifier.currentLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('appName', lang)),
        actions: [
          LanguageActionButton(languageNotifier: widget.languageNotifier),
          const SizedBox(width: AppTokens.space8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTokens.space16),
              Text(
                AppStrings.get('selectRole', lang),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTokens.space24),

              // Farmer Card
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTokens.cardRadius),
                  onTap: () => widget.authService.selectFarmerRole(),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.space16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.water_drop_outlined,
                          size: 32,
                          color: AppTokens.primary,
                        ),
                        const SizedBox(width: AppTokens.space16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.get('farmerRole', lang),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppTokens.space4),
                              Text(
                                AppStrings.get('farmerDesc', lang),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppTokens.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space12),

              // Officer Card
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTokens.cardRadius),
                  onTap: _onOfficerSelected,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.space16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 32,
                          color: AppTokens.primary,
                        ),
                        const SizedBox(width: AppTokens.space16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.get('officerRole', lang),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppTokens.space4),
                              Text(
                                AppStrings.get('officerDesc', lang),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppTokens.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_showPinInput) ...[
                const SizedBox(height: AppTokens.space24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppStrings.get('enterPin', lang),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTokens.space12),
                        TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'PIN',
                            errorText: _pinError,
                          ),
                        ),
                        const SizedBox(height: AppTokens.space16),
                        ElevatedButton(
                          onPressed: _submitPin,
                          child: Text(AppStrings.get('submitPin', lang)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const Spacer(),
              DisclaimerText(language: lang),
            ],
          ),
        ),
      ),
    );
  }
}
