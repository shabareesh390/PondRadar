import 'package:flutter/material.dart';
import '../../config/config.dart';
import '../../config/theme.dart';
import '../../l10n/translations.dart';
import '../../models/pond.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../widgets/app_banners.dart';

class ReportProblemScreen extends StatefulWidget {
  final String userId;
  final List<Pond> ponds;
  final FirestoreService firestoreService;
  final LanguageNotifier languageNotifier;

  const ReportProblemScreen({
    super.key,
    required this.userId,
    required this.ponds,
    required this.firestoreService,
    required this.languageNotifier,
  });

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final Set<String> _selectedSymptoms = {};
  Pond? _selectedPond;
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _symptomDefinitions = [
    {
      'id': 'lethargy',
      'icon': Icons.motion_photos_off_outlined,
      'nameKey': 'symptomLethargy',
    },
    {
      'id': 'surface_gasping',
      'icon': Icons.waves_outlined,
      'nameKey': 'symptomSurfaceGasping',
    },
    {
      'id': 'white_spots',
      'icon': Icons.grain_outlined,
      'nameKey': 'symptomWhiteSpots',
    },
    {
      'id': 'discoloured_water',
      'icon': Icons.water_outlined,
      'nameKey': 'symptomDiscolouredWater',
    },
    {
      'id': 'sudden_deaths',
      'icon': Icons.dangerous_outlined,
      'nameKey': 'symptomSuddenDeaths',
    },
    {
      'id': 'reduced_feeding',
      'icon': Icons.restaurant_outlined,
      'nameKey': 'symptomReducedFeeding',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.ponds.isNotEmpty) {
      _selectedPond = widget.ponds.first;
    }
  }

  void _toggleSymptom(String id) {
    setState(() {
      if (_selectedSymptoms.contains(id)) {
        _selectedSymptoms.remove(id);
      } else {
        _selectedSymptoms.add(id);
      }
    });
  }

  Future<void> _submitReport() async {
    final lang = widget.languageNotifier.currentLanguage;
    if (_selectedSymptoms.isEmpty) {
      setState(() {
        _errorMessage = lang == AppLanguage.kn
            ? 'ಕನಿಷ್ಠ ಒಂದು ರೋಗಲಕ್ಷಣವನ್ನು ಆಯ್ಕೆಮಾಡಿ'
            : 'Please select at least one symptom';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Use selected pond location, or fall back to current device GPS
      double exactLat = AppConfig.defaultLat;
      double exactLng = AppConfig.defaultLng;

      if (_selectedPond != null) {
        exactLat = _selectedPond!.latitude;
        exactLng = _selectedPond!.longitude;
      } else {
        final loc = await LocationService.getCurrentLocation();
        exactLat = loc.latitude;
        exactLng = loc.longitude;
      }

      await widget.firestoreService.submitSymptomReport(
        userId: widget.userId,
        pondId: _selectedPond?.id,
        symptoms: _selectedSymptoms.toList(),
        exactLatitude: exactLat,
        exactLongitude: exactLng,
        isSimulated: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('reportSubmitted', lang)),
            backgroundColor: AppTokens.primary,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to submit report: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.languageNotifier.currentLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('reportTitle', lang)),
        actions: [
          LanguageActionButton(languageNotifier: widget.languageNotifier),
          const SizedBox(width: AppTokens.space8),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.ponds.isNotEmpty) ...[
                    Text(
                      AppStrings.get('pondName', lang),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppTokens.space4),
                    DropdownButtonFormField<Pond>(
                      isExpanded: true,
                      initialValue: _selectedPond,
                      items: widget.ponds.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(p.name),
                        );
                      }).toList(),
                      onChanged: (p) => setState(() => _selectedPond = p),
                    ),
                    const SizedBox(height: AppTokens.space16),
                  ],

                  Text(
                    AppStrings.get('selectSymptoms', lang),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTokens.space12),

                  // Symptom picker grid with responsive columns
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 480;
                      final crossAxisCount = isWide ? 3 : 2;
                      final childAspectRatio = isWide ? 1.45 : 1.22;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: AppTokens.space12,
                          mainAxisSpacing: AppTokens.space12,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: _symptomDefinitions.length,
                        itemBuilder: (context, index) {
                          final item = _symptomDefinitions[index];
                          final id = item['id'] as String;
                          final icon = item['icon'] as IconData;
                          final nameKey = item['nameKey'] as String;
                          final isSelected = _selectedSymptoms.contains(id);

                          return InkWell(
                            onTap: () => _toggleSymptom(id),
                            borderRadius: BorderRadius.circular(AppTokens.cardRadius),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(AppTokens.space12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTokens.primary.withValues(alpha: 0.08)
                                    : AppTokens.surface,
                                borderRadius:
                                    BorderRadius.circular(AppTokens.cardRadius),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTokens.primary
                                      : AppTokens.border,
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  if (isSelected)
                                    const Align(
                                      alignment: Alignment.topRight,
                                      child: Icon(
                                        Icons.check_circle,
                                        color: AppTokens.primary,
                                        size: 18,
                                      ),
                                    ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          icon,
                                          size: 24,
                                          color: isSelected
                                              ? AppTokens.primary
                                              : AppTokens.textSecondary,
                                        ),
                                        const SizedBox(height: AppTokens.space8),
                                        Flexible(
                                          child: Text(
                                            AppStrings.get(nameKey, lang),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: isSelected
                                                  ? AppTokens.primary
                                                  : AppTokens.textPrimary,
                                              height: 1.25,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

              if (_errorMessage != null) ...[
                const SizedBox(height: AppTokens.space12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppTokens.riskHigh,
                    fontSize: 13,
                  ),
                ),
              ],

              const SizedBox(height: AppTokens.space24),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTokens.onPrimary,
                        ),
                      )
                    : Text(AppStrings.get('submitReport', lang)),
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
