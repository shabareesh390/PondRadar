import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/thresholds.dart';
import '../../l10n/translations.dart';
import '../../models/pond.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_banners.dart';
import '../../widgets/risk_badge.dart';
import 'risk_engine.dart';

class WaterCheckScreen extends StatefulWidget {
  final Pond pond;
  final FirestoreService firestoreService;
  final LanguageNotifier languageNotifier;

  const WaterCheckScreen({
    super.key,
    required this.pond,
    required this.firestoreService,
    required this.languageNotifier,
  });

  @override
  State<WaterCheckScreen> createState() => _WaterCheckScreenState();
}

class _WaterCheckScreenState extends State<WaterCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phController = TextEditingController(text: '8.0');
  final TextEditingController _ammoniaController =
      TextEditingController(text: '0.05');
  final TextEditingController _doController =
      TextEditingController(text: '5.2');
  final TextEditingController _tempController =
      TextEditingController(text: '28.5');

  WaterRiskEvaluation? _currentEvaluation;
  bool _isSaving = false;

  @override
  void dispose() {
    _phController.dispose();
    _ammoniaController.dispose();
    _doController.dispose();
    _tempController.dispose();
    super.dispose();
  }

  Future<void> _evaluate() async {
    if (!_formKey.currentState!.validate()) return;

    final ph = double.parse(_phController.text.trim());
    final ammonia = double.parse(_ammoniaController.text.trim());
    final dOxygen = double.parse(_doController.text.trim());
    final temp = double.parse(_tempController.text.trim());

    final evaluation = RiskEngine.evaluate(
      ph: ph,
      dissolvedOxygen: dOxygen,
      ammonia: ammonia,
      temperature: temp,
    );

    setState(() {
      _currentEvaluation = evaluation;
      _isSaving = true;
    });

    try {
      await widget.firestoreService.updatePondWaterEvaluation(
        pondId: widget.pond.id,
        evaluation: evaluation,
      );
    } catch (e) {
      debugPrint('Save evaluation error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.languageNotifier.currentLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text('${AppStrings.get('waterCheckTitle', lang)} - ${widget.pond.name}'),
        actions: [
          LanguageActionButton(languageNotifier: widget.languageNotifier),
          const SizedBox(width: AppTokens.space8),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Form(
                    key: _formKey,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 500;

                        final phWidget = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.get('phLabel', lang),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: AppTokens.space4),
                            TextFormField(
                              controller: _phController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                hintText: 'e.g. 7.8',
                                suffixText: 'pH',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return AppStrings.get('phValidation', lang);
                                }
                                final num = double.tryParse(val.trim());
                                if (num == null || num < 0 || num > 14) {
                                  return AppStrings.get('phValidation', lang);
                                }
                                return null;
                              },
                            ),
                          ],
                        );

                        final doWidget = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.get('doLabel', lang),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: AppTokens.space4),
                            TextFormField(
                              controller: _doController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                hintText: 'e.g. 5.0',
                                suffixText: 'mg/L',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return AppStrings.get('doValidation', lang);
                                }
                                final num = double.tryParse(val.trim());
                                if (num == null || num < 0) {
                                  return AppStrings.get('doValidation', lang);
                                }
                                return null;
                              },
                            ),
                          ],
                        );

                        final ammoniaWidget = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.get('ammoniaLabel', lang),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: AppTokens.space4),
                            TextFormField(
                              controller: _ammoniaController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                hintText: 'e.g. 0.08',
                                suffixText: 'mg/L',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return AppStrings.get('ammoniaValidation', lang);
                                }
                                final num = double.tryParse(val.trim());
                                if (num == null || num < 0) {
                                  return AppStrings.get('ammoniaValidation', lang);
                                }
                                return null;
                              },
                            ),
                          ],
                        );

                        final tempWidget = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.get('temperatureLabel', lang),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: AppTokens.space4),
                            TextFormField(
                              controller: _tempController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                hintText: 'e.g. 28.5',
                                suffixText: '°C',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return AppStrings.get('temperatureValidation', lang);
                                }
                                final num = double.tryParse(val.trim());
                                if (num == null || num < 0) {
                                  return AppStrings.get('temperatureValidation', lang);
                                }
                                return null;
                              },
                            ),
                          ],
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (isWide) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: phWidget),
                                  const SizedBox(width: AppTokens.space16),
                                  Expanded(child: doWidget),
                                ],
                              ),
                              const SizedBox(height: AppTokens.space16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: ammoniaWidget),
                                  const SizedBox(width: AppTokens.space16),
                                  Expanded(child: tempWidget),
                                ],
                              ),
                            ] else ...[
                              phWidget,
                              const SizedBox(height: AppTokens.space16),
                              doWidget,
                              const SizedBox(height: AppTokens.space16),
                              ammoniaWidget,
                              const SizedBox(height: AppTokens.space16),
                              tempWidget,
                            ],
                            const SizedBox(height: AppTokens.space24),

                            // Evaluate Button
                            ElevatedButton(
                              onPressed: _isSaving ? null : _evaluate,
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTokens.onPrimary,
                                      ),
                                    )
                                  : Text(AppStrings.get('evaluateRisk', lang)),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

              // Risk Assessment Result Card
              if (_currentEvaluation != null) ...[
                const SizedBox(height: AppTokens.space24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppStrings.get('riskAssessment', lang),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const SizedBox(width: AppTokens.space8),
                            RiskBadge(
                              risk: _currentEvaluation!.overallRisk,
                              language: lang,
                              isLarge: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.space16),
                        const Divider(),
                        const SizedBox(height: AppTokens.space12),

                        // Reasons per parameter
                        ..._currentEvaluation!.parameterResults.map((param) {
                          final reason =
                              lang == AppLanguage.kn ? param.reasonKn : param.reasonEn;
                          final paramName =
                              lang == AppLanguage.kn ? param.nameKn : param.nameEn;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTokens.space4,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RiskBadge(risk: param.risk, language: lang),
                                const SizedBox(width: AppTokens.space8),
                                Expanded(
                                  child: Text(
                                    '$paramName (${param.value} ${param.unit}): $reason',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: AppTokens.space12),
                        const Divider(),
                        const SizedBox(height: AppTokens.space12),

                        // Action Note
                        Text(
                          AppStrings.get('actionRequired', lang),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: AppTokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTokens.space4),
                        Text(
                          lang == AppLanguage.kn
                              ? _currentEvaluation!.actionNoteKn
                              : _currentEvaluation!.actionNoteEn,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTokens.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Previous Readings History
              const SizedBox(height: AppTokens.space24),
              Text(
                AppStrings.get('trendHistory', lang),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTokens.space8),
              StreamBuilder<List<WaterRiskEvaluation>>(
                stream: widget.firestoreService.getPondHistoryStream(widget.pond.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(AppTokens.space16),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final history = snapshot.data ?? [];
                  if (history.isEmpty) {
                    return Text(
                      'No prior readings logged for this pond.',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  }

                  return Column(
                    children: history.take(5).map((eval) {
                      final timeStr =
                          '${eval.evaluatedAt.day}/${eval.evaluatedAt.month}/${eval.evaluatedAt.year} ${eval.evaluatedAt.hour}:${eval.evaluatedAt.minute.toString().padLeft(2, '0')}';
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppTokens.space8),
                        child: Padding(
                          padding: const EdgeInsets.all(AppTokens.space12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      timeStr,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: AppTokens.space4),
                                    Text(
                                      eval.parameterResults
                                          .map((p) => '${p.nameEn}: ${p.value}')
                                          .join(' • '),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTokens.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppTokens.space8),
                              RiskBadge(risk: eval.overallRisk, language: lang),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: AppTokens.space24),
              DisclaimerText(language: lang),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
