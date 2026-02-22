import 'package:cinematick/widgets/app_colors.dart';
import 'package:cinematick/widgets/custom_app_bar.dart';
import 'package:cinematick/providers/cinema_providers.dart';
import 'package:cinematick/providers/navigation_providers.dart';
import 'package:cinematick/views/cinema/cinema_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CinemaScreen extends ConsumerStatefulWidget {
  final Function(String, String, String)? onChainSelected;
  final String location;

  const CinemaScreen({super.key, this.onChainSelected, this.location = 'NSW'});

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
      return 3;
    } else {
      return 6;
    }
  }

  double _getChildAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) {
      return 0.95;
    } else if (screenWidth < 600) {
      return 0.90;
    } else if (screenWidth < 1000) {
      return 0.92;
    } else {
      return 0.95;
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

  String _getChainImage(String chainName) {
    final chainImageMap = {
      'event': 'lib/assets/event.svg',
      'hoyts': 'lib/assets/hoytsau.svg',
      'read': 'lib/assets/readingau.svg',
      'village': 'lib/assets/village.svg',
      'country': 'lib/assets/country.svg',
      'palace': 'lib/assets/palace.svg',
    };

    final lowerChainName = chainName.toLowerCase();

    if (chainImageMap.containsKey(lowerChainName)) {
      return chainImageMap[lowerChainName]!;
    }

    for (final entry in chainImageMap.entries) {
      if (lowerChainName.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'lib/assets/event.svg';
  }

  @override
  Widget build(BuildContext context) {
    final chainState = ref.watch(cinemaChainProvider);

    ref.listen(selectedRegionProvider, (previous, next) {
      if (previous != null && previous != next) {
        setState(() {
          cinemasByChain.clear();
        });
      }
    });

    for (final chain in chainState.filteredChains) {
      final chainId = chain['chain_id'] as String?;
      final chainName = chain['chain_name'] as String?;
      if (chainId != null &&
          chainName != null &&
          !cinemasByChain.containsKey(chainId)) {
        final locationState = ref.watch(
          cinemaLocationProvider((chainId, chainName)),
        );
        if (mounted && locationState.locations.isNotEmpty) {
          setState(() {
            cinemasByChain[chainId] = locationState.locations;
          });
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(0, 16, 3, 3),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => selectedChainId = null);
                                  },
                                  child: SizedBox(
                                    width: 75,
                                    height: 75,
                                    child: Container(
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
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                            width: 1,
                                          ),
                                          left: BorderSide(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                            width: 1,
                                          ),
                                          right: BorderSide(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                            width: 1,
                                          ),
                                          bottom: BorderSide(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: const Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.movie,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'All',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              ...List.generate(
                                chainState.filteredChains.length,
                                (index) {
                                  final chain =
                                      chainState.filteredChains[index];
                                  final chainName = chain['chain_name'] ?? '';
                                  final chainId = chain['chain_id'] ?? '';
                                  final isSelected = selectedChainId == chainId;

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(
                                          () => selectedChainId = chainId,
                                        );
                                      },
                                      child: SizedBox(
                                        width: 75,
                                        height: 75,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient:
                                                isSelected
                                                    ? const LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        Color(0xFF7B3FF2),
                                                        Color(0xFF5A1EA9),
                                                      ],
                                                    )
                                                    : null,
                                            color:
                                                !isSelected
                                                    ? Colors.white.withOpacity(
                                                      0.08,
                                                    )
                                                    : null,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border(
                                              top: BorderSide(
                                                color: Colors.white.withOpacity(
                                                  0.3,
                                                ),
                                                width: 1,
                                              ),
                                              left: BorderSide(
                                                color: Colors.white.withOpacity(
                                                  0.3,
                                                ),
                                                width: 1,
                                              ),
                                              right: BorderSide(
                                                color: Colors.white.withOpacity(
                                                  0.3,
                                                ),
                                                width: 1,
                                              ),
                                              bottom: BorderSide(
                                                color: Colors.white.withOpacity(
                                                  0.3,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                  width: 48,
                                                  height: 48,
                                                  child: SvgPicture.asset(
                                                    _getChainImage(chainName),
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  chainName,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

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
                          final cinemaLocations = cinemasByChain[chainId] ?? [];
                          final actualCinemaCount = cinemaLocations.length;

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  16,
                                  18,
                                  12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: SvgPicture.asset(
                                        _getChainImage(chainName),
                                        fit: BoxFit.contain,
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
                                          '$actualCinemaCount locations',
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
                              Container(
                                margin: const EdgeInsets.fromLTRB(
                                  18,
                                  0,
                                  18,
                                  16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(
                                    255,
                                    10,
                                    10,
                                    10,
                                  ).withOpacity(0.05),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.15),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: _getGridPadding(context),
                                    vertical: 12,
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
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 10,
                                          childAspectRatio:
                                              _getChildAspectRatio(context),
                                        ),
                                    itemCount: actualCinemaCount,
                                    itemBuilder: (context, index) {
                                      final cinema =
                                          cinemaLocations.isNotEmpty &&
                                                  index < cinemaLocations.length
                                              ? cinemaLocations[index]
                                              : null;

                                      final cinemaName =
                                          cinema != null
                                              ? (cinema['cinema_name']
                                                      as String?) ??
                                                  'Unknown'
                                              : 'Unknown';

                                      return _CinemaLocationCard(
                                        index: index,
                                        chainName: chainName,
                                        cinemaName: cinemaName,
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
                                                      cinemaCity: cinemaName,
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
                              ),
                            ],
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
      ),
    );
  }
}

class _CinemaLocationCard extends StatelessWidget {
  final int index;
  final String chainName;
  final String cinemaName;
  final Map<String, dynamic>? cinema;
  final VoidCallback onTap;
  final BuildContext context;

  const _CinemaLocationCard({
    required this.index,
    required this.chainName,
    required this.cinemaName,
    required this.onTap,
    required this.context,
    this.cinema,
  });

  String _getSvgPath(String chainName) {
    final chainImageMap = {
      'event': 'lib/assets/event.svg',
      'hoyts': 'lib/assets/hoytsau.svg',
      'read': 'lib/assets/readingau.svg',
      'village': 'lib/assets/village.svg',
      'country': 'lib/assets/country.svg',
      'palace': 'lib/assets/palace.svg',
    };

    final lowerChainName = chainName.toLowerCase();

    if (chainImageMap.containsKey(lowerChainName)) {
      return chainImageMap[lowerChainName]!;
    }

    for (final entry in chainImageMap.entries) {
      if (lowerChainName.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'lib/assets/event.svg';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth < 600 ? 6.0 : 8.0;
    final locationFontSize = screenWidth < 400 ? 10.0 : 11.0;
    final imageHeight = screenWidth < 400 ? 28.0 : 32.0;
    final spacingHeight = screenWidth < 400 ? 2.0 : 2.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: padding * 1.0,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF581C87).withOpacity(0.8),
                      const Color(0xFF3A0E68).withOpacity(0.9),
                    ],
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      height: imageHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SvgPicture.asset(
                        _getSvgPath(chainName),
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: spacingHeight),
                    Flexible(
                      child: Text(
                        cinemaName,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: locationFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
