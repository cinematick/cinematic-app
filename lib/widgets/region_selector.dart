import 'package:flutter/material.dart';

class RegionSelector extends StatelessWidget {
  final String selectedRegion;
  final Function(String) onRegionSelected;

  const RegionSelector({
    super.key,
    required this.selectedRegion,
    required this.onRegionSelected,
  });

  static const List<String> regions = [
    'New South Wales',
    'Queensland',
    'Victoria',
    'South Australia',
    'Tasmania',
    'Western Australia',
    'Australian Capital Territory',
    'Northern Territory',
  ];

  static const Map<String, String> regionAbbreviations = {
    'New South Wales': 'NSW',
    'Queensland': 'QLD',
    'Victoria': 'VIC',
    'South Australia': 'SA',
    'Tasmania': 'TAS',
    'Western Australia': 'WA',
    'Australian Capital Territory': 'ACT',
    'Northern Territory': 'NT',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Region',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a region or detect automatically.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement location detection
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_searching, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Detect My Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: regions.length,
              itemBuilder: (context, index) {
                final region = regions[index];
                final isSelected =
                    regionAbbreviations[region] == selectedRegion;

                return GestureDetector(
                  onTap: () {
                    onRegionSelected(regionAbbreviations[region] ?? region);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFFFF6B35)
                                : Colors.white24,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      color:
                          isSelected
                              ? const Color(0xFFFF6B35).withOpacity(0.1)
                              : Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        region,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              isSelected
                                  ? const Color(0xFFFF6B35)
                                  : Colors.white,
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
