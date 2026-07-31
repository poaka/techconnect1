import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../providers/technicians_providers.dart';
import '../widgets/category_item.dart';
import '../widgets/technician_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(technicianListNotifierProvider.notifier)
          .fetchTechnicians(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      ref.read(technicianFilterProvider.notifier).setQuery(query.trim());
      final filter = ref.read(technicianFilterProvider);
      ref
          .read(technicianListNotifierProvider.notifier)
          .fetchTechnicians(filter: filter, isRefresh: true);
      context.push('/directory');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final categoriesAsync = ref.watch(categoriesProvider);
    final technicianListState = ref.watch(technicianListNotifierProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 360 ? 14.0 : 18.0;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(categoriesProvider);
            await ref
                .read(technicianListNotifierProvider.notifier)
                .fetchTechnicians(isRefresh: true);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar (Greeting & Profile/Logout)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: 36,
                            height: 36,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user != null
                                      ? 'Bonjour, ${user.fullName} 👋'
                                      : 'Bonjour ! 👋',
                                  style: AppTypography.heading2.copyWith(
                                      fontSize: screenWidth < 360 ? 18 : 20),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'TechConnect Cameroun',
                                  style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: unreadCount > 0
                              ? Badge(
                                  label: Text('$unreadCount'),
                                  child: const Icon(Icons.notifications_outlined,
                                      color: AppColors.textSecondary),
                                )
                              : const Icon(Icons.notifications_outlined,
                                  color: AppColors.textSecondary),
                          onPressed: () => context.push('/notifications'),
                        ),

                        /*IconButton(
                          icon: const Icon(Icons.assignment_outlined, color: AppColors.textSecondary),
                          onPressed: () => context.push('/requests'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite_border_rounded, color: AppColors.textSecondary),
                          onPressed: () => context.push('/favorites'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                          onPressed: () => context.push('/profile'),
                        ),*/
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search Header Card
                Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quel artisan cherchez-vous ?',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Électricien, Plombier, Frigoriste...',
                        style: TextStyle(fontSize: 12.5, color: Colors.white70),
                      ),
                      const SizedBox(height: 12),

                      // Search Input Field
                      TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _onSearchSubmitted,
                        style: const TextStyle(fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un service ou nom...',
                          hintStyle: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                          fillColor: Colors.white,
                          filled: true,
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.textSecondary, size: 20),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.arrow_forward,
                                color: AppColors.primary, size: 20),
                            onPressed: () =>
                                _onSearchSubmitted(_searchController.text),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Categories Section Header (Responsive Row)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Métiers & Catégories',
                        style: AppTypography.heading3
                            .copyWith(fontSize: screenWidth < 360 ? 15 : 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.push('/categories');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Voir tout',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Categories Horizontal Scroll List
                SizedBox(
                  height: 96,
                  child: categoriesAsync.when(
                    data: (categories) => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        return CategoryItem(
                          category: cat,
                          onTap: () {
                            ref
                                .read(technicianFilterProvider.notifier)
                                .resetFilters();
                            ref
                                .read(technicianFilterProvider.notifier)
                                .setCategory(cat.id);
                            final filter = ref.read(technicianFilterProvider);
                            ref
                                .read(technicianListNotifierProvider.notifier)
                                .fetchTechnicians(
                                    filter: filter, isRefresh: true);
                            context.push('/directory');
                          },
                        );
                      },
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) =>
                        const Text('Impossible de charger les catégories'),
                  ),
                ),
                const SizedBox(height: 20),

                // Top Verified Technicians Section Header (Responsive Row)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Artisans recommandés',
                        style: AppTypography.heading3
                            .copyWith(fontSize: screenWidth < 360 ? 15 : 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/directory'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Tout explorer',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Featured Technicians List
                if (technicianListState.isLoading &&
                    technicianListState.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (technicianListState.items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                      'Aucun technicien disponible pour le moment.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: technicianListState.items.length > 5
                        ? 5
                        : technicianListState.items.length,
                    itemBuilder: (context, index) {
                      final profile = technicianListState.items[index];
                      return TechnicianCard(
                        profile: profile,
                        onTap: () => context.push('/technicians/${profile.id}'),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
