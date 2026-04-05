import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DemandScreen extends StatefulWidget {
  const DemandScreen({
    super.key,
    required this.resource,
    required this.urgency,
    required this.requestQuantity,
    required this.arriveTillController,
    required this.isSubmitting,
    this.errorMessage,
    required this.onBack,
    required this.onConfirm,
    required this.onUrgencyChange,
    required this.onQuantityChanged,
  });

  final ResourceRecord resource;
  final UrgencyLevel urgency;
  final int requestQuantity;
  final TextEditingController arriveTillController;
  final bool isSubmitting;
  final String? errorMessage;
  final VoidCallback onBack;
  final VoidCallback onConfirm;
  final ValueChanged<UrgencyLevel> onUrgencyChange;
  final ValueChanged<int> onQuantityChanged;

  @override
  State<DemandScreen> createState() => _DemandScreenState();
}

class _DemandScreenState extends State<DemandScreen> {
  static const int _minRequestAmount = 1;
  static const int _maxRequestAmount = 1000000;

  late final TextEditingController _quantityController;
  String? _quantityError;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.requestQuantity.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant DemandScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestQuantity != widget.requestQuantity) {
      final normalized = widget.requestQuantity.clamp(
        _minRequestAmount,
        _maxRequestAmount,
      );
      final nextText = normalized.toString();
      if (_quantityController.text != nextText) {
        _quantityController.text = nextText;
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountError = _quantityError;
    final apiError = widget.errorMessage;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.close_rounded),
              ),
              Expanded(
                child: Text(
                  'CREATE REQUEST',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: [
                PanelCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.redAlert.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              color: AppColors.redAlert,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.resource.name,
                                  style: theme.textTheme.titleLarge,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _formatCategory(widget.resource.category),
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final singleColumn = constraints.maxWidth < 320;

                          if (singleColumn) {
                            return Column(
                              children: [
                                _ResourceMetricTile(
                                  label: 'Current Quantity',
                                  value: widget.resource.quantityValueLabel,
                                ),
                                const SizedBox(height: 8),
                                _ResourceMetricTile(
                                  label: 'Unit',
                                  value: widget.resource.normalizedUnitLabel,
                                ),
                                const SizedBox(height: 8),
                                _ResourceMetricTile(
                                  label: 'Location',
                                  value: _formatLocationValue(
                                    widget.resource.location,
                                  ),
                                  maxLines: 1,
                                  compactValue: true,
                                ),
                                const SizedBox(height: 8),
                                _ResourceMetricTile(
                                  label: 'Health',
                                  value: widget.resource.healthLabel,
                                  valueColor:
                                      _healthColor(widget.resource.health),
                                ),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _ResourceMetricTile(
                                      label: 'Current Quantity',
                                      value: widget.resource.quantityValueLabel,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _ResourceMetricTile(
                                      label: 'Unit',
                                      value:
                                          widget.resource.normalizedUnitLabel,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ResourceMetricTile(
                                      label: 'Location',
                                      value: _formatLocationValue(
                                        widget.resource.location,
                                      ),
                                      maxLines: 1,
                                      compactValue: true,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _ResourceMetricTile(
                                      label: 'Health',
                                      value: widget.resource.healthLabel,
                                      valueColor:
                                          _healthColor(widget.resource.health),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'SET URGENCY LEVEL',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.softText,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _UrgencySelectorTile(
                        label: 'NORMAL',
                        icon: Icons.check_circle_outline_rounded,
                        selected: widget.urgency == UrgencyLevel.normal,
                        color: AppColors.greenOk,
                        onTap: () => widget.onUrgencyChange(UrgencyLevel.normal),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _UrgencySelectorTile(
                        label: 'ELEVATED',
                        icon: Icons.warning_amber_rounded,
                        selected: widget.urgency == UrgencyLevel.elevated,
                        color: AppColors.amberWarn,
                        onTap: () =>
                            widget.onUrgencyChange(UrgencyLevel.elevated),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _UrgencySelectorTile(
                        label: 'CRITICAL',
                        icon: Icons.error_outline_rounded,
                        selected: widget.urgency == UrgencyLevel.critical,
                        color: AppColors.redAlert,
                        onTap: () =>
                            widget.onUrgencyChange(UrgencyLevel.critical),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _UrgencySelectorTile(
                        label: 'URGENT',
                        icon: Icons.bolt_rounded,
                        selected: widget.urgency == UrgencyLevel.urgent,
                        color: AppColors.warmGold,
                        onTap: () => widget.onUrgencyChange(UrgencyLevel.urgent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'REQUEST AMOUNT',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.softText,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.creamText,
                        ),
                        onChanged: _onQuantityChanged,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          helperText:
                              'Allowed range: $_minRequestAmount-$_maxRequestAmount',
                          errorText: amountError,
                          filled: true,
                          fillColor: AppColors.panel,
                          border: _inputBorder(),
                          enabledBorder: _inputBorder(),
                          focusedBorder: _inputBorder(const Color(0xFF8A6A24)),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _QuickAmountButton(
                      label: '+10',
                      onTap: () => _addAmount(10),
                    ),
                    const SizedBox(width: 6),
                    _QuickAmountButton(
                      label: '+50',
                      onTap: () => _addAmount(50),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ARRIVE BY',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.softText,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: widget.arriveTillController,
                  readOnly: true,
                  onTap: _pickArriveBy,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.creamText,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Date and time',
                    hintText: 'Select arrive-by date and time',
                    prefixIcon: const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.softText,
                      size: 18,
                    ),
                    suffixIcon: widget.arriveTillController.text.trim().isEmpty
                        ? const Icon(
                            Icons.access_time_rounded,
                            color: AppColors.softText,
                            size: 18,
                          )
                        : IconButton(
                            onPressed: _clearArriveBy,
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.softText,
                              size: 18,
                            ),
                          ),
                    filled: true,
                    fillColor: AppColors.panel,
                    border: _inputBorder(),
                    enabledBorder: _inputBorder(),
                    focusedBorder: _inputBorder(const Color(0xFF8A6A24)),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.urgency == UrgencyLevel.urgent
                      ? 'Required for URGENT. Auto format: YYYY-MM-DDTHH:mm:ss'
                      : 'Optional unless urgency is set to URGENT.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: widget.urgency == UrgencyLevel.urgent
                        ? AppColors.amberWarn
                        : AppColors.softText,
                  ),
                ),
                if (apiError != null && apiError.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    apiError,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.redAlert,
                    ),
                  ),
                ],
                const Spacer(),
              ],
            ),
          ),
          PrimaryActionButton(
            label: widget.isSubmitting ? 'Submitting...' : 'Create Request',
            icon: Icons.check_rounded,
            onPressed: widget.isSubmitting ? null : _handleConfirmPressed,
          ),
          const SizedBox(height: 8),
          OutlineActionButton(
            label: 'Cancel',
            icon: Icons.close_rounded,
            onTap: widget.onBack,
            fillWidth: true,
          ),
        ],
      ),
    );
  }

  Future<void> _pickArriveBy() async {
    final now = DateTime.now();
    final currentText = widget.arriveTillController.text.trim();
    final currentValue = DateTime.tryParse(currentText);
    final initialDate = currentValue ?? now;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
      helpText: 'Select arrive-by date',
    );

    if (!mounted || selectedDate == null) {
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentValue ?? now),
      helpText: 'Select arrive-by time',
    );

    if (!mounted || selectedTime == null) {
      return;
    }

    final selected = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    setState(() {
      widget.arriveTillController.text = _toIsoLocal(selected);
    });
  }

  void _clearArriveBy() {
    setState(() {
      widget.arriveTillController.clear();
    });
  }

  void _addAmount(int delta) {
    final current = _parseAmount(_quantityController.text) ?? widget.requestQuantity;
    final next = (current + delta).clamp(_minRequestAmount, _maxRequestAmount);
    _quantityController.text = next.toString();
    _onQuantityChanged(_quantityController.text);
  }

  void _handleConfirmPressed() {
    final amount = _parseAmount(_quantityController.text);
    if (amount == null) {
      setState(() {
        _quantityError = 'Enter a whole number.';
      });
      return;
    }

    if (amount < _minRequestAmount || amount > _maxRequestAmount) {
      setState(() {
        _quantityError =
            'Amount must be between $_minRequestAmount and $_maxRequestAmount.';
      });
      return;
    }

    if (widget.urgency == UrgencyLevel.urgent &&
        widget.arriveTillController.text.trim().isEmpty) {
      setState(() {
        _quantityError = null;
      });
      widget.onConfirm();
      return;
    }

    setState(() {
      _quantityError = null;
    });
    widget.onConfirm();
  }

  void _onQuantityChanged(String raw) {
    final value = _parseAmount(raw);
    if (raw.trim().isEmpty) {
      setState(() {
        _quantityError = 'Amount is required.';
      });
      return;
    }

    if (value == null) {
      setState(() {
        _quantityError = 'Only whole numbers are allowed.';
      });
      return;
    }

    if (value < _minRequestAmount || value > _maxRequestAmount) {
      setState(() {
        _quantityError =
            'Amount must be between $_minRequestAmount and $_maxRequestAmount.';
      });
      return;
    }

    setState(() {
      _quantityError = null;
    });
    widget.onQuantityChanged(value);
  }

  int? _parseAmount(String raw) {
    return int.tryParse(raw.trim());
  }

  OutlineInputBorder _inputBorder([Color color = AppColors.stroke]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }

  Color _healthColor(InventoryHealth health) {
    return switch (health) {
      InventoryHealth.healthy => AppColors.greenOk,
      InventoryHealth.low => AppColors.amberWarn,
      InventoryHealth.critical => AppColors.redAlert,
    };
  }

  String _toIsoLocal(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$year-$month-${day}T$hour:$minute:00';
  }

  String _formatCategory(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'Uncategorized';
    }

    final words = trimmed.split(RegExp(r'[\s_-]+'));
    return words
        .where((word) => word.isNotEmpty)
        .map((word) {
          if (word.length == 1) {
            return word.toUpperCase();
          }
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }

  String _formatLocationValue(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'Unknown';
    }

    final normalized = trimmed
        .replaceAll(RegExp(r'\s+', caseSensitive: false), ' ')
        .replaceAll(
          RegExp(r'warehouse\s+location', caseSensitive: false),
          'Warehouse',
        )
        .trim();
    return normalized;
  }
}

class _ResourceMetricTile extends StatelessWidget {
  const _ResourceMetricTile({
    required this.label,
    required this.value,
    this.maxLines = 1,
    this.valueColor = AppColors.creamText,
    this.compactValue = false,
  });

  final String label;
  final String value;
  final int maxLines;
  final Color valueColor;
  final bool compactValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: (compactValue
                    ? theme.textTheme.titleSmall
                    : theme.textTheme.titleMedium)
                ?.copyWith(
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgencySelectorTile extends StatelessWidget {
  const _UrgencySelectorTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 62,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.2) : AppColors.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : AppColors.stroke,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? color.withValues(alpha: 0.25)
                    : Colors.transparent,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected ? AppColors.creamText : AppColors.softText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAmountButton extends StatelessWidget {
  const _QuickAmountButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Ink(
        width: 54,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
