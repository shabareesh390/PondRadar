import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/config.dart';
import '../../config/theme.dart';
import '../../l10n/translations.dart';
import '../../models/outbreak_alert.dart';
import '../../models/symptom_report.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_banners.dart';

class OfficerDashboardScreen extends StatefulWidget {
  final AuthService authService;
  final FirestoreService firestoreService;
  final LanguageNotifier languageNotifier;

  const OfficerDashboardScreen({
    super.key,
    required this.authService,
    required this.firestoreService,
    required this.languageNotifier,
  });

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  int _selectedSidebarTab = 0; // 0: Map, 1: Reports, 2: Clusters
  String _timeFilter = '48h';
  String _symptomFilter = 'all';

  OutbreakAlert? _selectedCluster;
  SymptomReport? _selectedReport;
  bool _isLoadingDemo = false;
  GoogleMapController? _mapController;

  static const LatLng _initialMapCenter =
      LatLng(AppConfig.defaultLat, AppConfig.defaultLng);

  Future<void> _loadDemo() async {
    setState(() => _isLoadingDemo = true);
    await widget.firestoreService.loadDemoData(widget.authService.userId);
    if (mounted) {
      setState(() => _isLoadingDemo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loaded 40 simulated coastal Karnataka reports.'),
          backgroundColor: AppTokens.primary,
        ),
      );
    }
  }

  Future<void> _simulateOutbreak() async {
    setState(() => _isLoadingDemo = true);
    // Simulate near Udupi Aquaculture pond
    await widget.firestoreService.simulateOutbreak(
      nearLat: 13.345,
      nearLng: 74.715,
    );
    if (mounted) {
      setState(() => _isLoadingDemo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Outbreak cluster simulated (3 independent reports).'),
          backgroundColor: AppTokens.riskHigh,
        ),
      );
    }
  }

  Future<void> _clearDemo() async {
    setState(() => _isLoadingDemo = true);
    await widget.firestoreService.clearDemoData();
    if (mounted) {
      setState(() {
        _isLoadingDemo = false;
        _selectedCluster = null;
        _selectedReport = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demo data cleared.'),
        ),
      );
    }
  }

  List<SymptomReport> _filterReports(List<SymptomReport> reports) {
    final now = DateTime.now();
    return reports.where((r) {
      // Time filter
      if (_timeFilter == '24h' &&
          r.createdAt.isBefore(now.subtract(const Duration(hours: 24)))) {
        return false;
      }
      if (_timeFilter == '48h' &&
          r.createdAt.isBefore(now.subtract(const Duration(hours: 48)))) {
        return false;
      }
      if (_timeFilter == '7d' &&
          r.createdAt.isBefore(now.subtract(const Duration(days: 7)))) {
        return false;
      }

      // Symptom filter
      if (_symptomFilter != 'all' && !r.symptoms.contains(_symptomFilter)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.languageNotifier.currentLanguage;

    return StreamBuilder<bool>(
      stream: widget.firestoreService.hasSimulatedDataStream(),
      builder: (context, simSnap) {
        final hasSimulated = simSnap.data ?? false;

        return Scaffold(
          body: Column(
            children: [
              if (hasSimulated) SimulatedDataBanner(language: lang),
              Expanded(
                child: StreamBuilder<List<SymptomReport>>(
                  stream: widget.firestoreService.getPrivateReportsStream(),
                  builder: (context, reportSnap) {
                    final allReports = reportSnap.data ?? [];
                    final filteredReports = _filterReports(allReports);

                    return StreamBuilder<List<OutbreakAlert>>(
                      stream: widget.firestoreService.getAlertsStream(),
                      builder: (context, alertSnap) {
                        final alerts = alertSnap.data ?? [];

                        return Row(
                          children: [
                            // 1. Left Sidebar (Fixed 250px)
                            _buildLeftSidebar(context, lang),

                            const VerticalDivider(width: 1),

                            // 2. Main Center Content
                            Expanded(
                              child: Column(
                                children: [
                                  _buildTopFilterBar(lang),
                                  const Divider(height: 1),
                                  Expanded(
                                    child: _buildMainContent(
                                      filteredReports,
                                      alerts,
                                      lang,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 3. Right Detail Panel (if selected)
                            if (_selectedCluster != null ||
                                _selectedReport != null) ...[
                              const VerticalDivider(width: 1),
                              _buildRightDetailPanel(lang),
                            ],
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeftSidebar(BuildContext context, AppLanguage lang) {
    return Container(
      width: 250,
      color: AppTokens.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTokens.space16),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: AppTokens.primary,
                  size: 26,
                ),
                const SizedBox(width: AppTokens.space8),
                Expanded(
                  child: Text(
                    AppStrings.get('officerDashboard', lang),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: Text(AppStrings.get('tabMap', lang)),
            selected: _selectedSidebarTab == 0,
            selectedColor: AppTokens.primary,
            onTap: () => setState(() => _selectedSidebarTab = 0),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: Text(AppStrings.get('tabReports', lang)),
            selected: _selectedSidebarTab == 1,
            selectedColor: AppTokens.primary,
            onTap: () => setState(() => _selectedSidebarTab = 1),
          ),
          ListTile(
            leading: const Icon(Icons.radar_outlined),
            title: Text(AppStrings.get('tabAlerts', lang)),
            selected: _selectedSidebarTab == 2,
            selectedColor: AppTokens.primary,
            onTap: () => setState(() => _selectedSidebarTab = 2),
          ),
          const Spacer(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isLoadingDemo)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTokens.space8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else ...[
                  ElevatedButton(
                    onPressed: _loadDemo,
                    child: Text(AppStrings.get('loadDemoData', lang)),
                  ),
                  const SizedBox(height: AppTokens.space8),
                  OutlinedButton(
                    onPressed: _simulateOutbreak,
                    child: Text(AppStrings.get('simulateOutbreak', lang)),
                  ),
                  const SizedBox(height: AppTokens.space8),
                  TextButton(
                    onPressed: _clearDemo,
                    child: Text(AppStrings.get('clearDemoData', lang)),
                  ),
                ],
                const SizedBox(height: AppTokens.space12),
                OutlinedButton.icon(
                  onPressed: () => widget.authService.switchRole(),
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: Text(AppStrings.get('switchRole', lang)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopFilterBar(AppLanguage lang) {
    return Container(
      color: AppTokens.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space16,
        vertical: AppTokens.space8,
      ),
      child: Row(
        children: [
          const Text(
            'Time:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(width: AppTokens.space8),
          DropdownButton<String>(
            value: _timeFilter,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: '24h', child: Text('Last 24 hours')),
              DropdownMenuItem(value: '48h', child: Text('Last 48 hours')),
              DropdownMenuItem(value: '7d', child: Text('Last 7 days')),
              DropdownMenuItem(value: 'all', child: Text('All time')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _timeFilter = val);
            },
          ),
          const SizedBox(width: AppTokens.space24),
          const Text(
            'Symptom:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(width: AppTokens.space8),
          DropdownButton<String>(
            value: _symptomFilter,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All symptoms')),
              DropdownMenuItem(value: 'white_spots', child: Text('White spots')),
              DropdownMenuItem(value: 'lethargy', child: Text('Lethargy')),
              DropdownMenuItem(
                value: 'surface_gasping',
                child: Text('Surface gasping'),
              ),
              DropdownMenuItem(
                value: 'discoloured_water',
                child: Text('Discoloured water'),
              ),
              DropdownMenuItem(
                value: 'sudden_deaths',
                child: Text('Sudden deaths'),
              ),
              DropdownMenuItem(
                value: 'reduced_feeding',
                child: Text('Reduced feeding'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _symptomFilter = val);
            },
          ),
          const Spacer(),
          LanguageActionButton(languageNotifier: widget.languageNotifier),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    List<SymptomReport> reports,
    List<OutbreakAlert> alerts,
    AppLanguage lang,
  ) {
    if (_selectedSidebarTab == 1) {
      return _buildReportsTable(reports, lang);
    } else if (_selectedSidebarTab == 2) {
      return _buildClustersTable(alerts, lang);
    }
    return _buildMapView(reports, alerts);
  }

  Widget _buildMapView(
    List<SymptomReport> reports,
    List<OutbreakAlert> alerts,
  ) {
    // Generate Google Map markers for reports
    final Set<Marker> markers = {};
    for (final r in reports) {
      markers.add(
        Marker(
          markerId: MarkerId(r.id),
          position: LatLng(r.latitude, r.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          infoWindow: InfoWindow(
            title: 'Report (${r.symptoms.join(', ')})',
            snippet: 'Logged at ${r.createdAt.hour}:${r.createdAt.minute.toString().padLeft(2, '0')}',
          ),
          onTap: () {
            setState(() {
              _selectedReport = r;
              _selectedCluster = null;
            });
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(LatLng(r.latitude, r.longitude)),
            );
          },
        ),
      );
    }

    // Generate cluster circles
    final Set<Circle> circles = {};
    for (final a in alerts) {
      circles.add(
        Circle(
          circleId: CircleId(a.id),
          center: LatLng(a.centerLat, a.centerLng),
          radius: a.radiusKm * 1000, // 3000m
          fillColor: AppTokens.riskHigh.withValues(alpha: 0.15),
          strokeColor: AppTokens.riskHigh,
          strokeWidth: 2,
          consumeTapEvents: true,
          onTap: () {
            setState(() {
              _selectedCluster = a;
              _selectedReport = null;
            });
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(LatLng(a.centerLat, a.centerLng)),
            );
          },
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _initialMapCenter,
            zoom: 10.5,
          ),
          markers: markers,
          circles: circles,
          onMapCreated: (ctrl) => _mapController = ctrl,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
        ),

        // Map Legend (exactly 2 lines as specified in design brief)
        Positioned(
          bottom: AppTokens.space16,
          left: AppTokens.space16,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space12,
              vertical: AppTokens.space8,
            ),
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(AppTokens.controlRadius),
              border: Border.all(color: AppTokens.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: AppTokens.primary),
                    SizedBox(width: 4),
                    Text(
                      'Cyan pin: Farm symptom report',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTokens.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.circle, size: 14, color: AppTokens.riskHigh),
                    SizedBox(width: 4),
                    Text(
                      'Red circle: Confirmed 3 km outbreak cluster',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTokens.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportsTable(List<SymptomReport> reports, AppLanguage lang) {
    if (reports.isEmpty) {
      return const Center(child: Text('No reports matching filters.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space16),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppTokens.border.withValues(alpha: 0.3)),
        columns: const [
          DataColumn(label: Text('Report ID')),
          DataColumn(label: Text('Time')),
          DataColumn(label: Text('Symptoms')),
          DataColumn(label: Text('Exact Coords (Officer)')),
          DataColumn(label: Text('User ID')),
        ],
        rows: reports.map((r) {
          final timeStr =
              '${r.createdAt.day}/${r.createdAt.month} ${r.createdAt.hour}:${r.createdAt.minute.toString().padLeft(2, '0')}';
          return DataRow(
            onSelectChanged: (_) {
              setState(() {
                _selectedReport = r;
                _selectedCluster = null;
              });
            },
            cells: [
              DataCell(Text(r.id.length > 8 ? r.id.substring(0, 8) : r.id)),
              DataCell(Text(timeStr)),
              DataCell(Text(r.symptoms.join(', '))),
              DataCell(Text('${r.latitude.toStringAsFixed(4)}, ${r.longitude.toStringAsFixed(4)}')),
              DataCell(Text(r.userId ?? r.reporterHash)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildClustersTable(List<OutbreakAlert> alerts, AppLanguage lang) {
    if (alerts.isEmpty) {
      return const Center(child: Text('No confirmed clusters.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space16),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppTokens.border.withValues(alpha: 0.3)),
        columns: const [
          DataColumn(label: Text('Cluster ID')),
          DataColumn(label: Text('Center Lat/Lng')),
          DataColumn(label: Text('Farms')),
          DataColumn(label: Text('Reports')),
          DataColumn(label: Text('Symptoms')),
          DataColumn(label: Text('Detected')),
        ],
        rows: alerts.map((a) {
          final timeStr =
              '${a.detectedAt.day}/${a.detectedAt.month} ${a.detectedAt.hour}:${a.detectedAt.minute.toString().padLeft(2, '0')}';
          return DataRow(
            onSelectChanged: (_) {
              setState(() {
                _selectedCluster = a;
                _selectedReport = null;
              });
            },
            cells: [
              DataCell(Text(a.id)),
              DataCell(Text('${a.centerLat.toStringAsFixed(3)}, ${a.centerLng.toStringAsFixed(3)}')),
              DataCell(Text('${a.uniqueReporters}')),
              DataCell(Text('${a.reportCount}')),
              DataCell(Text(a.symptoms.join(', '))),
              DataCell(Text(timeStr)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRightDetailPanel(AppLanguage lang) {
    return Container(
      width: 320,
      color: AppTokens.surface,
      padding: const EdgeInsets.all(AppTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedCluster != null ? 'Cluster Detail' : 'Report Detail',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  setState(() {
                    _selectedCluster = null;
                    _selectedReport = null;
                  });
                },
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: AppTokens.space12),
          if (_selectedCluster != null) ...[
            Text('Cluster ID: ${_selectedCluster!.id}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppTokens.space8),
            Text(
              'Center: ${_selectedCluster!.centerLat}, ${_selectedCluster!.centerLng}',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const SizedBox(height: AppTokens.space8),
            Text('Radius: ${_selectedCluster!.radiusKm} km'),
            const SizedBox(height: AppTokens.space8),
            Text('Independent reporting farms: ${_selectedCluster!.uniqueReporters}'),
            const SizedBox(height: AppTokens.space8),
            Text('Total reports in cluster: ${_selectedCluster!.reportCount}'),
            const SizedBox(height: AppTokens.space12),
            const Text('Symptoms Reported:',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            const SizedBox(height: AppTokens.space4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _selectedCluster!.symptoms.map((s) {
                return Chip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppTokens.background,
                );
              }).toList(),
            ),
          ] else if (_selectedReport != null) ...[
            Text('Report ID: ${_selectedReport!.id}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppTokens.space8),
            Text(
              'Officer View: Exact Coords: ${_selectedReport!.latitude}, ${_selectedReport!.longitude}',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const SizedBox(height: AppTokens.space8),
            Text('Reporter ID: ${_selectedReport!.userId ?? "Anonymous"}'),
            const SizedBox(height: AppTokens.space8),
            Text('Reporter Hash: ${_selectedReport!.reporterHash}'),
            const SizedBox(height: AppTokens.space8),
            Text('Time: ${_selectedReport!.createdAt}'),
            const SizedBox(height: AppTokens.space12),
            const Text('Symptoms:',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            const SizedBox(height: AppTokens.space4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _selectedReport!.symptoms.map((s) {
                return Chip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppTokens.background,
                );
              }).toList(),
            ),
          ],
          const Spacer(),
          DisclaimerText(language: lang),
        ],
      ),
    );
  }
}
