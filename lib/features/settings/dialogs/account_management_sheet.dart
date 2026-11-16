// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../dialogs/dialogs.dart';

/// Mostra il bottom sheet di gestione account per l'utente loggato.
void showAccountManagementSheet({
  required BuildContext context,
  required FirebaseAuth auth,
  required String? optimisticDisplayName,
  required void Function(String message, {bool isError}) onTriggerToast,
  required void Function(String) onUpdateOptimisticDisplayName,
  required Future<void> Function(BuildContext) onLogout,
  required Widget Function(BuildContext, bool, {double size}) buildAvatar,
}) {
  final currentUser = auth.currentUser;
  if (currentUser == null) return;

  final String initialDisplayName =
      optimisticDisplayName ?? currentUser.displayName ?? "";

  String providerName = "Account";
  IconData providerIcon = Icons.account_circle_outlined;
  if (currentUser.providerData.isNotEmpty) {
    final pid = currentUser.providerData.first.providerId;
    if (pid.contains('google')) {
      providerName = "Google";
      providerIcon = Icons.g_mobiledata;
    } else if (pid.contains('facebook')) {
      providerName = "Facebook";
      providerIcon = Icons.facebook;
    } else if (pid.contains('password')) {
      providerName = "Email";
      providerIcon = Icons.email_outlined;
    } else if (pid.contains('phone')) {
      providerName = "Telefono";
      providerIcon = Icons.phone_android;
    }
  }
  final String identifier =
      (currentUser.email != null && currentUser.email!.isNotEmpty)
      ? currentUser.email!
      : ((currentUser.phoneNumber != null &&
                currentUser.phoneNumber!.isNotEmpty)
            ? currentUser.phoneNumber!
            : "Dati cloud");

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: false,
    constraints: const BoxConstraints(maxWidth: 500),
    backgroundColor: context.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (ctx) {
      return _AccountManagementSheetContent(
        parentContext: context,
        auth: auth,
        currentUser: currentUser,
        initialDisplayName: initialDisplayName,
        providerName: providerName,
        providerIcon: providerIcon,
        identifier: identifier,
        onTriggerToast: onTriggerToast,
        onUpdateOptimisticDisplayName: onUpdateOptimisticDisplayName,
        onLogout: onLogout,
        buildAvatar: buildAvatar,
      );
    },
  );
}

class _AccountManagementSheetContent extends StatefulWidget {
  final BuildContext parentContext;
  final FirebaseAuth auth;
  final User currentUser;
  final String initialDisplayName;
  final String providerName;
  final IconData providerIcon;
  final String identifier;
  final void Function(String message, {bool isError}) onTriggerToast;
  final void Function(String) onUpdateOptimisticDisplayName;
  final Future<void> Function(BuildContext) onLogout;
  final Widget Function(BuildContext, bool, {double size}) buildAvatar;

  const _AccountManagementSheetContent({
    required this.parentContext,
    required this.auth,
    required this.currentUser,
    required this.initialDisplayName,
    required this.providerName,
    required this.providerIcon,
    required this.identifier,
    required this.onTriggerToast,
    required this.onUpdateOptimisticDisplayName,
    required this.onLogout,
    required this.buildAvatar,
  });

  @override
  State<_AccountManagementSheetContent> createState() =>
      _AccountManagementSheetContentState();
}

