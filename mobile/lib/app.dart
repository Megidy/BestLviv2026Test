import 'package:flutter/material.dart';

import 'data/app_api_config.dart';
import 'data/app_repository.dart';
import 'data/mock_app_repository.dart';
import 'models.dart';
import 'screens/alerts_screen.dart';
import 'screens/demand_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/settings_screen.dart';
import 'theme.dart';
import 'widgets/common.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LogiSync',
      theme: buildAppTheme(),
      home: const TerminalExperience(),
    );
  }
}

class TerminalExperience extends StatefulWidget {
  const TerminalExperience({super.key});

  @override
  State<TerminalExperience> createState() => _TerminalExperienceState();
}

class _TerminalExperienceState extends State<TerminalExperience> {
  static const AppRepository _repository = MockAppRepository();

  final TextEditingController _operatorController = TextEditingController(
    text: 'J.DOE_WH04',
  );
  final TextEditingController _accessKeyController = TextEditingController(
    text: 'A1B2C3D4',
  );
  final TextEditingController _reasonController = TextEditingController(
    text: 'Reason for demand spike...',
  );

  AppScreen _currentScreen = AppScreen.login;
  UrgencyLevel _selectedUrgency = UrgencyLevel.critical;
  int _requestQuantity = 100;
  int _navIndex = 0;

  late final UserProfile _userProfile = _repository.getCurrentUserProfile();
  late final InventoryOverview _inventoryOverview =
      _repository.getInventoryOverview(_userProfile.locationId);
  late final List<FacilityMapPoint> _mapPoints = _repository.getMapPoints();
  late final List<PredictiveAlert> _predictiveAlerts =
      _repository.getPredictiveAlerts();

  final ResourceRecord _resource = const ResourceRecord(
    name: 'Lithium Cells B-2',
    code: 'RE-RE2911 - Sector 7G',
    manufacturer: 'VoltEdge Industrial',
    location: 'Zone C / Rack 04',
    currentStock: '14 units',
    threshold: '50 units',
    lastSync: '12m ago',
    lastAudited: '24h ago',
    receipt: '25 units',
  );

  final List<QueueItem> _queue = const [
    QueueItem(
      name: 'Hydraulic Fluid X-9',
      code: 'RE-RE-0042 - 42L',
      age: '2m ago',
      status: 'normal',
      accent: AppColors.greenOk,
      icon: Icons.opacity_rounded,
    ),
    QueueItem(
      name: 'Titanium Fasteners',
      code: 'RE-BX-0191 - 125 units',
      age: '45m ago',
      status: 'elevated',
      accent: AppColors.amberWarn,
      icon: Icons.grid_view_rounded,
    ),
    QueueItem(
      name: 'Lithium Cells B-2',
      code: 'RE-RE2911 - 14 units',
      age: '1h ago',
      status: 'elevated',
      accent: AppColors.redAlert,
      icon: Icons.battery_alert_rounded,
    ),
    QueueItem(
      name: 'Coolant Pump M1',
      code: 'RE-RES-0772 - 3 units',
      age: '3h ago',
      status: 'normal',
      accent: AppColors.greenOk,
      icon: Icons.thermostat_rounded,
    ),
    QueueItem(
      name: 'Structural Girders',
      code: 'RE-BX-Y184 - 88 pcs',
      age: '6h ago',
      status: 'normal',
      accent: AppColors.greenOk,
      icon: Icons.construction_rounded,
    ),
  ];

  @override
  void dispose() {
    _operatorController.dispose();
    _accessKeyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _goTo(AppScreen screen) {
    setState(() {
      _currentScreen = screen;
      _navIndex = switch (screen) {
        AppScreen.home => 0,
        AppScreen.alerts => 0,
        AppScreen.inventory => 1,
        AppScreen.detail => 0,
        AppScreen.scanner => 2,
        AppScreen.map => 3,
        AppScreen.settings => 4,
        AppScreen.demand => 0,
        AppScreen.login => 0,
      };
    });
  }

  void _handleNavigation(int index) {
    final screen = switch (index) {
      0 => AppScreen.home,
      1 => AppScreen.inventory,
      2 => AppScreen.scanner,
      3 => AppScreen.map,
      4 => AppScreen.settings,
      _ => AppScreen.home,
    };
    _goTo(screen);
  }

  @override
  Widget build(BuildContext context) {
    return TerminalShell(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey<AppScreen>(_currentScreen),
          child: switch (_currentScreen) {
            AppScreen.login => LoginScreen(
                operatorController: _operatorController,
                accessKeyController: _accessKeyController,
                onInitialize: () => _goTo(AppScreen.home),
              ),
            AppScreen.alerts => AlertsScreen(
                alerts: _predictiveAlerts,
                swaggerJsonUrl: AppApiConfig.swaggerJsonUrl,
                alertsEndpointUrl: AppApiConfig.resolve(
                  AppApiConfig.predictiveAlertsPath,
                ),
                onBack: () => _goTo(AppScreen.home),
              ),
            AppScreen.home => HomeScreen(
                queue: _queue,
                navIndex: _navIndex,
                onQuickScan: () => _goTo(AppScreen.scanner),
                onAlertsTap: () => _goTo(AppScreen.alerts),
                onAccountTap: () => _goTo(AppScreen.settings),
                onQueueTap: () => _goTo(AppScreen.detail),
                onNavigate: _handleNavigation,
              ),
            AppScreen.inventory => InventoryScreen(
                overview: _inventoryOverview,
                swaggerJsonUrl: AppApiConfig.swaggerJsonUrl,
                inventoryEndpointUrl: AppApiConfig.resolve(
                  '${AppApiConfig.inventoryPath}/${_inventoryOverview.locationId}',
                ),
                onBack: () => _goTo(AppScreen.home),
              ),
            AppScreen.detail => DetailScreen(
                resource: _resource,
                onBack: () => _goTo(AppScreen.home),
                onUpdate: () => _goTo(AppScreen.demand),
                onConfirm: () => _goTo(AppScreen.home),
              ),
            AppScreen.demand => DemandScreen(
                resource: _resource,
                urgency: _selectedUrgency,
                requestQuantity: _requestQuantity,
                reasonController: _reasonController,
                onBack: () => _goTo(AppScreen.detail),
                onConfirm: () => _goTo(AppScreen.home),
                onUrgencyChange: (value) {
                  setState(() {
                    _selectedUrgency = value;
                  });
                },
                onAddQuantity: (value) {
                  setState(() {
                    _requestQuantity += value;
                  });
                },
              ),
            AppScreen.scanner => ScannerScreen(
                onClose: () => _goTo(AppScreen.home),
                onManual: () => _goTo(AppScreen.detail),
              ),
            AppScreen.map => MapScreen(
                points: _mapPoints,
                swaggerJsonUrl: AppApiConfig.swaggerJsonUrl,
                mapPointsEndpointUrl: AppApiConfig.resolve(
                  AppApiConfig.mapPointsPath,
                ),
                onBack: () => _goTo(AppScreen.home),
              ),
            AppScreen.settings => SettingsScreen(
                profile: _userProfile,
                swaggerJsonUrl: AppApiConfig.swaggerJsonUrl,
                profileEndpointUrl: AppApiConfig.resolve(
                  AppApiConfig.authMePath,
                ),
                onBack: () => _goTo(AppScreen.home),
                onLogout: () => _goTo(AppScreen.login),
              ),
          },
        ),
      ),
    );
  }
}
