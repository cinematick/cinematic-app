import 'package:cinematick/config/secrets.dart';
import 'package:cinematick/widgets/app_colors.dart';
import 'package:cinematick/widgets/custom_app_bar.dart';
import 'package:cinematick/providers/cinema_providers.dart';
import 'package:cinematick/providers/navigation_providers.dart';
import 'package:cinematick/views/cinema/cinema_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CinemaScreen extends ConsumerStatefulWidget {
  final Function(String, String, String)? onChainSelected;

  const CinemaScreen({super.key, this.onChainSelected});

  @override
  ConsumerState<CinemaScreen> createState() => _CinemaScreenState();
}

class _CinemaScreenState extends ConsumerState<CinemaScreen> {
  String? selectedChainId;
  bool isGridView = true;
  Map<String, List<Map<String, dynamic>>> cinemasByChain = {};

  int _getGridColumnCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) {
      return 3; 
    } else if (screenWidth < 600) {
      return 3; 
    } else if (screenWidth < 1000) {
      return 4; 
    } else {
      return 6; 
    }
  }

  double _getChildAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) {
      return 1.2;
    } else if (screenWidth < 600) {
      return 1.08; 
    } else if (screenWidth < 1000) {
      return 1.12; 
    } else {
      return 1.15; 
    }
  }

  double _getGridPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 12; 
    } else {
      return 18; 
    }
  }

  double _getCardPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 12; 
    } else {
      return 16; 
    }
  }

  @override
  Widget build(BuildContext context) {
    final chainState = ref.watch(cinemaChainProvider);

    for (final chain in chainState.filteredChains) {
      final chainId = chain['chain_id'] as String?;
      if (chainId != null && !cinemasByChain.containsKey(chainId)) {
        final locationState = ref.watch(cinemaLocationProvider(chainId));
        if (mounted && locationState.locations.isNotEmpty) {
          setState(() {
            cinemasByChain[chainId] = locationState.locations;
          });
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF2B1967),
      resizeToAvoidBottomInset: false,
      body: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: CustomAppBar()),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(18, 16, 18, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CinemaTick',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: Colors.white70,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Sydney',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (chainState.isLoading)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else if (chainState.errorMessage != null)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Text(
                              chainState.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                ref
                                    .read(cinemaChainProvider.notifier)
                                    .fetchCinemaChains();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => selectedChainId = null);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient:
                                        selectedChainId == null
                                            ? const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFF7B3FF2),
                                                Color(0xFF5A1EA9),
                                              ],
                                            )
                                            : null,
                                    color:
                                        selectedChainId != null
                                            ? Colors.white.withOpacity(0.08)
                                            : null,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                      left: BorderSide(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                      right: BorderSide(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                      bottom: BorderSide(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'All',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ...List.generate(chainState.filteredChains.length, (
                              index,
                            ) {
                              final chain = chainState.filteredChains[index];
                              final chainName = chain['chain_name'] ?? '';
                              final chainId = chain['chain_id'] ?? '';
                              final isSelected = selectedChainId == chainId;

                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => selectedChainId = chainId);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient:
                                          isSelected
                                              ? const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Color(0xFF7B3FF2),
                                                  Color(0xFF5A1EA9),
                                                ],
                                              )
                                              : null,
                                      color:
                                          !isSelected
                                              ? Colors.white.withOpacity(0.08)
                                              : null,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border(
                                        top: BorderSide(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                        left: BorderSide(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                        right: BorderSide(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                        bottom: BorderSide(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      chainName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => isGridView = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isGridView
                                          ? AppColors.selectedChipPurple
                                          : Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.grid_view,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Grid',
                                      style: TextStyle(
                                        color:
                                            isGridView
                                                ? Colors.white
                                                : Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => setState(() => isGridView = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      !isGridView
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.map_outlined,
                                      color:
                                          !isGridView
                                              ? Colors.black
                                              : Colors.white70,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Map',
                                      style: TextStyle(
                                        color:
                                            !isGridView
                                                ? Colors.black
                                                : Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (isGridView)
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        ...List.generate(
                          selectedChainId == null
                              ? chainState.filteredChains.length
                              : 1,
                          (chainIndex) {
                            final chain =
                                selectedChainId == null
                                    ? chainState.filteredChains[chainIndex]
                                    : chainState.filteredChains.firstWhere(
                                      (c) => c['chain_id'] == selectedChainId,
                                      orElse: () => {},
                                    );

                            if (chain.isEmpty) return const SizedBox.shrink();

                            final chainName = chain['chain_name'] ?? 'Cinema';
                            final chainId = chain['chain_id'] ?? '';
                            final cinemaCount = chain['cinemaCount'] ?? 12;

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    20,
                                    18,
                                    16,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.movie_creation_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            chainName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$cinemaCount locations',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.6,
                                              ),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: _getGridPadding(context),
                                  ),
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: _getGridColumnCount(
                                            context,
                                          ),
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 2,
                                          childAspectRatio:
                                              _getChildAspectRatio(context),
                                        ),
                                    itemCount:
                                        cinemasByChain[chainId]?.length ??
                                        cinemaCount,
                                    itemBuilder: (context, index) {
                                      final cinemaLocations =
                                          cinemasByChain[chainId] ?? [];
                                      final cinema =
                                          cinemaLocations.isNotEmpty &&
                                                  index < cinemaLocations.length
                                              ? cinemaLocations[index]
                                              : null;
                                      final cinemaCity =
                                          cinema != null
                                              ? (cinema['cinema_city'] ??
                                                  'Unknown')
                                              : 'Unknown';

                                      return _CinemaLocationCard(
                                        index: index,
                                        chainName: chainName,
                                        cinemaCity: cinemaCity,
                                        cinema: cinema,
                                        context: context,
                                        onTap: () {
                                          if (cinema != null) {
                                            final cinemaId =
                                                cinema['cinema_id'] as String?;
                                            final screenCounts = [
                                              16,
                                              18,
                                              14,
                                              12,
                                              18,
                                              9,
                                              16,
                                              11,
                                              8,
                                              8,
                                              9,
                                              8,
                                            ];
                                            final screenCount =
                                                screenCounts[index %
                                                    screenCounts.length];
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder:
                                                    (
                                                      context,
                                                    ) => CinemaDetailScreen(
                                                      tmdbId: '86512',
                                                      cinema: cinema,
                                                      cinemaCity: cinemaCity,
                                                      chainName: chainName,
                                                      cinemaId: cinemaId,
                                                      screenCount: screenCount,
                                                    ),
                                              ),
                                            );
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 400,
                      child: Center(
                        child: Text(
                          'Map View',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CinemaLocationCard extends StatelessWidget {
  final int index;
  final String chainName;
  final String cinemaCity;
  final Map<String, dynamic>? cinema;
  final VoidCallback onTap;
  final BuildContext context;

  const _CinemaLocationCard({
    required this.index,
    required this.chainName,
    required this.cinemaCity,
    required this.onTap,
    required this.context,
    this.cinema,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth < 600 ? 12.0 : 16.0;
    final badgeFontSize = screenWidth < 400 ? 8.0 : 9.0;
    final locationFontSize = screenWidth < 400 ? 9.0 : 10.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF5A1EA9).withOpacity(0.8),
                    const Color(0xFF3A0E68).withOpacity(0.9),
                  ],
                ),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      chainName.length > 8
                          ? chainName.substring(0, 8)
                          : chainName.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: badgeFontSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  SizedBox(height: screenWidth < 400 ? 10 : 14),
                  Text(
                    cinemaCity,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: locationFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
