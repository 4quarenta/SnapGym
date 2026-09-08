import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/theme/sg_colors.dart';
import '../../../core/theme/sg_radius.dart';
import '../../../core/theme/sg_spacing.dart';
import '../../../core/ui/sg_brand.dart';
import '../../../core/ui/sg_primary_button.dart';
import '../../feed/data/feed_repository.dart';
import '../data/checkin_repository.dart';
import '../domain/checkin_validation.dart';
import '../domain/workout_type.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  final _picker = ImagePicker();
  final _durationController = TextEditingController(text: '45');
  final _noteController = TextEditingController();

  WorkoutType _workoutType = WorkoutType.musculacao;
  XFile? _photo;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _durationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    setState(() => _error = null);
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 82,
        maxWidth: 1600,
        maxHeight: 1600,
        requestFullMetadata: false,
      );
      if (photo != null && mounted) {
        setState(() => _photo = photo);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível abrir a câmera. Verifique a permissão do app.';
        });
      }
    }
  }

  Future<void> _publish() async {
    final durationError = CheckinValidation.duration(_durationController.text);
    final noteError = CheckinValidation.note(_noteController.text);
    if (_photo == null) {
      setState(() => _error = 'A foto do treino é obrigatória.');
      return;
    }
    if (durationError != null || noteError != null) {
      setState(() => _error = durationError ?? noteError);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(checkinRepositoryProvider).createCheckin(
            sourceImagePath: _photo!.path,
            workoutType: _workoutType,
            durationMinutes: int.parse(_durationController.text.trim()),
            note: _noteController.text,
          );
      ref.invalidate(feedCheckinsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in publicado.')),
      );
      context.go('/feed');
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Falha ao publicar o check-in: $error');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(SgSpacing.lg),
        children: <Widget>[
          const SgBrand(fontSize: 28),
          const SizedBox(height: SgSpacing.xl),
          Text(
            'Registrar treino',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: SgSpacing.xs),
          Text(
            'Todo check-in precisa de uma foto tirada agora.',
            style: textTheme.bodyLarge?.copyWith(
              color: SgColors.darkTextSecondary,
            ),
          ),
          const SizedBox(height: SgSpacing.lg),
          _PhotoCapture(photo: _photo, onTakePhoto: _takePhoto),
          const SizedBox(height: SgSpacing.lg),
          DropdownButtonFormField<WorkoutType>(
            value: _workoutType,
            decoration: const InputDecoration(labelText: 'Tipo de treino'),
            items: WorkoutType.values
                .map(
                  (type) => DropdownMenuItem<WorkoutType>(
                    value: type,
                    child: Text(type.label),
                  ),
                )
                .toList(),
            onChanged: _submitting
                ? null
                : (value) {
                    if (value != null) setState(() => _workoutType = value);
                  },
          ),
          const SizedBox(height: SgSpacing.md),
          TextField(
            controller: _durationController,
            enabled: !_submitting,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Duração',
              suffixText: 'min',
            ),
          ),
          const SizedBox(height: SgSpacing.md),
          TextField(
            controller: _noteController,
            enabled: !_submitting,
            maxLength: 280,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Observação (opcional)',
              hintText: 'Ex.: treino de pernas, corrida leve...',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: SgSpacing.sm),
            Text(
              _error!,
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: SgSpacing.md),
          SgPrimaryButton(
            label: _submitting ? 'Publicando...' : 'Concluir check-in',
            icon: _submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const PhosphorIcon(PhosphorIconsBold.check),
            onPressed: _submitting ? null : _publish,
          ),
        ],
      ),
    );
  }
}

class _PhotoCapture extends StatelessWidget {
  const _PhotoCapture({required this.photo, required this.onTakePhoto});

  final XFile? photo;
  final VoidCallback onTakePhoto;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SgRadius.lg),
        child: Material(
          color: SgColors.darkSurfaceElevated,
          child: InkWell(
            onTap: onTakePhoto,
            child: photo == null
                ? const _EmptyPhoto()
                : Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Image.file(File(photo!.path), fit: BoxFit.cover),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(SgSpacing.md),
                          color: Colors.black.withValues(alpha: 0.55),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              PhosphorIcon(PhosphorIconsBold.cameraRotate),
                              SizedBox(width: SgSpacing.xs),
                              Text('Tocar para refazer a foto'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPhoto extends StatelessWidget {
  const _EmptyPhoto();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SgSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const PhosphorIcon(
              PhosphorIconsBold.camera,
              size: 52,
              color: SgColors.orange,
            ),
            const SizedBox(height: SgSpacing.md),
            Text(
              'Tirar foto do treino',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: SgSpacing.xs),
            Text(
              'A galeria não é usada nesta fase: a evidência deve ser capturada no momento do check-in.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: SgColors.darkTextSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
