import 'package:cinematick/config/secrets.dart';
import 'package:cinematick/widgets/app_colors.dart';
import 'package:cinematick/widgets/custom_app_bar.dart';
import 'package:cinematick/providers/cinema_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CinemaLocationsScreen extends ConsumerWidget {
  final String chainName;
  final String chainId;
  final String chainCount;
  final Function(String, String, String)? onLocationSelected;
  final VoidCallback? onBackPressed;

  const CinemaLocationsScreen({
    super.key,
    required this.chainName,
    required this.chainId,
    required this.chainCount,
    this.onLocationSelected,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(cinemaLocationProvider(chainId));

    return Scaffold(
      backgroundColor: const Color(0xFF2B1967),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: CustomAppBar()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: onBackPressed,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chainName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.dashboard_customize,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    chainCount,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _SearchField(chainId: chainId, ref: ref),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              if (locationState.isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (locationState.errorMessage != null)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Text(
                            locationState.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(
                                    cinemaLocationProvider(chainId).notifier,
                                  )
                                  .fetchLocations();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (locationState.filteredLocations.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 80),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off_outlined,
                            size: 64,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No cinemas found',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final location = locationState.filteredLocations[index];
                    final cinemaName = location['cinema_name'] ?? 'Unknown';
                    final cinemaAddress =
                        location['cinema_address'] ?? 'Unknown';
                    final cinemaId = location['cinema_id'] ?? '';
                    final cinemaCity = location['cinema_city'] ?? '';
                    final cinemaState = location['cinema_state'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          onLocationSelected?.call(
                            cinemaName,
                            cinemaAddress,
                            cinemaId,
                          );
                        },
                        child: _LocationCard(
                          cinemaName: cinemaName,
                          cinemaCity: cinemaCity,
                          cinemaState: cinemaState,
                          cinemaAddress: cinemaAddress,
                        ),
                      ),
                    );
                  }, childCount: locationState.filteredLocations.length),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends ConsumerWidget {
  final String chainId;
  final WidgetRef ref;

  const _SearchField({required this.chainId, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        onChanged: (query) {
          ref
              .read(cinemaLocationProvider(chainId).notifier)
              .searchLocations(query);
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search locations...',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(left: 16),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String cinemaName;
  final String cinemaCity;
  final String cinemaState;
  final String cinemaAddress;

  const _LocationCard({
    required this.cinemaName,
    required this.cinemaCity,
    required this.cinemaState,
    required this.cinemaAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cinemaName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white60,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$cinemaCity, $cinemaState',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
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
              const Icon(Icons.chevron_right, color: Colors.white60, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.home_outlined, color: Colors.white60, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  cinemaAddress,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
