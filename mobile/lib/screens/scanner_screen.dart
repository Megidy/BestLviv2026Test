import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({
    super.key,
    required this.onClose,
    required this.onManual,
    required this.onDetected,
  });

  final VoidCallback onClose;
  final VoidCallback onManual;
  final ValueChanged<String> onDetected;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isHandlingScan = false;
  String? _lastScannedValue;
  String _scannerStatus = 'Scanning for Resource ID...';

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: Row(
            children: [
              SmallSquareButton(
                icon: Icons.close_rounded,
                onTap: widget.onClose,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mutedGold,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.goldStroke),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.route_rounded,
                      size: 13,
                      color: AppColors.creamText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'DEMAND_OBJECTIVE',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.creamText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              const Positioned.fill(child: ScannerBackdrop()),
              Positioned.fill(
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: _handleDetect,
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.canvas.withValues(alpha: 0.18),
                          AppColors.canvas.withValues(alpha: 0.42),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    children: [
                      const Positioned.fill(child: ScannerFrame()),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 110,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.white54,
                                    blurRadius: 18,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 78),
                            Text(
                              'ALIGN QR CODE',
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _scannerStatus,
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          child: Column(
            children: [
              PanelCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.mutedGold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.settings_input_antenna_rounded,
                        size: 18,
                        color: AppColors.creamText,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LOGISYNC SCANNER v2.4',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.softText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _statusLine(),
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Grant camera permission when prompted.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.greenOk,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ValueListenableBuilder<TorchState>(
                      valueListenable: _scannerController.torchState,
                      builder: (context, state, child) {
                        final flashOn = state == TorchState.on;
                        return ScannerActionTile(
                          label: 'Flash',
                          icon: flashOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          selected: flashOn,
                          onTap: _toggleFlash,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ScannerActionTile(
                      label: 'Recent',
                      icon: Icons.history_rounded,
                      onTap: _showRecentScan,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ScannerActionTile(
                      label: 'Manual',
                      icon: Icons.tune_rounded,
                      selected: true,
                      onTap: widget.onManual,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isHandlingScan) {
      return;
    }

    String? value;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim();
      if (rawValue != null && rawValue.isNotEmpty) {
        value = rawValue;
        break;
      }
    }

    if (value == null) {
      return;
    }

    setState(() {
      _isHandlingScan = true;
      _lastScannedValue = value;
      _scannerStatus = 'QR detected. Resolving resource...';
    });

    widget.onDetected(value);

    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _isHandlingScan = false;
        _scannerStatus = 'Scanning for Resource ID...';
      });
    });
  }

  Future<void> _toggleFlash() async {
    try {
      await _scannerController.toggleTorch();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flashlight is unavailable on this device.'),
        ),
      );
    }
  }

  void _showRecentScan() {
    final recent = _lastScannedValue;
    final message = recent == null || recent.isEmpty
        ? 'No recent scans yet.'
        : 'Last scanned: $recent';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _statusLine() {
    final value = _lastScannedValue;
    if (value == null || value.trim().isEmpty) {
      return 'Ready for industrial input';
    }
    return 'Last QR: $value';
  }
}
