import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../l10n/translations.dart';
import '../../models/pond.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_banners.dart';
import '../../widgets/risk_badge.dart';
import '../reports/report_problem_screen.dart';
import '../water_check/water_check_screen.dart';
import 'add_pond_screen.dart';

class FarmerHomeScreen extends StatelessWidget {
  final String userId;
  final List<Pond> ponds;
  final FirestoreService firestoreService;
  final LanguageNotifier languageNotifier;

  const FarmerHomeScreen({
    super.key,
    required this.userId,
    required this.ponds,
    required this.firestoreService,
    required this.languageNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final lang = languageNotifier.currentLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('appName', lang)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: AppStrings.get('addPondTitle', lang),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddPondScreen(
                    userId: userId,
                    firestoreService: firestoreService,
                    languageNotifier: languageNotifier,
                  ),
                ),
              );
            },
          ),
          LanguageActionButton(languageNotifier: languageNotifier),
          const SizedBox(width: AppTokens.space8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Two Big Main Action Buttons
              ElevatedButton.icon(
                onPressed: ponds.isEmpty
                    ? () => _navigateToAddPond(context)
                    : () => _navigateToCheckWater(context, ponds.first),
                icon: const Icon(Icons.water_drop_outlined),
                label: Text(AppStrings.get('checkWater', lang)),
              ),
              const SizedBox(height: AppTokens.space12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReportProblemScreen(
                        userId: userId,
                        ponds: ponds,
                        firestoreService: firestoreService,
                        languageNotifier: languageNotifier,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.warning_amber_outlined),
                label: Text(AppStrings.get('reportProblem', lang)),
              ),
              const SizedBox(height: AppTokens.space24),

              // My Ponds Section
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.get('myPonds', lang),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (ponds.isNotEmpty)
                    TextButton(
                      onPressed: () => _navigateToAddPond(context),
                      child: Text('+ ${AppStrings.get('addPondTitle', lang)}'),
                    ),
                ],
              ),
              const SizedBox(height: AppTokens.space8),

              if (ponds.isEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.space24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.waves_outlined,
                          size: 40,
                          color: AppTokens.textSecondary,
                        ),
                        const SizedBox(height: AppTokens.space12),
                        Text(
                          AppStrings.get('noPonds', lang),
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTokens.space16),
                        OutlinedButton(
                          onPressed: () => _navigateToAddPond(context),
                          child: Text(AppStrings.get('addFirstPond', lang)),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                ...ponds.map((pond) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppTokens.space12),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pond.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: AppTokens.space4),
                                    Text(
                                      pond.species,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppTokens.space8),
                              if (pond.lastRisk != null)
                                RiskBadge(risk: pond.lastRisk!, language: lang)
                              else
                                Text(
                                  'Not tested',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                          if (pond.lastEvaluation != null) ...[
                            const SizedBox(height: AppTokens.space12),
                            const Divider(),
                            const SizedBox(height: AppTokens.space8),
                            Text(
                              lang == AppLanguage.kn
                                  ? pond.lastEvaluation!.actionNoteKn
                                  : pond.lastEvaluation!.actionNoteEn,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: AppTokens.space12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () =>
                                  _navigateToCheckWater(context, pond),
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: Text(AppStrings.get('checkWater', lang)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAddPond(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPondScreen(
          userId: userId,
          firestoreService: firestoreService,
          languageNotifier: languageNotifier,
        ),
      ),
    );
  }

  void _navigateToCheckWater(BuildContext context, Pond pond) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WaterCheckScreen(
          pond: pond,
          firestoreService: firestoreService,
          languageNotifier: languageNotifier,
        ),
      ),
    );
  }
}
