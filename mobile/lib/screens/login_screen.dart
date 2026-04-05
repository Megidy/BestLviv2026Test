import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.onInitialize,
    this.errorMessage,
    this.isSubmitting = false,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final VoidCallback onInitialize;
  final String? errorMessage;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2A0303),
            Color(0xFF240304),
            Color(0xFF1A0304),
            Color(0xFF090607),
          ],
          stops: [0.0, 0.42, 0.78, 1.0],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
          final tightMode = keyboardVisible || constraints.maxHeight < 690;
          final compactHeight = constraints.maxHeight < 760;
          final horizontalPadding = compactHeight ? 20.0 : 24.0;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              tightMode ? 12 : 20,
              horizontalPadding,
              tightMode ? 12 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LoginHeaderSection(
                  visible: !tightMode,
                  compactHeight: compactHeight,
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: _LoginAuthCard(
                        usernameController: usernameController,
                        passwordController: passwordController,
                        onInitialize: onInitialize,
                        errorMessage: errorMessage,
                        isSubmitting: isSubmitting,
                        showSubtitle: !tightMode,
                        showSecondaryLinks: !tightMode,
                        compact: tightMode,
                      ),
                    ),
                  ),
                ),
                _VisibilityCollapse(
                  visible: !tightMode,
                  child: const _LoginFooter(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LoginAuthCard extends StatelessWidget {
  const _LoginAuthCard({
    required this.usernameController,
    required this.passwordController,
    required this.onInitialize,
    required this.errorMessage,
    required this.isSubmitting,
    required this.showSubtitle,
    required this.showSecondaryLinks,
    required this.compact,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final VoidCallback onInitialize;
  final String? errorMessage;
  final bool isSubmitting;
  final bool showSubtitle;
  final bool showSecondaryLinks;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PanelCard(
      padding: EdgeInsets.all(compact ? 12 : 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operator Authentication',
            style: theme.textTheme.titleMedium,
          ),
          _VisibilityCollapse(
            visible: showSubtitle,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Authenticate against the deployed API',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          SizedBox(height: compact ? 12 : 18),
          TerminalField(
            label: 'Username',
            controller: usernameController,
            prefixIcon: Icons.badge_outlined,
          ),
          const SizedBox(height: 12),
          TerminalField(
            label: 'Password',
            controller: passwordController,
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: Icons.visibility_outlined,
          ),
          if (errorMessage != null && errorMessage!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.redAlert,
              ),
            ),
          ],
          const SizedBox(height: 14),
          PrimaryActionButton(
            label: isSubmitting ? 'Signing In...' : 'Sign In',
            icon: Icons.login_rounded,
            onPressed: isSubmitting ? null : onInitialize,
          ),
          _VisibilityCollapse(
            visible: showSecondaryLinks,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Forgot Key',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.creamText,
                      ),
                    ),
                    Text(
                      'Emergency Bypass',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.creamText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginHeaderSection extends StatelessWidget {
  const _LoginHeaderSection({
    required this.visible,
    required this.compactHeight,
  });

  final bool visible;
  final bool compactHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _VisibilityCollapse(
      visible: visible,
      child: Column(
        children: [
          const SizedBox(height: 6),
          const Center(child: SyncMark(size: 64)),
          SizedBox(height: compactHeight ? 12 : 16),
          Text(
            'LOGISYNC',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          Text(
            'INDUSTRIAL TERMINAL v4.2',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.softText,
            ),
          ),
          SizedBox(height: compactHeight ? 28 : 44),
        ],
      ),
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        const DecorativeDivider(),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: const [
            FooterChip(
              label: 'NETWORK SECURE',
              icon: Icons.shield_outlined,
            ),
            FooterChip(
              label: 'SYNC READY',
              icon: Icons.blur_circular_rounded,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'SECURE INDUSTRIAL INTERFACE',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.softText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '(C) 2026 LOGISYNC SYSTEMS INC.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}

class _VisibilityCollapse extends StatelessWidget {
  const _VisibilityCollapse({
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return visible ? child : const SizedBox.shrink();
  }
}
