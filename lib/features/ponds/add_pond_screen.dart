import 'package:flutter/material.dart';
import '../../config/config.dart';
import '../../config/theme.dart';
import '../../l10n/translations.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../widgets/app_banners.dart';

class AddPondScreen extends StatefulWidget {
  final String userId;
  final FirestoreService firestoreService;
  final LanguageNotifier languageNotifier;

  const AddPondScreen({
    super.key,
    required this.userId,
    required this.firestoreService,
    required this.languageNotifier,
  });

  @override
  State<AddPondScreen> createState() => _AddPondScreenState();
}

class _AddPondScreenState extends State<AddPondScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latController =
      TextEditingController(text: AppConfig.defaultLat.toString());
  final TextEditingController _lngController =
      TextEditingController(text: AppConfig.defaultLng.toString());

  String _selectedSpecies = 'Shrimp (Vannamei)';
  bool _isFetchingLocation = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _fetchGPSLocation() async {
    setState(() => _isFetchingLocation = true);
    final loc = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _latController.text = loc.latitude.toStringAsFixed(5);
        _lngController.text = loc.longitude.toStringAsFixed(5);
        _isFetchingLocation = false;
      });
    }
  }

  Future<void> _savePond() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.tryParse(_latController.text) ?? AppConfig.defaultLat;
    final lng = double.tryParse(_lngController.text) ?? AppConfig.defaultLng;

    setState(() => _isSaving = true);
    try {
      await widget.firestoreService.addPond(
        userId: widget.userId,
        name: _nameController.text.trim(),
        species: _selectedSpecies,
        latitude: lat,
        longitude: lng,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save pond: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.languageNotifier.currentLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('addPondTitle', lang)),
        actions: [
          LanguageActionButton(languageNotifier: widget.languageNotifier),
          const SizedBox(width: AppTokens.space8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pond Name Input
                Text(
                  AppStrings.get('pondName', lang),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppTokens.space4),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: AppStrings.get('pondNameHint', lang),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a pond name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTokens.space16),

                // Species Selector
                Text(
                  AppStrings.get('species', lang),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppTokens.space4),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedSpecies,
                  items: [
                    DropdownMenuItem(
                      value: 'Shrimp (Vannamei)',
                      child: Text(AppStrings.get('speciesShrimp', lang)),
                    ),
                    DropdownMenuItem(
                      value: 'Fish',
                      child: Text(AppStrings.get('speciesFish', lang)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSpecies = val);
                  },
                ),
                const SizedBox(height: AppTokens.space16),

                // Location Header & GPS button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.get('location', lang),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Flexible(
                      child: TextButton.icon(
                        onPressed: _isFetchingLocation ? null : _fetchGPSLocation,
                        icon: _isFetchingLocation
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location, size: 16),
                        label: Text(
                          _isFetchingLocation
                              ? AppStrings.get('fetchingLocation', lang)
                              : AppStrings.get('useCurrentLocation', lang),
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.space4),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                        ),
                        validator: (val) {
                          if (val == null || double.tryParse(val) == null) {
                            return 'Valid lat';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppTokens.space12),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                        ),
                        validator: (val) {
                          if (val == null || double.tryParse(val) == null) {
                            return 'Valid lng';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.space32),

                // Primary Save Button
                ElevatedButton(
                  onPressed: _isSaving ? null : _savePond,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTokens.onPrimary,
                          ),
                        )
                      : Text(AppStrings.get('save', lang)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
