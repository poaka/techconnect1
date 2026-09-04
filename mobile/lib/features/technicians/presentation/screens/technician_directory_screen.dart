import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/technicians_providers.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/technician_card.dart';

class TechnicianDirectoryScreen extends ConsumerStatefulWidget {
  const TechnicianDirectoryScreen({super.key});

  @override
  ConsumerState<TechnicianDirectoryScreen> createState() => _TechnicianDirectoryScreenState();
}

class _TechnicianDirectoryScreenState extends ConsumerState<TechnicianDirectoryScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final filter = ref.read(technicianFilterProvider);
    _searchController.text = filter.q ?? '';

    _scrollController.addListener(_onScroll);

    // Initial fetch if list is empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final listState = ref.read(technicianListNotifierProvider);
      if (listState.items.isEmpty) {
        ref.read(technicianListNotifierProvider.notifier).fetchTechnicians(filter: filter, isRefresh: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(technicianListNotifierProvider.notifier).loadNextPage();
    }
  }

  void _onSearchChanged(String query) {
    ref.read(technicianFilterProvider.notifier).setQuery(query.trim().isEmpty ? null : query.trim());
    final newFilter = ref.read(technicianFilterProvider);
    ref.read(technicianListNotifierProvider.notifier).fetchTechnicians(filter: newFilter, isRefresh: true);
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(technicianFilterProvider);
    final technicianListState = ref.watch(technicianListNotifierProvider);
    final activeCount = filterState.activeFiltersCount;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 360 ? 12.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('directory_title_long')),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.filter_list_rounded),
                if (activeCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$activeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _openFilterBottomSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Search & Filter Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: context.tr('search_artisan_hint'),
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Compact Filter Button
                  OutlinedButton.icon(
                    onPressed: _openFilterBottomSheet,
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: Text(
                      activeCount > 0 ? '($activeCount)' : context.tr('filters'),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ),

            // Active Filters Chips Bar
            if (activeCount > 0)
              Container(
                height: 40,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Chip(
                      label: Text(context.tr('reset_all'), style: const TextStyle(fontSize: 12)),
                      onDeleted: () {
                        _searchController.clear();
                        ref.read(technicianFilterProvider.notifier).resetFilters();
                        final resetFilter = ref.read(technicianFilterProvider);
                        ref.read(technicianListNotifierProvider.notifier).fetchTechnicians(filter: resetFilter, isRefresh: true);
                      },
                      deleteIcon: const Icon(Icons.close, size: 14),
                    ),
                  ],
                ),
              ),

            // Technician List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(technicianListNotifierProvider.notifier).fetchTechnicians(isRefresh: true);
                },
                child: technicianListState.isLoading && technicianListState.items.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : technicianListState.errorMessage != null && technicianListState.items.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textSecondary),
                                  const SizedBox(height: 12),
                                  Text(
                                    technicianListState.errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodyMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      ref.read(technicianListNotifierProvider.notifier).fetchTechnicians(isRefresh: true);
                                    },
                                    child: Text(context.tr('retry')),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : technicianListState.items.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.search_off_rounded, size: 54, color: AppColors.textSecondary),
                                      const SizedBox(height: 12),
                                      Text(
                                        context.tr('no_artisan_found'),
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        context.tr('try_changing_filters'),
                                        textAlign: TextAlign.center,
                                        style: AppTypography.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12.0),
                                itemCount: technicianListState.items.length + (technicianListState.hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == technicianListState.items.length) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16.0),
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  }

                                  final profile = technicianListState.items[index];
                                  return TechnicianCard(
                                    profile: profile,
                                    onTap: () => context.push('/technicians/${profile.id}'),
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