class _AccountManagementSheetContentState
    extends State<_AccountManagementSheetContent>
    with SingleTickerProviderStateMixin {
  late String _currentDisplayName;
  bool _isEditingName = false;
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;
  late final AnimationController _animController;
  late final Animation<double> _animation;
  late final Animation<double> _fadeInAnimation;
  late final Animation<double> _fadeOutAnimation;
  late final Animation<double> _collapseAnimation;
  Timer? _unfocusTimer;

  @override
  void initState() {
    super.initState();
    _currentDisplayName = widget.initialDisplayName;
    _nameController = TextEditingController(text: _currentDisplayName);
    _nameFocusNode = FocusNode();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _fadeInAnimation = _animation;
    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_animation);
    _collapseAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_animation);
  }

  @override
  void dispose() {
    _unfocusTimer?.cancel();
    _animController.dispose();
    _nameFocusNode.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _scheduleUnfocus() {
    _unfocusTimer?.cancel();
    _unfocusTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        _nameFocusNode.unfocus();
      }
    });
  }

  void _startEditing() {
    _unfocusTimer?.cancel();
    _nameController.text = _currentDisplayName;
    _nameController.selection = TextSelection.fromPosition(
      TextPosition(offset: _currentDisplayName.length),
    );
    setState(() {
      _isEditingName = true;
    });
    _animController.forward();
    _nameFocusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isEditingName && !_nameFocusNode.hasFocus) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  void _cancelEditing() {
    _scheduleUnfocus();
    _nameController.text = _currentDisplayName;
    setState(() {
      _isEditingName = false;
    });
    _animController.reverse();
  }

  Future<void> _handleSaveName(String newName) async {
    _scheduleUnfocus();
    if (newName != _currentDisplayName) {
      final previousName = _currentDisplayName;
      widget.onUpdateOptimisticDisplayName(newName);
      setState(() {
        _currentDisplayName = newName;
        _isEditingName = false;
      });
      _animController.reverse();
      try {
        await widget.currentUser.updateDisplayName(newName);
      } catch (e) {
        if (mounted) {
          setState(() {
            _currentDisplayName = previousName;
          });
        }
        widget.onUpdateOptimisticDisplayName(previousName);
        widget.onTriggerToast(
          "settings.account.updateNameError".tr(),
          isError: true,
        );
      }
    } else {
      setState(() {
        _isEditingName = false;
      });
      _animController.reverse();
    }
  }

  Widget _buildDisplayNameView(ColorScheme colorScheme) {
    return Column(
      key: const ValueKey("InlineDisplayNameView"),
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _currentDisplayName.isNotEmpty
                ? _currentDisplayName
                : "auth.social.addYourName".tr(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _startEditing,
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: Text(
            "settings.account.editName".tr(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildEditNameView(ColorScheme colorScheme) {
    return Column(
      key: const ValueKey("InlineEditNameView"),
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            height: 48,
            child: TextField(
              key: const ValueKey("InlineEditNameTextField"),
              controller: _nameController,
              focusNode: _nameFocusNode,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              cursorColor: colorScheme.primary,
              textInputAction: TextInputAction.done,
              onSubmitted: (val) {
                final trimmed = val.trim();
                if (trimmed.isNotEmpty) {
                  _handleSaveName(trimmed);
                }
              },
              decoration: InputDecoration(
                hintText: "settings.account.editNameHint".tr(),
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                isDense: true,
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  maxWidth: 40,
                  minHeight: 40,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(
                    Icons.badge_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: OutlinedButton(
                  onPressed: _cancelEditing,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    minimumSize: const Size(0, 40),
                  ),
                  child: Text(
                    "common.actions.cancel".tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _nameController,
                  builder: (context, value, child) {
                    final bool isValid = value.text.trim().isNotEmpty;
                    return FilledButton(
                      onPressed: isValid
                          ? () => _handleSaveName(value.text.trim())
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        "common.actions.save".tr(),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNameSection(ColorScheme colorScheme) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Offstage(
            offstage: _isEditingName && _animController.isCompleted,
            child: FadeTransition(
              opacity: _fadeOutAnimation,
              child: IgnorePointer(
                ignoring: _isEditingName,
                child: _buildDisplayNameView(colorScheme),
              ),
            ),
          ),
          Offstage(
            offstage: !_isEditingName && _animController.isDismissed,
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: IgnorePointer(
                ignoring: !_isEditingName,
                child: _buildEditNameView(colorScheme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActionButtons(ColorScheme colorScheme) {
    return Column(
      key: const ValueKey("AccountActionButtons"),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Divider(
          height: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout(widget.parentContext);
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
              foregroundColor: colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.logout, size: 20),
            label: Text(
              "settings.account.signOut".tr(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AppDestructiveActionButton(
          onPressed: () {
            Navigator.pop(context);
            showDeleteAccountFlow(
              context: widget.parentContext,
              auth: widget.auth,
              onTriggerToast: widget.onTriggerToast,
            );
          },
          icon: Icons.person_remove_outlined,
          label: "settings.account.deleteAccount".tr(),
        ),
      ],
    );
  }

  Widget _buildAccountActions(ColorScheme colorScheme) {
    return SizeTransition(
      sizeFactor: _collapseAnimation,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _collapseAnimation,
        child: AnimatedBuilder(
          animation: _collapseAnimation,
          builder: (context, child) {
            if (_collapseAnimation.value == 0.0 && _isEditingName) {
              return const SizedBox(width: double.infinity, height: 0);
            }
            return child!;
          },
          child: _buildAccountActionButtons(colorScheme),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          key: const ValueKey("MenuView"),
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.only(top: 16, bottom: 24),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            widget.buildAvatar(context, false, size: 80),
            const SizedBox(height: 16),
            _buildNameSection(colorScheme),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (widget.providerName == "Google" ||
                                    widget.providerName == "Facebook")
                                ? Colors.transparent
                                : colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: widget.providerName == "Google"
                              ? Image.asset(
                                  'assets/icons/google.png',
                                  width: 28,
                                  height: 28,
                                )
                              : widget.providerName == "Facebook"
                              ? Image.asset(
                                  'assets/icons/facebook.png',
                                  width: 28,
                                  height: 28,
                                )
                              : Icon(
                                  widget.providerIcon,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 24,
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.identifier,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.link,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      "auth.social.connectedWith".tr(
                                        namedArgs: {
                                          "provider": widget.providerName,
                                        },
                                      ),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    _buildAccountActions(colorScheme),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
