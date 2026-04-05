import 'package:flutter/material.dart';

import 'data/api_exception.dart';
import 'data/app_repository.dart';
import 'data/remote_app_repository.dart';
import 'models.dart';
import 'presentation/queue_factory.dart';
import 'presentation/resource_record_factory.dart';
import 'screens/alerts_screen.dart';
import 'screens/delivery_request_detail_screen.dart';
import 'screens/delivery_requests_screen.dart';
import 'screens/demand_screen.dart';
import 'screens/demand_readings_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'screens/rebalancing_proposal_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stock_nearest_screen.dart';
import 'theme.dart';
import 'widgets/common.dart';
import 'widgets/shell_status_view.dart';

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
  static const int _minRequestQuantity = 1;
  static const int _maxRequestQuantity = 1000000;

  final AppRepository _repository = RemoteAppRepository();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _arriveTillController = TextEditingController();
  final TextEditingController _demandPointIdController = TextEditingController();
  final TextEditingController _demandResourceIdController = TextEditingController();
  final TextEditingController _demandQuantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _demandRecordedAtController =
      TextEditingController();
  final TextEditingController _proposalIdController = TextEditingController();
  final TextEditingController _nearestResourceIdController =
      TextEditingController();
  final TextEditingController _nearestPointIdController =
      TextEditingController();
  final TextEditingController _nearestQuantityController =
      TextEditingController();

  AppScreen _currentScreen = AppScreen.login;
  UrgencyLevel _selectedUrgency = UrgencyLevel.critical;
  int _requestQuantity = 100;
  int _navIndex = 0;
  AppScreen _detailBackScreen = AppScreen.home;

  bool _isRestoringSession = true;
  bool _isAuthenticating = false;
  bool _isRefreshingData = false;
  bool _isSubmittingRequest = false;
  bool _isRunningAlertAction = false;
  bool _isDemandBusy = false;
  bool _isProposalBusy = false;
  bool _isNearestBusy = false;
  bool _isLoadingRequests = false;
  bool _isMutatingRequest = false;
  String? _authError;
  String? _dataError;
  String? _requestError;
  String? _demandError;
  String? _proposalError;
  String? _proposalStatusMessage;
  String? _nearestError;
  String? _deliveryError;

  UserProfile? _userProfile;
  InventoryOverview? _inventoryOverview;
  List<FacilityMapPoint> _mapPoints = const [];
  List<PredictiveAlert> _predictiveAlerts = const [];
  List<DeliveryRequestSummary> _deliveryRequests = const [];
  List<AllocationRecord> _allocations = const [];
  int _deliveryRequestsTotal = 0;
  int _allocationsTotal = 0;
  String? _requestsStatusFilter;
  String? _allocationsStatusFilter;
  int _requestsPage = 1;
  int _allocationsPage = 1;
  final int _requestsPageSize = 20;
  final int _allocationsPageSize = 20;
  DeliveryRequestDetail? _selectedRequestDetail;
  List<DemandReadingRecord> _demandReadings = const [];
  int _demandReadingsTotal = 0;
  RebalancingProposalDetail? _selectedProposal;
  List<NearestStockResult> _nearestStockResults = const [];
  List<QueueItem> _queue = const [];
  ResourceRecord? _resource;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _arriveTillController.dispose();
    _demandPointIdController.dispose();
    _demandResourceIdController.dispose();
    _demandQuantityController.dispose();
    _demandRecordedAtController.dispose();
    _proposalIdController.dispose();
    _nearestResourceIdController.dispose();
    _nearestPointIdController.dispose();
    _nearestQuantityController.dispose();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    try {
      final profile = await _repository.tryRestoreSession();
      if (!mounted) {
        return;
      }

      if (profile == null) {
        setState(() {
          _isRestoringSession = false;
          _currentScreen = AppScreen.login;
        });
        return;
      }

      await _loadCoreData(profile, forceHome: true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isRestoringSession = false;
        _authError = 'Session restore failed. Sign in again.';
        _currentScreen = AppScreen.login;
      });
    }
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _authError = 'Enter both username and password.';
      });
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _authError = null;
    });

    try {
      final profile = await _repository.login(
        username: username,
        password: password,
      );
      if (!mounted) {
        return;
      }

      await _loadCoreData(profile, forceHome: true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isAuthenticating = false;
        _authError = error.toString();
      });
    }
  }

  Future<void> _loadCoreData(
    UserProfile profile, {
    required bool forceHome,
  }) async {
    if (profile.role == UserRole.admin) {
      await _repository.logout();
      if (!mounted) {
        return;
      }

      setState(() {
        _isRestoringSession = false;
        _isAuthenticating = false;
        _isRefreshingData = false;
        _authError = 'Admin account is web-only. Use worker or dispatcher credentials in mobile app.';
        _currentScreen = AppScreen.login;
        _navIndex = 0;
        _userProfile = null;
      });
      return;
    }

    setState(() {
      _isRestoringSession = false;
      _isAuthenticating = false;
      _isRefreshingData = true;
      _isRunningAlertAction = false;
      _dataError = null;
      _requestError = null;
      _userProfile = profile;
    });

    try {
      final results = await Future.wait<dynamic>([
        _repository.getInventoryOverview(profile.locationId),
        _repository.getMapPoints(),
        _repository.getPredictiveAlerts(),
      ]);

      final inventoryOverview = results[0] as InventoryOverview;
      final mapPoints = List<FacilityMapPoint>.from(
        results[1] as List<FacilityMapPoint>,
      );
      final predictiveAlerts = List<PredictiveAlert>.from(
        results[2] as List<PredictiveAlert>,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _inventoryOverview = inventoryOverview;
        _mapPoints = mapPoints;
        _predictiveAlerts = predictiveAlerts;
        _queue = buildQueueFromInventory(
          inventoryOverview: inventoryOverview,
          predictiveAlerts: predictiveAlerts,
        );
        _resource = _buildResourceRecord(inventoryOverview);
        if (_demandPointIdController.text.trim().isEmpty) {
          _demandPointIdController.text = _userProfile!.locationId.toString();
        }
        if (_demandResourceIdController.text.trim().isEmpty &&
            inventoryOverview.items.isNotEmpty) {
          _demandResourceIdController.text =
              inventoryOverview.items.first.resourceId.toString();
        }
        if (_nearestResourceIdController.text.trim().isEmpty &&
            inventoryOverview.items.isNotEmpty) {
          _nearestResourceIdController.text =
              inventoryOverview.items.first.resourceId.toString();
        }
        if (_nearestPointIdController.text.trim().isEmpty) {
          _nearestPointIdController.text = _userProfile!.locationId.toString();
        }
        _isRefreshingData = false;
        if (forceHome || _currentScreen == AppScreen.login) {
          _currentScreen = AppScreen.home;
          _navIndex = 0;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isRefreshingData = false;
        _dataError = error.toString();
        if (forceHome || _currentScreen == AppScreen.login) {
          _currentScreen = AppScreen.home;
          _navIndex = 0;
        }
      });
    }
  }

  Future<void> _refreshCoreData() async {
    final profile = _userProfile;
    if (profile == null || _isRefreshingData) {
      return;
    }

    await _loadCoreData(profile, forceHome: false);
  }

  void _openQueueItem(QueueItem item) {
    final inventoryOverview = _inventoryOverview;
    if (inventoryOverview == null) {
      _goTo(AppScreen.detail);
      return;
    }

    InventoryItem? selectedItem;
    for (final candidate in inventoryOverview.items) {
      if (candidate.resourceName == item.name) {
        selectedItem = candidate;
        break;
      }
    }

    final matchedItem = selectedItem;
    setState(() {
      if (matchedItem != null) {
        _resource = buildResourceRecordFromItem(
          item: matchedItem,
          lastUpdatedLabel: item.age,
        );
      }
      _detailBackScreen = AppScreen.home;
    });

    _goTo(AppScreen.detail);
  }

  void _openInventoryItem(InventoryItem item) {
    setState(() {
      _resource = buildResourceRecordFromItem(
        item: item,
        lastUpdatedLabel: 'Live sync',
      );
      _detailBackScreen = AppScreen.inventory;
    });

    _goTo(AppScreen.detail);
  }

  void _handleScannerDetected(String rawValue) {
    final inventoryOverview = _inventoryOverview;
    if (inventoryOverview == null || inventoryOverview.items.isEmpty) {
      return;
    }

    final normalizedRaw = rawValue.trim();
    if (normalizedRaw.isEmpty) {
      return;
    }

    final scannedResourceId = _extractScannedResourceId(normalizedRaw);

    InventoryItem? matchedById;
    if (scannedResourceId != null) {
      for (final item in inventoryOverview.items) {
        if (item.resourceId == scannedResourceId || item.id == scannedResourceId) {
          matchedById = item;
          break;
        }
      }
    }

    InventoryItem? matchedItem = matchedById;
    if (matchedItem == null) {
      final loweredRaw = normalizedRaw.toLowerCase();
      for (final item in inventoryOverview.items) {
        final loweredName = item.resourceName.toLowerCase();
        if (loweredName.contains(loweredRaw) || loweredRaw.contains(loweredName)) {
          matchedItem = item;
          break;
        }
      }
    }

    if (matchedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'QR scanned, but no matching resource was found: $normalizedRaw',
          ),
        ),
      );
      return;
    }

    final selectedItem = matchedItem;
    setState(() {
      _resource = buildResourceRecordFromItem(
        item: selectedItem,
        lastUpdatedLabel: 'Scanned just now',
      );
      _detailBackScreen = AppScreen.scanner;
    });

    _goTo(AppScreen.detail);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Scanned resource #${selectedItem.resourceId}: ${selectedItem.resourceName}',
        ),
      ),
    );
  }

  int? _extractScannedResourceId(String rawValue) {
    final direct = int.tryParse(rawValue);
    if (direct != null && direct > 0) {
      return direct;
    }

    final taggedIdMatch = RegExp(
      r'(?:resource[_\s-]?id|resourceid|item[_\s-]?id|id)\D{0,5}(\d{1,9})',
      caseSensitive: false,
    ).firstMatch(rawValue);
    if (taggedIdMatch != null) {
      final parsed = int.tryParse(taggedIdMatch.group(1) ?? '');
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }

    final firstNumberMatch = RegExp(r'\b(\d{1,9})\b').firstMatch(rawValue);
    if (firstNumberMatch != null) {
      final parsed = int.tryParse(firstNumberMatch.group(1) ?? '');
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }

    return null;
  }

  Future<void> _handleLogout() async {
    await _repository.logout();
    if (!mounted) {
      return;
    }

    setState(() {
      _resetToLoggedOutState();
    });
  }

  void _resetToLoggedOutState() {
    _currentScreen = AppScreen.login;
    _navIndex = 0;
    _detailBackScreen = AppScreen.home;
    _isRestoringSession = false;
    _isAuthenticating = false;
    _isRefreshingData = false;
    _isSubmittingRequest = false;
    _isRunningAlertAction = false;
    _isDemandBusy = false;
    _isProposalBusy = false;
    _isNearestBusy = false;
    _isLoadingRequests = false;
    _isMutatingRequest = false;
    _authError = null;
    _dataError = null;
    _requestError = null;
    _demandError = null;
    _proposalError = null;
    _proposalStatusMessage = null;
    _nearestError = null;
    _deliveryError = null;
    _userProfile = null;
    _inventoryOverview = null;
    _mapPoints = const [];
    _predictiveAlerts = const [];
    _deliveryRequests = const [];
    _allocations = const [];
    _deliveryRequestsTotal = 0;
    _allocationsTotal = 0;
    _requestsStatusFilter = null;
    _allocationsStatusFilter = null;
    _requestsPage = 1;
    _allocationsPage = 1;
    _selectedRequestDetail = null;
    _demandReadings = const [];
    _demandReadingsTotal = 0;
    _selectedProposal = null;
    _nearestStockResults = const [];
    _queue = const [];
    _resource = null;

    _passwordController.clear();
    _arriveTillController.clear();
    _demandPointIdController.clear();
    _demandResourceIdController.clear();
    _demandQuantityController.text = '1';
    _demandRecordedAtController.clear();
    _proposalIdController.clear();
    _nearestResourceIdController.clear();
    _nearestPointIdController.clear();
    _nearestQuantityController.clear();
  }

  Future<void> _dismissAlert(PredictiveAlert alert) async {
    setState(() {
      _isRunningAlertAction = true;
    });

    try {
      await _repository.dismissPredictiveAlert(alert.id);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alert #${alert.id} dismissed.')),
      );
      await _refreshCoreData();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isRunningAlertAction = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _submitDeliveryRequest() async {
    final profile = _userProfile;
    final resource = _resource;
    if (profile == null || resource == null) {
      return;
    }
    if (profile.role != UserRole.worker &&
        profile.role != UserRole.dispatcher) {
      setState(() {
        _requestError =
            'Delivery request creation is available only for worker and dispatcher accounts.';
      });
      return;
    }

    DateTime? arriveTill;
    final arriveTillText = _arriveTillController.text.trim();
    if (arriveTillText.isNotEmpty) {
      arriveTill = DateTime.tryParse(arriveTillText);
      if (arriveTill == null) {
        setState(() {
          _requestError =
              'Use ISO date format for arrive by, for example 2026-04-05T18:00:00.';
        });
        return;
      }
    }

    if (_selectedUrgency == UrgencyLevel.urgent && arriveTill == null) {
      setState(() {
        _requestError = 'Urgent requests require an arrive-by time.';
      });
      return;
    }

    if (_requestQuantity < _minRequestQuantity ||
        _requestQuantity > _maxRequestQuantity) {
      setState(() {
        _requestError =
            'Request amount must be between $_minRequestQuantity and $_maxRequestQuantity.';
      });
      return;
    }

    setState(() {
      _isSubmittingRequest = true;
      _requestError = null;
    });

    try {
      await _repository.createDeliveryRequest(
        destinationId: profile.locationId,
        resourceId: resource.resourceId,
        quantity: _requestQuantity,
        urgency: _selectedUrgency,
        arriveTill: arriveTill,
      );

      if (!mounted) {
        return;
      }

      _arriveTillController.clear();

      setState(() {
        _isSubmittingRequest = false;
        _currentScreen = AppScreen.home;
        _navIndex = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery request created successfully.'),
        ),
      );

      await _refreshCoreData();
    } catch (error) {
      if (!mounted) {
        return;
      }

      final readableError = _presentApiError(
        error,
        forbiddenMessage:
            'Delivery request creation is available only for worker and dispatcher accounts.',
      );
      setState(() {
        _isSubmittingRequest = false;
        _requestError = readableError;
      });
    }
  }

  Future<void> _openDemandReadings() async {
    _goTo(AppScreen.demandReadings);
    await _loadDemandReadings();
  }

  Future<void> _loadDemandReadings() async {
    final pointId = int.tryParse(_demandPointIdController.text.trim());
    if (pointId == null || pointId <= 0) {
      setState(() {
        _demandError = 'Enter a valid Point ID to load demand history.';
      });
      return;
    }

    setState(() {
      _isDemandBusy = true;
      _demandError = null;
    });

    try {
      final feed = await _repository.getDemandReadings(
        pointId: pointId,
        page: 1,
        pageSize: 30,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _demandReadings = feed.readings;
        _demandReadingsTotal = feed.total;
        _isDemandBusy = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDemandBusy = false;
        _demandError = error.toString();
      });
    }
  }

  Future<void> _submitDemandReading() async {
    final pointId = int.tryParse(_demandPointIdController.text.trim());
    final resourceId = int.tryParse(_demandResourceIdController.text.trim());
    final quantity = num.tryParse(_demandQuantityController.text.trim());
    DateTime? recordedAt;
    final recordedAtText = _demandRecordedAtController.text.trim();

    if (pointId == null || pointId <= 0) {
      setState(() {
        _demandError = 'Point ID is required.';
      });
      return;
    }
    if (resourceId == null || resourceId <= 0) {
      setState(() {
        _demandError = 'Resource ID is required.';
      });
      return;
    }
    if (quantity == null || quantity <= 0) {
      setState(() {
        _demandError = 'Quantity must be greater than zero.';
      });
      return;
    }

    if (recordedAtText.isNotEmpty) {
      recordedAt = DateTime.tryParse(recordedAtText);
      if (recordedAt == null) {
        setState(() {
          _demandError = 'Use ISO format for recorded_at, for example 2026-04-05T12:00:00.';
        });
        return;
      }
    }

    setState(() {
      _isDemandBusy = true;
      _demandError = null;
    });

    try {
      await _repository.recordDemandReading(
        pointId: pointId,
        resourceId: resourceId,
        quantity: quantity,
        source: DemandReadingSource.manual,
        recordedAt: recordedAt,
      );
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demand reading submitted.')),
      );
      await _loadDemandReadings();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDemandBusy = false;
        _demandError = error.toString();
      });
    }
  }

  void _openRebalancingProposals() {
    if (!_canUseRebalancing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Rebalancing proposals are available only for dispatcher accounts.',
          ),
        ),
      );
      return;
    }

    _goTo(AppScreen.rebalancingProposals);
  }

  Future<void> _openProposalFromAlert(PredictiveAlert alert) async {
    if (!_canUseRebalancing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Proposal review is available only for dispatcher accounts.',
          ),
        ),
      );
      return;
    }

    final proposalId = alert.proposalId;
    if (proposalId == null || proposalId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No proposal is linked to this alert.')),
      );
      return;
    }

    _proposalIdController.text = proposalId.toString();
    _goTo(AppScreen.rebalancingProposals);
    await _loadRebalancingProposal();
  }

  void _openStockNearest() {
    _goTo(AppScreen.stockNearest);
  }

  Future<void> _lookupNearestStock() async {
    final resourceId = int.tryParse(_nearestResourceIdController.text.trim());
    final pointId = int.tryParse(_nearestPointIdController.text.trim());
    final quantityText = _nearestQuantityController.text.trim();
    final quantity = quantityText.isEmpty ? null : num.tryParse(quantityText);

    if (resourceId == null || resourceId <= 0) {
      setState(() {
        _nearestError = 'Resource ID must be a positive integer.';
      });
      return;
    }

    if (pointId == null || pointId <= 0) {
      setState(() {
        _nearestError = 'Destination Point ID must be a positive integer.';
      });
      return;
    }

    if (quantityText.isNotEmpty && (quantity == null || quantity <= 0)) {
      setState(() {
        _nearestError = 'Required quantity must be a positive number.';
      });
      return;
    }

    setState(() {
      _isNearestBusy = true;
      _nearestError = null;
    });

    try {
      final results = await _repository.getNearestStock(
        resourceId: resourceId,
        pointId: pointId,
        quantity: quantity,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _nearestStockResults = results;
        _isNearestBusy = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isNearestBusy = false;
        _nearestError = error.toString();
      });
    }
  }

  Future<void> _loadRebalancingProposal() async {
    if (!_canUseRebalancing) {
      setState(() {
        _proposalError =
            'Rebalancing proposals are available only for dispatcher accounts.';
        _proposalStatusMessage = null;
      });
      return;
    }

    final proposalId = int.tryParse(_proposalIdController.text.trim());
    if (proposalId == null || proposalId <= 0) {
      setState(() {
        _proposalError = 'Enter a valid Proposal ID.';
        _proposalStatusMessage = null;
      });
      return;
    }

    setState(() {
      _isProposalBusy = true;
      _proposalError = null;
      _proposalStatusMessage = null;
      _selectedProposal = null;
    });

    try {
      final proposal = await _repository.getRebalancingProposal(proposalId);
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedProposal = proposal;
        _isProposalBusy = false;
        _proposalStatusMessage = 'Proposal #${proposal.id} loaded successfully.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final readableError = _presentApiError(
        error,
        forbiddenMessage:
            'Rebalancing proposals are available only for dispatcher accounts.',
      );
      setState(() {
        _isProposalBusy = false;
        _proposalError = readableError;
      });
    }
  }

  Future<void> _runProposalMutation({
    required Future<void> Function(int proposalId) action,
    required String successMessage,
  }) async {
    final proposal = _selectedProposal;
    if (proposal == null) {
      return;
    }

    setState(() {
      _isProposalBusy = true;
      _proposalError = null;
      _proposalStatusMessage = null;
    });

    try {
      await action(proposal.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _proposalStatusMessage = successMessage;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      await _loadRebalancingProposal();
    } catch (error) {
      if (!mounted) {
        return;
      }

      final readableError = _presentApiError(
        error,
        forbiddenMessage:
            'Rebalancing moderation is available only for dispatcher accounts.',
      );
      setState(() {
        _isProposalBusy = false;
        _proposalError = readableError;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(readableError)),
      );
    }
  }

  Future<void> _approveSelectedProposal() {
    return _runProposalMutation(
      action: (proposalId) => _repository.approveRebalancingProposal(proposalId),
      successMessage: 'Proposal approved.',
    );
  }

  Future<void> _dismissSelectedProposal() {
    return _runProposalMutation(
      action: (proposalId) => _repository.dismissRebalancingProposal(proposalId),
      successMessage: 'Proposal dismissed.',
    );
  }

  Future<void> _openDeliveryRequests() async {
    _goTo(AppScreen.requests);
    await _loadDeliveryRequests();
  }

  Future<void> _setRequestFilters({
    String? status,
  }) async {
    setState(() {
      _requestsStatusFilter = status;
      _requestsPage = 1;
    });
    await _loadDeliveryRequests();
  }

  Future<void> _setAllocationStatusFilter(String? status) async {
    setState(() {
      _allocationsStatusFilter = status;
      _allocationsPage = 1;
    });
    await _loadDeliveryRequests();
  }

  Future<void> _loadDeliveryRequests() async {
    if (_isLoadingRequests) {
      return;
    }

    setState(() {
      _isLoadingRequests = true;
      _deliveryError = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _repository.getDeliveryRequests(
          status: _requestsStatusFilter,
          page: _requestsPage,
          pageSize: _requestsPageSize,
        ),
        _repository.getAllocations(
          status: _allocationsStatusFilter,
          page: _allocationsPage,
          pageSize: _allocationsPageSize,
        ),
      ]);

      if (!mounted) {
        return;
      }

      final requestList = results[0] as DeliveryRequestList;
      final allocationList = results[1] as AllocationList;

      setState(() {
        _deliveryRequests = requestList.requests;
        _allocations = allocationList.allocations;
        _deliveryRequestsTotal = requestList.total;
        _allocationsTotal = allocationList.total;
        _isLoadingRequests = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingRequests = false;
        _deliveryError = error.toString();
      });
    }
  }

  Future<void> _openDeliveryRequestDetail(DeliveryRequestSummary request) async {
    setState(() {
      _currentScreen = AppScreen.requestDetail;
      _navIndex = 0;
      _isMutatingRequest = true;
      _selectedRequestDetail = null;
      _deliveryError = null;
    });

    try {
      final detail = await _repository.getDeliveryRequestDetail(request.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedRequestDetail = detail;
        _isMutatingRequest = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isMutatingRequest = false;
        _deliveryError = error.toString();
      });
    }
  }

  Future<void> _refreshSelectedDeliveryRequest() async {
    final detail = _selectedRequestDetail;
    if (detail == null) {
      return;
    }

    setState(() {
      _isMutatingRequest = true;
      _deliveryError = null;
    });

    try {
      final refreshed = await _repository.getDeliveryRequestDetail(
        detail.request.id,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedRequestDetail = refreshed;
        _isMutatingRequest = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isMutatingRequest = false;
        _deliveryError = error.toString();
      });
    }
  }

  Future<void> _runDeliveryMutation({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    setState(() {
      _isMutatingRequest = true;
      _deliveryError = null;
    });

    try {
      await action();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );

      await Future.wait<void>([
        _refreshSelectedDeliveryRequest(),
        _loadDeliveryRequests(),
      ]);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isMutatingRequest = false;
        _deliveryError = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _runAllocatePending() async {
    setState(() {
      _isMutatingRequest = true;
      _deliveryError = null;
    });

    try {
      final allocated = await _repository.allocatePendingRequests();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Allocation run completed. Allocated: $allocated.')),
      );
      await _loadDeliveryRequests();
      if (!mounted) {
        return;
      }
      setState(() {
        _isMutatingRequest = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isMutatingRequest = false;
        _deliveryError = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _escalateSelectedRequest() async {
    final detail = _selectedRequestDetail;
    if (detail == null) {
      return;
    }
    await _runDeliveryMutation(
      action: () => _repository.escalateDeliveryRequest(detail.request.id),
      successMessage: 'Request priority escalated.',
    );
  }

  Future<void> _approveAllSelectedRequestAllocations() async {
    final detail = _selectedRequestDetail;
    if (detail == null) {
      return;
    }
    await _runDeliveryMutation(
      action: () => _repository.approveAllAllocations(detail.request.id),
      successMessage: 'All planned allocations approved.',
    );
  }

  Future<void> _cancelSelectedRequest() async {
    final detail = _selectedRequestDetail;
    if (detail == null) {
      return;
    }
    await _runDeliveryMutation(
      action: () => _repository.cancelDeliveryRequest(detail.request.id),
      successMessage: 'Request cancelled.',
    );
  }

  Future<void> _deliverSelectedRequest() async {
    final detail = _selectedRequestDetail;
    if (detail == null) {
      return;
    }
    await _runDeliveryMutation(
      action: () => _repository.deliverDeliveryRequest(detail.request.id),
      successMessage: 'Request marked as delivered.',
    );
  }

  Future<void> _updateSelectedRequestItemQuantity({
    required int resourceId,
    required num quantity,
  }) async {
    final detail = _selectedRequestDetail;
    if (detail == null) {
      return;
    }
    final normalizedQuantity = quantity < 1 ? 1 : quantity;

    await _runDeliveryMutation(
      action: () => _repository.updateDeliveryRequestItem(
        requestId: detail.request.id,
        resourceId: resourceId,
        quantity: normalizedQuantity,
      ),
      successMessage: 'Request item quantity updated.',
    );
  }

  Future<void> _approveAllocation(int allocationId) async {
    await _runDeliveryMutation(
      action: () => _repository.approveAllocation(allocationId),
      successMessage: 'Allocation approved.',
    );
  }

  Future<void> _dispatchAllocation(int allocationId) async {
    await _runDeliveryMutation(
      action: () => _repository.dispatchAllocation(allocationId),
      successMessage: 'Allocation dispatched.',
    );
  }

  Future<void> _rejectAllocation({
    required int allocationId,
    required String reason,
  }) async {
    await _runDeliveryMutation(
      action: () => _repository.rejectAllocation(
        allocationId: allocationId,
        reason: reason,
      ),
      successMessage: 'Allocation rejected.',
    );
  }

  bool get _canUseRebalancing => _userProfile?.role == UserRole.dispatcher;

  String _presentApiError(
    Object error, {
    String? forbiddenMessage,
  }) {
    if (error is ApiException) {
      final message = error.message.trim();
      final normalized = message.toLowerCase();
      if (error.isUnauthorized ||
          normalized.contains('validate token') ||
          normalized.contains('invalid token') ||
          normalized.contains('jwt')) {
        return 'Session expired or invalid. Sign in again.';
      }
      if (error.isForbidden) {
        return forbiddenMessage ??
            'You do not have permission for this action.';
      }
      return message;
    }
    return error.toString();
  }

  void _goTo(AppScreen screen) {
    if (_userProfile == null && screen != AppScreen.login) {
      return;
    }

    setState(() {
      if (screen != AppScreen.demand) {
        _requestError = null;
      }
      if (screen != AppScreen.demandReadings) {
        _demandError = null;
      }
      if (screen != AppScreen.rebalancingProposals) {
        _proposalError = null;
      }
      if (screen != AppScreen.stockNearest) {
        _nearestError = null;
      }
      if (screen != AppScreen.requests && screen != AppScreen.requestDetail) {
        _deliveryError = null;
      }
      _currentScreen = screen;
      _navIndex = switch (screen) {
        AppScreen.home => 0,
        AppScreen.alerts => 0,
        AppScreen.inventory => 1,
        AppScreen.detail => 0,
        AppScreen.requests => 0,
        AppScreen.requestDetail => 0,
        AppScreen.demandReadings => 0,
        AppScreen.rebalancingProposals => 0,
        AppScreen.stockNearest => 0,
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
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isRestoringSession) {
      return const ShellStatusView(
        title: 'RESTORING SESSION',
        message: 'Checking saved credentials and syncing with the API.',
        busy: true,
      );
    }

    if (_userProfile == null) {
      return LoginScreen(
        usernameController: _usernameController,
        passwordController: _passwordController,
        onInitialize: () => _handleLogin(),
        errorMessage: _authError,
        isSubmitting: _isAuthenticating,
      );
    }

    final inventoryOverview = _inventoryOverview;
    final resource = _resource ?? _fallbackResource;

    if (inventoryOverview == null) {
      return ShellStatusView(
        title: _isRefreshingData ? 'LOADING DATA' : 'SYNC ERROR',
        message: _dataError ??
            'The app signed in, but the first data sync did not complete.',
        busy: _isRefreshingData,
        primaryLabel: _isRefreshingData ? null : 'Retry Sync',
        onPrimary: _isRefreshingData ? null : () => _refreshCoreData(),
        secondaryLabel: _isRefreshingData ? null : 'Log Out',
        onSecondary: _isRefreshingData ? null : () => _handleLogout(),
      );
    }

    final locationTitle = 'Warehouse ${_userProfile!.locationLabel}';
    final criticalCount = _predictiveAlerts
            .where(
              (alert) => alert.severity == PredictiveAlertSeverity.critical,
            )
            .length +
        inventoryOverview.items
            .where((item) => item.health == InventoryHealth.critical)
            .length;

    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey<AppScreen>(_currentScreen),
            child: switch (_currentScreen) {
              AppScreen.login => LoginScreen(
                  usernameController: _usernameController,
                  passwordController: _passwordController,
                  onInitialize: () => _handleLogin(),
                  errorMessage: _authError,
                  isSubmitting: _isAuthenticating,
                ),
              AppScreen.alerts => AlertsScreen(
                  alerts: _predictiveAlerts,
                  actorRole: _userProfile!.role,
                  locationLabel: _userProfile!.locationLabel,
                  isBusy: _isRunningAlertAction || _isRefreshingData,
                  onDismissAlert: (alert) => _dismissAlert(alert),
                  onOpenProposal: (alert) => _openProposalFromAlert(alert),
                  onOpenMap: (_) => _goTo(AppScreen.map),
                  onRefresh: () => _refreshCoreData(),
                  onBack: () => _goTo(AppScreen.home),
                ),
              AppScreen.home => HomeScreen(
                  actorRole: _userProfile!.role,
                  queue: _queue,
                  navIndex: _navIndex,
                  locationLabel: _userProfile!.locationLabel,
                  locationTitle: locationTitle,
                  accountLabel: _userProfile!.initials,
                  activeCount: inventoryOverview.items.length,
                  pendingCount: _predictiveAlerts.length,
                  criticalCount: criticalCount,
                  onQuickScan: () => _goTo(AppScreen.scanner),
                  onRequestsTap: () => _openDeliveryRequests(),
                  onDemandReadingsTap: () => _openDemandReadings(),
                  onRebalancingTap: () => _openRebalancingProposals(),
                  onStockNearestTap: () => _openStockNearest(),
                  onAlertsTap: () => _goTo(AppScreen.alerts),
                  onAccountTap: () => _goTo(AppScreen.settings),
                  onQueueTap: _openQueueItem,
                  onNavigate: _handleNavigation,
                ),
              AppScreen.inventory => InventoryScreen(
                  overview: inventoryOverview,
                  onBack: () => _goTo(AppScreen.home),
                  onItemTap: _openInventoryItem,
                ),
              AppScreen.detail => DetailScreen(
                  resource: resource,
                  actorRole: _userProfile!.role,
                  returnLabel: _detailBackScreen == AppScreen.inventory
                      ? 'Back To Inventory'
                      : 'Back To Home',
                  onBack: () => _goTo(_detailBackScreen),
                  onCreateRequest: () {
                    setState(() {
                      _selectedUrgency = UrgencyLevel.critical;
                    });
                    _goTo(AppScreen.demand);
                  },
                  onConfirm: () => _goTo(_detailBackScreen),
                ),
              AppScreen.demand => DemandScreen(
                  resource: resource,
                  urgency: _selectedUrgency,
                  requestQuantity: _requestQuantity,
                  arriveTillController: _arriveTillController,
                  isSubmitting: _isSubmittingRequest,
                  errorMessage: _requestError,
                  onBack: () => _goTo(AppScreen.detail),
                  onConfirm: () => _submitDeliveryRequest(),
                  onUrgencyChange: (value) {
                    setState(() {
                      _selectedUrgency = value;
                    });
                  },
                  onQuantityChanged: (value) {
                    setState(() {
                      final normalized = value.clamp(
                        _minRequestQuantity,
                        _maxRequestQuantity,
                      );
                      _requestQuantity = normalized;
                    });
                  },
                ),
              AppScreen.requests => DeliveryRequestsScreen(
                  actorRole: _userProfile!.role,
                  requests: _deliveryRequests,
                  allocations: _allocations,
                  totalRequests: _deliveryRequestsTotal,
                  totalAllocations: _allocationsTotal,
                  selectedRequestStatus: _requestsStatusFilter,
                  selectedAllocationStatus: _allocationsStatusFilter,
                  isBusy: _isLoadingRequests || _isMutatingRequest,
                  errorMessage: _deliveryError,
                  onBack: () => _goTo(AppScreen.home),
                  onRefresh: () => _loadDeliveryRequests(),
                  onRequestStatusFilterChange: (value) =>
                      _setRequestFilters(status: value),
                  onAllocationStatusFilterChange: (value) =>
                      _setAllocationStatusFilter(value),
                  onRunAllocate: () => _runAllocatePending(),
                  onOpenRequest: (request) => _openDeliveryRequestDetail(request),
                ),
              AppScreen.requestDetail => _selectedRequestDetail == null
                  ? ShellStatusView(
                      title: _isMutatingRequest ? 'LOADING REQUEST' : 'REQUEST ERROR',
                      message: _deliveryError ??
                          'Request details are not loaded yet. Try to refresh and reopen.',
                      busy: _isMutatingRequest,
                      primaryLabel: _isMutatingRequest ? null : 'Back To List',
                      onPrimary: _isMutatingRequest
                          ? null
                          : () => _goTo(AppScreen.requests),
                    )
                  : DeliveryRequestDetailScreen(
                      detail: _selectedRequestDetail!,
                      actorRole: _userProfile!.role,
                      isBusy: _isMutatingRequest,
                      errorMessage: _deliveryError,
                      onBack: () => _goTo(AppScreen.requests),
                      onRefresh: () => _refreshSelectedDeliveryRequest(),
                      onEscalate: () => _escalateSelectedRequest(),
                      onApproveAll: () => _approveAllSelectedRequestAllocations(),
                      onCancel: () => _cancelSelectedRequest(),
                      onDeliver: () => _deliverSelectedRequest(),
                      onUpdateItemQuantity: (resourceId, quantity) =>
                          _updateSelectedRequestItemQuantity(
                        resourceId: resourceId,
                        quantity: quantity,
                      ),
                      onApproveAllocation: (allocationId) =>
                          _approveAllocation(allocationId),
                      onDispatchAllocation: (allocationId) =>
                          _dispatchAllocation(allocationId),
                      onRejectAllocation: (allocationId, reason) =>
                          _rejectAllocation(
                        allocationId: allocationId,
                        reason: reason,
                      ),
                    ),
              AppScreen.demandReadings => DemandReadingsScreen(
                  pointIdController: _demandPointIdController,
                  resourceIdController: _demandResourceIdController,
                  quantityController: _demandQuantityController,
                  recordedAtController: _demandRecordedAtController,
                  readings: _demandReadings,
                  total: _demandReadingsTotal,
                  isBusy: _isDemandBusy,
                  errorMessage: _demandError,
                  onBack: () => _goTo(AppScreen.home),
                  onRefresh: () => _loadDemandReadings(),
                  onSubmit: () => _submitDemandReading(),
                ),
              AppScreen.rebalancingProposals => RebalancingProposalScreen(
                  proposalIdController: _proposalIdController,
                  proposal: _selectedProposal,
                  actorRole: _userProfile!.role,
                  isBusy: _isProposalBusy,
                  errorMessage: _proposalError,
                  statusMessage: _proposalStatusMessage,
                  onBack: () => _goTo(AppScreen.home),
                  onLoad: () => _loadRebalancingProposal(),
                  onApprove: () => _approveSelectedProposal(),
                  onDismiss: () => _dismissSelectedProposal(),
                ),
              AppScreen.stockNearest => StockNearestScreen(
                  resourceIdController: _nearestResourceIdController,
                  pointIdController: _nearestPointIdController,
                  quantityController: _nearestQuantityController,
                  results: _nearestStockResults,
                  isBusy: _isNearestBusy,
                  errorMessage: _nearestError,
                  onBack: () => _goTo(AppScreen.home),
                  onLookup: () => _lookupNearestStock(),
                ),
              AppScreen.scanner => ScannerScreen(
                  onClose: () => _goTo(AppScreen.home),
                  onManual: () {
                    setState(() {
                      _detailBackScreen = AppScreen.scanner;
                    });
                    _goTo(AppScreen.detail);
                  },
                  onDetected: _handleScannerDetected,
                ),
              AppScreen.map => MapScreen(
                  points: _mapPoints,
                  onBack: () => _goTo(AppScreen.home),
                ),
              AppScreen.settings => SettingsScreen(
                  profile: _userProfile!,
                  onBack: () => _goTo(AppScreen.home),
                  onLogout: () => _handleLogout(),
                ),
            },
          ),
        ),
        if (_isRefreshingData)
          const Positioned(
            top: 12,
            left: 18,
            right: 18,
            child: LinearProgressIndicator(
              minHeight: 3,
              color: AppColors.warmGold,
              backgroundColor: AppColors.stroke,
            ),
          ),
      ],
    );
  }

  ResourceRecord _buildResourceRecord(InventoryOverview overview) {
    if (overview.items.isEmpty) {
      return _fallbackResource;
    }

    final preferred = overview.items.firstWhere(
      (item) => item.health != InventoryHealth.healthy,
      orElse: () => overview.items.first,
    );

    return buildResourceRecordFromItem(
      item: preferred,
      lastUpdatedLabel: 'Live sync',
    );
  }

  ResourceRecord get _fallbackResource => fallbackResourceRecord;
}
