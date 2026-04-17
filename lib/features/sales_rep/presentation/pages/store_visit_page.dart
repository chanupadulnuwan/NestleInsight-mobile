import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sales_rep/data/services/visit_service.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/visit_cubit.dart';

class StoreVisitPage extends StatefulWidget {
  const StoreVisitPage({
    super.key,
    required this.routeId,
    this.territoryId = '00000000-0000-0000-0000-000000000001',
  });

  final String routeId;
  final String territoryId;

  @override
  State<StoreVisitPage> createState() => _StoreVisitPageState();
}

class _StoreVisitPageState extends State<StoreVisitPage> {
  late VisitCubit _visitCubit;
  final _shopNameController = TextEditingController();
  final _osaNotesController = TextEditingController();
  final _feedbackController = TextEditingController();

  bool _planogramOk = false;
  bool _posmOk = false;
  final List<String> _localPhotoPaths = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _visitCubit = context.read<VisitCubit>();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _osaNotesController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _startVisit() {
    if (_shopNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter shop name')));
      return;
    }

    // Mock GPS coordinates
    const mockLatitude = 6.5244;
    const mockLongitude = 3.3792;

    _visitCubit.startVisit(
      routeId: widget.routeId,
      shopName: _shopNameController.text,
      latitude: mockLatitude,
      longitude: mockLongitude,
      territoryId: widget.territoryId,
    );
  }

  void _completeVisit(StoreVisit visit) {
    _visitCubit.completeVisit(
      visitId: visit.id,
      shelfStock: null,
      backroomStock: null,
      osaIssues: _osaNotesController.text.isNotEmpty
          ? {'notes': _osaNotesController.text}
          : null,
      promotions: null,
      planogramOk: _planogramOk,
      posmOk: _posmOk,
      feedback: _feedbackController.text.isNotEmpty
          ? _feedbackController.text
          : null,
    );
  }

  Future<void> _capturePhoto(String visitId) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, 
      );

      if (photo != null) {
        setState(() {
          _localPhotoPaths.add(photo.path);
        });

        _visitCubit.uploadPhoto(
          visitId: visitId,
          filePath: photo.path,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWarm,
      appBar: AppBar(title: const Text('Store Visit')),
      body: BlocListener<VisitCubit, VisitState>(
        listener: (context, state) {
          if (state is VisitError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is VisitCompleted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            Navigator.of(context).pop();
          }
        },
        child: BlocBuilder<VisitCubit, VisitState>(
          builder: (context, state) {
            final isLoading = state is VisitLoading;

            if (state is VisitInProgress) {
              return _InProgressView(
                visit: state.visit,
                isLoading: isLoading,
                osaNotesController: _osaNotesController,
                feedbackController: _feedbackController,
                planogramOk: _planogramOk,
                posmOk: _posmOk,
                onPlanogramChanged: (value) {
                  setState(() => _planogramOk = value ?? false);
                },
                onPosmChanged: (value) {
                  setState(() => _posmOk = value ?? false);
                },
                localPhotoPaths: _localPhotoPaths,
                onCapturePhoto: () => _capturePhoto(state.visit.id),
                onComplete: () => _completeVisit(state.visit),
              );
            }

            return _StartPhaseView(
              isLoading: isLoading,
              shopNameController: _shopNameController,
              onStartVisit: _startVisit,
            );
          },
        ),
      ),
    );
  }
}

class _StartPhaseView extends StatelessWidget {
  const _StartPhaseView({
    required this.isLoading,
    required this.shopNameController,
    required this.onStartVisit,
  });

  final bool isLoading;
  final TextEditingController shopNameController;
  final VoidCallback onStartVisit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Check-In to Store',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: shopNameController,
            enabled: !isLoading,
            decoration: InputDecoration(
              labelText: 'Shop Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onStartVisit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBrown,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Check-In',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InProgressView extends StatelessWidget {
  const _InProgressView({
    required this.visit,
    required this.isLoading,
    required this.osaNotesController,
    required this.feedbackController,
    required this.planogramOk,
    required this.posmOk,
    required this.onPlanogramChanged,
    required this.onPosmChanged,
    required this.localPhotoPaths,
    required this.onCapturePhoto,
    required this.onComplete,
  });

  final StoreVisit visit;
  final bool isLoading;
  final TextEditingController osaNotesController;
  final TextEditingController feedbackController;
  final bool planogramOk;
  final bool posmOk;
  final Function(bool?) onPlanogramChanged;
  final Function(bool?) onPosmChanged;
  final List<String> localPhotoPaths;
  final VoidCallback onCapturePhoto;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VisitInfoCard(visit: visit),
          const SizedBox(height: 24),
          _SectionTitle(title: 'OSA Check'),
          const SizedBox(height: 12),
          TextField(
            controller: osaNotesController,
            enabled: !isLoading,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter any OSA issues or notes',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'Merchandising'),
          const SizedBox(height: 12),
          _CheckboxTile(
            label: 'Planogram OK',
            value: planogramOk,
            onChanged: onPlanogramChanged,
            enabled: !isLoading,
          ),
          const SizedBox(height: 12),
          _CheckboxTile(
            label: 'POSM OK',
            value: posmOk,
            onChanged: onPosmChanged,
            enabled: !isLoading,
          ),
          _SectionTitle(title: 'Display Evidence'),
          const SizedBox(height: 12),
          _PhotoCaptureSection(
            localPhotoPaths: localPhotoPaths,
            onCapture: onCapturePhoto,
            enabled: !isLoading,
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'Feedback'),
          const SizedBox(height: 12),
          TextField(
            controller: feedbackController,
            enabled: !isLoading,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter store feedback',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.proceedOrderOlive,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Complete Visit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitInfoCard extends StatelessWidget {
  const _VisitInfoCard({required this.visit});

  final StoreVisit visit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              visit.shopNameSnapshot,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${visit.status}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(color: AppTheme.primaryBrown),
    );
  }
}

class _CheckboxTile extends StatelessWidget {
  const _CheckboxTile({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final bool value;
  final Function(bool?) onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.outlineWarm),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        title: Text(label),
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

class _PhotoCaptureSection extends StatelessWidget {
  const _PhotoCaptureSection({
    required this.localPhotoPaths,
    required this.onCapture,
    this.enabled = true,
  });

  final List<String> localPhotoPaths;
  final VoidCallback onCapture;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (localPhotoPaths.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: localPhotoPaths.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.outlineWarm),
                  ),
                  child: const Center(
                    child: Icon(Icons.image, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: enabled ? onCapture : null,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Capture Shelf Photo'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
