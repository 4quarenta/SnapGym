import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/sg_colors.dart';
import '../../../core/theme/sg_spacing.dart';
import '../data/update_repository.dart';
import '../domain/app_update.dart';

class UpdateGate extends ConsumerStatefulWidget {
  const UpdateGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    if (_checked) return;
    _checked = true;

    try {
      final update = await ref.read(updateRepositoryProvider).checkForUpdate();
      if (!mounted || update == null) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: !update.isMandatory,
        builder: (context) => _UpdateDialog(update: update),
      );
    } catch (_) {
      // Update checks must never block normal app startup.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _UpdateDialog extends ConsumerStatefulWidget {
  const _UpdateDialog({required this.update});

  final AppUpdate update;

  @override
  ConsumerState<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<_UpdateDialog> {
  bool _working = false;
  double? _progress;
  String? _message;

  Future<void> _updateNow() async {
    if (!Platform.isAndroid) {
      setState(() {
        _message =
            'A atualização automática para iPhone será feita pelo TestFlight ou App Store quando a distribuição iOS estiver configurada.';
      });
      return;
    }

    setState(() {
      _working = true;
      _progress = 0;
      _message = null;
    });

    try {
      final result = await ref
          .read(updateRepositoryProvider)
          .downloadAndInstallAndroid(
            widget.update,
            onProgress: (progress) {
              if (!mounted) return;
              setState(() => _progress = progress);
            },
          );

      if (!mounted) return;

      if (result == UpdateInstallResult.permissionRequired) {
        setState(() {
          _working = false;
          _message =
              'Autorize o SnapGym a instalar aplicativos nesta tela do Android. Depois volte ao app e toque novamente em “Atualizar agora”.';
        });
        return;
      }

      setState(() {
        _working = false;
        _message =
            'Download concluído. Confirme a instalação na tela do Android.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _message = 'Não foi possível atualizar agora: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final update = widget.update;
    final notes = update.releaseNotes?.trim();

    return PopScope(
      canPop: !update.isMandatory && !_working,
      child: AlertDialog(
        title: const Text('Atualização disponível'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'A versão ${update.versionName} do SnapGym está disponível.',
              ),
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: SgSpacing.md),
                Text(
                  'Novidades',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: SgSpacing.xs),
                Text(notes),
              ],
              if (_progress != null) ...[
                const SizedBox(height: SgSpacing.lg),
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: SgSpacing.xs),
                Text(
                  _working
                      ? 'Baixando ${((_progress ?? 0) * 100).round()}%'
                      : 'Download concluído',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: SgSpacing.md),
                Text(
                  _message!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: SgColors.moonstone),
                ),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          if (!update.isMandatory && !_working)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Depois'),
            ),
          FilledButton(
            onPressed: _working ? null : _updateNow,
            child: Text(_working ? 'Baixando...' : 'Atualizar agora'),
          ),
        ],
      ),
    );
  }
}
