import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/report.dart';
import '../providers/admin_providers.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signalements'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'En attente'),
            Tab(text: 'Résolus'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ReportsList(status: 'pending'),
          _ReportsList(status: 'resolved'),
        ],
      ),
    );
  }
}

class _ReportsList extends ConsumerWidget {
  final String status;

  const _ReportsList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(adminReportsProvider(status));

    return reportsAsync.when(
      data: (reports) {
        if (reports.isEmpty) {
          return const Center(child: Text('Aucun signalement.'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminReportsProvider(status)),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final report = reports[index];
              return _ReportCard(report: report);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erreur: $err')),
    );
  }
}

class _ReportCard extends ConsumerWidget {
  final Report report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = DateFormat('dd MMM yyyy HH:mm').format(report.createdAt);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  report.status == 'pending' ? Icons.warning_amber_rounded : Icons.check_circle,
                  color: report.status == 'pending' ? Colors.orange : AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.reason,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Signalé par: ${report.client?.fullName ?? 'Inconnu'}'),
            Text('Technicien: ${report.technician?.fullName ?? 'Inconnu'}', 
                 style: const TextStyle(fontWeight: FontWeight.w600)),
            if (report.details != null && report.details!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Détails: ${report.details}'),
              ),
            ],
            if (report.status == 'resolved' && report.actionTaken != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Text('Action prise: ${report.actionTaken}', style: const TextStyle(color: AppColors.success)),
              ),
            ],
            if (report.status == 'pending') ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _showResolveDialog(context, ref, report),
                  icon: const Icon(Icons.gavel),
                  label: const Text('Prendre une décision'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showResolveDialog(BuildContext context, WidgetRef ref, Report report) {
    final actionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Résoudre le signalement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Quelle action avez-vous prise concernant ce technicien ? (ex: Avertissement envoyé, Compte suspendu, etc.)'),
              const SizedBox(height: 16),
              TextField(
                controller: actionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Action prise...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final action = actionController.text.trim();
                if (action.isEmpty) return;
                ref.read(reportActionsProvider.notifier).resolveReport(report.id, action);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Résoudre'),
            ),
          ],
        );
      },
    );
  }
}
