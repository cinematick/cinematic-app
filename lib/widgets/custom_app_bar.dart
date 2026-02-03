import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinematick/providers/navigation_providers.dart';

import 'app_colors.dart';

class CustomAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  final VoidCallback? onLocationTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onCloseTap;

  const CustomAppBar({
    super.key,
    this.onLocationTap,
    this.onSearchTap,
    this.onCloseTap,
  });

  @override
  ConsumerState<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends ConsumerState<CustomAppBar> {
  final Map<String, String> _regionMap = {
    'NSW': 'New South Wales',
    'VIC': 'Victoria',
    'QLD': 'Queensland',
    'TAS': 'Tasmania',
    'SA': 'South Australia',
    'NT': 'Northern Territory',
    'WA': 'Western Australia',
    'ACT': 'Australian Capital Territory',
  };

  final List<String> _lockedRegions = [];
  final List<String> _regionKeys = [
    'NSW',
    'QLD',
    'VIC',
    'SA',
    'WA',
    'TAS',
    'ACT',
    'NT',
  ];

  @override
  void initState() {
    super.initState();
    _loadLocationFromCache();
  }

  Future<void> _loadLocationFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedLocation = prefs.getString('selected_region') ?? 'NSW';
      // Update the Riverpod state
      ref.read(selectedRegionProvider.notifier).state = cachedLocation;
    } catch (e) {
      print('Error loading location from cache: $e');
    }
  }

  Future<void> _saveRegionToCache(String region) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_region', region);
      ref.read(selectedRegionProvider.notifier).state = region;
    } catch (e) {
      print('Error saving region to cache: $e');
    }
  }

  void _showRegionSelector(BuildContext context) {
    final currentRegion = ref.read(selectedRegionProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Change Region',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Select a region or detect automatically.',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, color: Colors.white70, size: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    // TODO: Implement auto-detect location
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 238, 142, 39),
                          Color.fromARGB(255, 255, 165, 0),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.location_on, color: Colors.black, size: 12),
                        SizedBox(width: 8),
                        Text(
                          'Detect My Location',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children:
                      _regionKeys.map((regionKey) {
                        final isSelected = regionKey == currentRegion;
                        final isLocked = _lockedRegions.contains(regionKey);
                        final regionName = _regionMap[regionKey] ?? regionKey;

                        return GestureDetector(
                          onTap:
                              isLocked
                                  ? null
                                  : () {
                                    _saveRegionToCache(regionKey);
                                    Navigator.pop(context);
                                  },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border:
                                  isSelected
                                      ? Border.all(
                                        color: const Color.fromARGB(
                                          255,
                                          238,
                                          142,
                                          39,
                                        ),
                                        width: 1.5,
                                      )
                                      : Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1,
                                      ),
                              color:
                                  isLocked
                                      ? Colors.white.withOpacity(0.05)
                                      : const Color.fromARGB(141, 59, 69, 88),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    regionName,
                                    style: TextStyle(
                                      color:
                                          isLocked
                                              ? Colors.white24
                                              : Colors.white,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isLocked)
                                  Positioned(
                                    right: 4,
                                    bottom: 4,
                                    child: Icon(
                                      Icons.lock,
                                      color: Colors.white.withOpacity(0.3),
                                      size: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(selectedRegionProvider);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          ShaderMask(
            shaderCallback:
                (bounds) => AppColors.appBarTitleGradient.createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                ),
            child: const Text(
              'Cinema',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
          ShaderMask(
            shaderCallback:
                (bounds) => AppColors.appBarTickGradient.createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                ),
            child: const Text(
              'Tick',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          if (widget.onCloseTap != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onCloseTap,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.close,
                    color: const Color.fromARGB(255, 238, 142, 39),
                    size: 24,
                  ),
                ),
              ),
            )
          else if (widget.onSearchTap != null)
            GestureDetector(
              onTap: widget.onSearchTap,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color.fromARGB(
                    255,
                    238,
                    142,
                    39,
                  ).withOpacity(0.2),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.search,
                  color: const Color.fromARGB(255, 238, 142, 39),
                  size: 20,
                ),
              ),
            ),
          SizedBox(width: 10),
          GestureDetector(
            onTap: () => _showRegionSelector(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white30, width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: const Color.fromARGB(255, 238, 142, 39),
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    location,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      centerTitle: false,
    );
  }
}
