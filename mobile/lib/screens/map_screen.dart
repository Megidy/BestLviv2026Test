import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.points,
    required this.swaggerJsonUrl,
    required this.mapPointsEndpointUrl,
    required this.onBack,
  });

  final List<FacilityMapPoint> points;
  final String swaggerJsonUrl;
  final String mapPointsEndpointUrl;
  final VoidCallback onBack;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  FacilityMapPoint? _selectedPoint;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    if (widget.points.isNotEmpty) {
      _selectedPoint = widget.points.first;
    }
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.points, widget.points)) {
      return;
    }

    if (widget.points.isEmpty) {
      _selectedPoint = null;
      return;
    }

    final selectedId = _selectedPoint?.id;
    FacilityMapPoint? matchedPoint;
    if (selectedId != null) {
      for (final point in widget.points) {
        if (point.id == selectedId) {
          matchedPoint = point;
          break;
        }
      }
    }
    _selectedPoint = matchedPoint ?? widget.points.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initialPoint = widget.points.isNotEmpty
        ? widget.points.first
        : const FacilityMapPoint(
            id: 0,
            name: 'No map points',
            latitude: 49.8397,
            longitude: 24.0297,
            type: MapPointType.warehouse,
            status: MapPointStatus.normal,
            alertCount: 0,
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _isFullscreen ? 10 : 18,
        _isFullscreen ? 10 : 18,
        _isFullscreen ? 10 : 18,
        _isFullscreen ? 12 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isFullscreen) ...[
            Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                Expanded(
                  child: Text(
                    'FACILITY MAP',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 10),
            const _LegendBar(),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_isFullscreen ? 28 : 22),
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        initialPoint.latitude,
                        initialPoint.longitude,
                      ),
                      initialZoom: 12.4,
                      onTap: (_, _) {
                        setState(() {
                          _selectedPoint = null;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'logisync_mobile',
                      ),
                      MarkerLayer(
                        markers: widget.points.map((point) {
                          final color = _colorFor(point.status);
                          final selected = _selectedPoint?.id == point.id;
                          return Marker(
                            point: LatLng(point.latitude, point.longitude),
                            width: 88,
                            height: 88,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPoint = point;
                                });
                              },
                              child: _MapMarker(
                                label: point.name,
                                color: color,
                                selected: selected,
                                alertCount: point.alertCount,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      children: [
                        if (_isFullscreen) ...[
                          _MapOverlayButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: widget.onBack,
                          ),
                          const SizedBox(width: 8),
                        ],
                        _MapOverlayButton(
                          icon: _isFullscreen
                              ? Icons.close_fullscreen_rounded
                              : Icons.open_in_full_rounded,
                          onTap: () {
                            setState(() {
                              _isFullscreen = !_isFullscreen;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: PanelCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.hub_rounded,
                            size: 16,
                            color: AppColors.warmGold,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.points.length} points',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.creamText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isFullscreen)
                    const Positioned(
                      top: 62,
                      left: 12,
                      right: 12,
                      child: _LegendBar(compact: true),
                    ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.canvas.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.stroke),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          '© OpenStreetMap contributors',
                          style: TextStyle(
                            color: AppColors.creamText,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isFullscreen)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 44,
                      child: _SelectedPointCard(
                        point: _selectedPoint,
                        endpointUrl: widget.mapPointsEndpointUrl,
                        compact: true,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!_isFullscreen) ...[
            const SizedBox(height: 12),
            _SelectedPointCard(
              point: _selectedPoint,
              endpointUrl: widget.mapPointsEndpointUrl,
            ),
          ],
        ],
      ),
    );
  }

  Color _colorFor(MapPointStatus status) {
    return switch (status) {
      MapPointStatus.normal => AppColors.greenOk,
      MapPointStatus.elevated => AppColors.amberWarn,
      MapPointStatus.critical => AppColors.redAlert,
      MapPointStatus.predictive => AppColors.warmGold,
    };
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.mutedGold.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.creamText,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendBar extends StatelessWidget {
  const _LegendBar({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 8 : 10,
      ),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          runAlignment: WrapAlignment.center,
          runSpacing: compact ? 6 : 8,
          spacing: compact ? 6 : 8,
          children: const [
            _LegendChip(
              color: AppColors.greenOk,
              label: 'Normal',
            ),
            _LegendChip(
              color: AppColors.amberWarn,
              label: 'Elevated',
            ),
            _LegendChip(
              color: AppColors.redAlert,
              label: 'Critical',
            ),
            _LegendChip(
              color: AppColors.warmGold,
              label: 'Predictive',
            ),
          ],
        ),
      ),
    );
  }
}

class _MapOverlayButton extends StatelessWidget {
  const _MapOverlayButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.canvas.withValues(alpha: 0.84),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.stroke),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            size: 20,
            color: AppColors.creamText,
          ),
        ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.label,
    required this.color,
    required this.selected,
    required this.alertCount,
  });

  final String label;
  final Color color;
  final bool selected;
  final int alertCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? 32 : 28,
          height: selected ? 32 : 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.creamText,
              width: selected ? 2.5 : 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              alertCount.toString(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.canvas,
              ),
            ),
          ),
        ),
        if (selected) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxWidth: 108),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.canvas.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.creamText,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}

class _SelectedPointCard extends StatelessWidget {
  const _SelectedPointCard({
    required this.point,
    required this.endpointUrl,
    this.compact = false,
  });

  final FacilityMapPoint? point;
  final String endpointUrl;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (point == null) {
      return PanelCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(
              Icons.touch_app_rounded,
              color: AppColors.warmGold,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tap a point on the map to inspect warehouse or customer status.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.creamText,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final color = switch (point!.status) {
      MapPointStatus.normal => AppColors.greenOk,
      MapPointStatus.elevated => AppColors.amberWarn,
      MapPointStatus.critical => AppColors.redAlert,
      MapPointStatus.predictive => AppColors.warmGold,
    };

    return PanelCard(
      padding: EdgeInsets.all(compact ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  point!.name,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 10),
              StatusPill(
                label: point!.statusLabel.toUpperCase(),
                color: color,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.location_city_rounded,
                label: point!.typeLabel,
              ),
              _InfoChip(
                icon: Icons.notifications_active_outlined,
                label: '${point!.alertCount} alerts',
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MetaColumn(
            label: 'Coordinates',
            value:
                '${point!.latitude.toStringAsFixed(4)}, ${point!.longitude.toStringAsFixed(4)}',
          ),
          const SizedBox(height: 10),
          _MetaColumn(
            label: 'Source',
            value: endpointUrl,
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.mutedGold.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.warmGold),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.creamText,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaColumn extends StatelessWidget {
  const _MetaColumn({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.softText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.creamText,
          ),
          softWrap: true,
        ),
      ],
    );
  }
}
