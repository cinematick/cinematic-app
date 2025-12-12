import 'package:cinematick/config/secrets.dart';
import 'package:cinematick/widgets/app_colors.dart';
import 'package:cinematick/widgets/custom_app_bar.dart';
import 'package:cinematick/providers/cinema_providers.dart';
import 'package:cinematick/providers/navigation_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CinemaScreen extends ConsumerWidget {
  final Function(String, String, String)? onChainSelected;

  const CinemaScreen({super.key, this.onChainSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chainState = ref.watch(cinemaChainProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF2B1967),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: CustomAppBar()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback:
                            (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFFFFFFFF),
                                Color.fromARGB(255, 188, 165, 253),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                        child: const Text(
                          'Cinema Chains',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SearchField(ref: ref),
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
              else if (chainState.filteredChains.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 80),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.movie_filter_outlined,
                            size: 64,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No cinema chains found',
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
                    final chain = chainState.filteredChains[index];
                    final chainName = chain['chain_name'] ?? 'Unknown';
                    final chainId = chain['chain_id'] ?? '';
                    final cinemaCount = chain['cinemaCount'] ?? 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          onChainSelected?.call(
                            chainName,
                            chainId,
                            '$cinemaCount Cinemas',
                          );
                        },
                        child: _ChainCard(
                          chainName: chainName,
                          cinemaCount: cinemaCount,
                          index: index,
                        ),
                      ),
                    );
                  }, childCount: chainState.filteredChains.length),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends ConsumerWidget {
  final WidgetRef ref;

  const _SearchField({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        onChanged: (query) {
          ref.read(cinemaChainProvider.notifier).searchChains(query);
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search cinema chains...',
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

class _ChainCard extends StatelessWidget {
  final String chainName;
  final int cinemaCount;
  final int index;

  const _ChainCard({
    required this.chainName,
    required this.cinemaCount,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              'https://picsum.photos/400/250?random=${index + 1}',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black26,
                  child: const Icon(
                    Icons.image,
                    color: Colors.white24,
                    size: 60,
                  ),
                );
              },
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF4A2F6B).withOpacity(0.7),
                    const Color(0xFF6B3FA0).withOpacity(0.95),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentOrange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'MAJOR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chainName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.dashboard_customize,
                        color: Colors.white60,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$cinemaCount Cinemas',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white60,
                        size: 14,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
