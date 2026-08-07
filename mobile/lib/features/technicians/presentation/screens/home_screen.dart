import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/language_selector.dart';
import '../../../../shared/widgets/theme_toggle_button.dart';
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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          await ref
              .read(technicianListNotifierProvider.notifier)
              .fetchTechnicians(isRefresh: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------
              // HERO HEADER WITH BRAND GRADIENT
              // ----------------------------------------------------
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: horizontalPadding,
                  right: horizontalPadding,
                  bottom: 30,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user != null
                                      ? '${context.tr('hello_user')}${user.fullName} 👋'
                                      : context.tr('hello_default'),
                                  style: AppTypography.heading2.copyWith(
                                      color: Colors.white,
                                      fontSize: screenWidth < 360 ? 18 : 20),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.tr('app_title'),
                                  style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const ThemeToggleButton(),
                            const LanguageSelector(),
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                                  onPressed: () => context.push('/notifications'),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 10,
                                    top: 10,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        unreadCount > 9 ? '9+' : unreadCount.toString(),
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
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // SEARCH BAR INSIDE HEADER
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _onSearchSubmitted,
                        decoration: InputDecoration(
                          hintText: context.tr('search_placeholder'),
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.tune, color: AppColors.primary),
                            onPressed: () => context.push('/directory'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // END HERO HEADER
              
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                // Categories Section Header (Responsive Row)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('categories_header'),
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
                      child: Text(context.tr('see_all'),
                          style: const TextStyle(fontSize: 13)),
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
                        const Text('Error loading categories'),
                  ),
                ),
                const SizedBox(height: 20),

                // Top Verified Technicians Section Header (Responsive Row)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('recommended_artisans'),
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
                      child: Text(context.tr('explore_all'),
                          style: const TextStyle(fontSize: 13)),
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
                    child: Text(
                      context.tr('no_technician_found'),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: technicianListState.items.length,
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
        ],
      ),
    ),
  ),
);
  }
}
