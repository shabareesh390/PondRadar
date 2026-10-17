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
import '../../widgets/map_availability.dart';

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return StreamBuilder<bool>(
          stream: widget.firestoreService.hasSimulatedDataStream(),
          builder: (context, simSnap) {
            final hasSimulated = simSnap.data ?? false;

            return StreamBuilder<List<SymptomReport>>(
              stream: widget.firestoreService.getPrivateReportsStream(),
              builder: (context, reportSnap) {
                final allReports = reportSnap.data ?? [];
                final filteredReports = _filterReports(allReports);

                return StreamBuilder<List<OutbreakAlert>>(
                  stream: widget.firestoreService.getAlertsStream(),
                  builder: (context, alertSnap) {
                    final alerts = alertSnap.data ?? [];

                    if (isMobile) {
                      return Scaffold(
                        appBar: AppBar(
                          title: Text(AppStrings.get('officerDashboard', lang)),
                          actions: [
                            LanguageActionButton(
                              languageNotifier: widget.languageNotifier,
                            ),
                            const SizedBox(width: AppTokens.space8),
                          ],
                        ),
                        drawer: Drawer(
                          child: _buildLeftSidebar(context, lang, isDrawer: true),
                        ),
                        body: Column(
                          children: [
                            if (hasSimulated) SimulatedDataBanner(language: lang),
                            _buildTopFilterBar(lang, isMobile: true),
                            const Divider(height: 1),
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: _buildMainContent(
                                      filteredReports,
                                      alerts,
                                      lang,
                                    ),
                                  ),
                                  if (_selectedCluster != null ||
                                      _selectedReport != null)
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Material(
                                        elevation: 8,
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(AppTokens.cardRadius),
                                        ),
                                        child: Container(
                                          constraints: BoxConstraints(
                                            maxHeight: constraints.maxHeight * 0.45,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTokens.surface,
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(AppTokens.cardRadius),
                                            ),
                                            border: Border.all(color: AppTokens.border),
                                          ),
                                          child: _buildRightDetailPanel(
                                            lang,
                                            isMobile: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        bottomNavigationBar: NavigationBar(
                          selectedIndex: _selectedSidebarTab,
                          onDestinationSelected: (idx) =>
                              setState(() => _selectedSidebarTab = idx),
                          destinations: [
                            NavigationDestination(
                              icon: const Icon(Icons.map_outlined),
                              selectedIcon: const Icon(Icons.map),
                              label: AppStrings.get('tabMap', lang),
                            ),
                            NavigationDestination(
                              icon: const Icon(Icons.table_chart_outlined),
                              selectedIcon: const Icon(Icons.table_chart),
                              label: AppStrings.get('tabReports', lang),
                            ),
                            NavigationDestination(
                              icon: const Icon(Icons.radar_outlined),
                              selectedIcon: const Icon(Icons.radar),
                              label: AppStrings.get('tabAlerts', lang),
                            ),
                          ],
                        ),
                      );
                    }

                    // Desktop / Wide Screen Layout (width >= 800)
                    return Scaffold(
                      body: Column(
                        children: [
                          if (hasSimulated) SimulatedDataBanner(language: lang),
                          Expanded(
                            child: Row(
                              children: [
                                // 1. Left Sidebar (Fixed 250px)
                                _buildLeftSidebar(context, lang, isDrawer: false),

                                const VerticalDivider(width: 1),

                                // 2. Main Center Content (Takes 100% of remaining width)
                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildTopFilterBar(lang, isMobile: false),
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
                                  _buildRightDetailPanel(lang, isMobile: false),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLeftSidebar(BuildContext context, AppLanguage lang, {bool isDrawer = false}) {
    return Material(
      color: AppTokens.surface,
      child: SizedBox(
        width: isDrawer ? null : 250,
        child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
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
                            if (isDrawer)
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.of(context).pop(),
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
                        onTap: () {
                          setState(() => _selectedSidebarTab = 0);
                          if (isDrawer) Navigator.of(context).pop();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.table_chart_outlined),
                        title: Text(AppStrings.get('tabReports', lang)),
                        selected: _selectedSidebarTab == 1,
                        selectedColor: AppTokens.primary,
                        onTap: () {
                          setState(() => _selectedSidebarTab = 1);
                          if (isDrawer) Navigator.of(context).pop();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.radar_outlined),
                        title: Text(AppStrings.get('tabAlerts', lang)),
                        selected: _selectedSidebarTab == 2,
                        selectedColor: AppTokens.primary,
                        onTap: () {
                          setState(() => _selectedSidebarTab = 2);
                          if (isDrawer) Navigator.of(context).pop();
                        },
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
                                onPressed: () {
                                  _loadDemo();
                                  if (isDrawer) Navigator.of(context).pop();
                                },
                                child: Text(AppStrings.get('loadDemoData', lang)),
                              ),
                              const SizedBox(height: AppTokens.space8),
                              OutlinedButton(
                                onPressed: () {
                                  _simulateOutbreak();
                                  if (isDrawer) Navigator.of(context).pop();
                                },
                                child: Text(AppStrings.get('simulateOutbreak', lang)),
                              ),
                              const SizedBox(height: AppTokens.space8),
                              TextButton(
                                onPressed: () {
                                  _clearDemo();
                                  if (isDrawer) Navigator.of(context).pop();
                                },
                                child: Text(AppStrings.get('clearDemoData', lang)),
                              ),
                            ],
                            const SizedBox(height: AppTokens.space12),
                            OutlinedButton.icon(
                              onPressed: () {
                                if (isDrawer) Navigator.of(context).pop();
                                widget.authService.switchRole();
                              },
                              icon: const Icon(Icons.swap_horiz, size: 16),
                              label: Text(AppStrings.get('switchRole', lang)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
    );
  }

  Widget _buildTopFilterBar(AppLanguage lang, {bool isMobile = false}) {
    return Material(
      color: AppTokens.surface,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space16,
          vertical: AppTokens.space8,
        ),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text(
                      'Time:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: AppTokens.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppTokens.space8),
                    DropdownButton<String>(
                      value: _timeFilter,
                      isDense: true,
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
                    const SizedBox(width: AppTokens.space16),
                    const Text(
                      'Symptom:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: AppTokens.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppTokens.space8),
                    DropdownButton<String>(
                      value: _symptomFilter,
                      isDense: true,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All symptoms')),
                        DropdownMenuItem(value: 'white_spots', child: Text('White spots')),
                        DropdownMenuItem(value: 'lethargy', child: Text('Lethargy')),
                        DropdownMenuItem(value: 'surface_gasping', child: Text('Surface gasping')),
                        DropdownMenuItem(value: 'discoloured_water', child: Text('Discoloured water')),
                        DropdownMenuItem(value: 'sudden_deaths', child: Text('Sudden deaths')),
                        DropdownMenuItem(value: 'reduced_feeding', child: Text('Reduced feeding')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _symptomFilter = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (!isMobile) ...[
              const SizedBox(width: AppTokens.space16),
              LanguageActionButton(languageNotifier: widget.languageNotifier),
            ],
          ],
        ),
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

    if (!isGoogleMapsAvailable()) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.map_outlined,
                size: 56,
                color: AppTokens.textSecondary,
              ),
              const SizedBox(height: AppTokens.space16),
              Text(
                'Map View (Google Maps API key not loaded)',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.space8),
              const Text(
                'To display Google Maps in the web dashboard, provide an API key in web/env.js or URL query (?maps_key=KEY).',
                style: TextStyle(fontSize: 13, color: AppTokens.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.space20),
              Wrap(
                spacing: AppTokens.space12,
                runSpacing: AppTokens.space8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _selectedSidebarTab = 1),
                    icon: const Icon(Icons.table_chart_outlined, size: 18),
                    label: Text('View Reports (${reports.length})'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _selectedSidebarTab = 2),
                    icon: const Icon(Icons.radar_outlined, size: 18),
                    label: Text('View Clusters (${alerts.length})'),
                  ),
                ],
              ),
            ],
          ),
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

        // Map Legend (top right so it does not overlap bottom sheets)
        Positioned(
          top: AppTokens.space12,
          right: AppTokens.space12,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space12,
              vertical: AppTokens.space8,
            ),
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(AppTokens.controlRadius),
              border: Border.all(color: AppTokens.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 14, color: AppTokens.primary),
                    SizedBox(width: 4),
                    Text(
                      'Cyan: Farm report',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTokens.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 14, color: AppTokens.riskHigh),
                    SizedBox(width: 4),
                    Text(
                      'Red: Outbreak cluster (3 km)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTokens.textPrimary,
                        fontWeight: FontWeight.w500,
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
      ),
    );
  }

  Widget _buildClustersTable(List<OutbreakAlert> alerts, AppLanguage lang) {
    if (alerts.isEmpty) {
      return const Center(child: Text('No confirmed clusters.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
      ),
    );
  }

  Widget _buildRightDetailPanel(AppLanguage lang, {bool isMobile = false}) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: isMobile
                  ? 0
                  : (constraints.maxHeight - (AppTokens.space16 * 2)).clamp(0.0, double.infinity),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: AppTokens.space8),
                  if (_selectedCluster != null) ...[
                    Text('Cluster ID: ${_selectedCluster!.id}',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: AppTokens.space4),
                    Text(
                      'Center: ${_selectedCluster!.centerLat.toStringAsFixed(4)}, ${_selectedCluster!.centerLng.toStringAsFixed(4)}',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    const SizedBox(height: AppTokens.space4),
                    Text('Radius: ${_selectedCluster!.radiusKm} km | Farms: ${_selectedCluster!.uniqueReporters} | Reports: ${_selectedCluster!.reportCount}'),
                    const SizedBox(height: AppTokens.space8),
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
                    const SizedBox(height: AppTokens.space4),
                    Text(
                      'Officer View: Exact Coords: ${_selectedReport!.latitude.toStringAsFixed(4)}, ${_selectedReport!.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    const SizedBox(height: AppTokens.space4),
                    Text('Reporter: ${_selectedReport!.userId ?? _selectedReport!.reporterHash}'),
                    const SizedBox(height: AppTokens.space4),
                    Text('Time: ${_selectedReport!.createdAt.day}/${_selectedReport!.createdAt.month} ${_selectedReport!.createdAt.hour}:${_selectedReport!.createdAt.minute.toString().padLeft(2, '0')}'),
                    const SizedBox(height: AppTokens.space8),
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
                  if (!isMobile) ...[
                    const Spacer(),
                    const SizedBox(height: AppTokens.space16),
                    DisclaimerText(language: lang),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );

    if (isMobile) {
      return Material(
        color: AppTokens.surface,
        child: content,
      );
    }

    return Material(
      color: AppTokens.surface,
      child: SizedBox(
        width: 320,
        child: content,
      ),
    );
  }
}
