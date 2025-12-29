import 'package:cinematick/widgets/app_colors.dart';
import 'package:flutter/material.dart';

class TheatreTile extends StatelessWidget {
  final Map<String, dynamic> theatre;
  final bool highlight;

  const TheatreTile({required this.theatre, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(255, 40, 15, 70).withOpacity(0.3),
            const Color.fromARGB(255, 30, 35, 120).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        theatre['name'],
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(
                          255,
                          74,
                          73,
                          73,
                        ).withOpacity(0.70),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.accentOrange,
                          width: 0.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, color: AppColors.goldStar, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            theatre['rating'],
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(
                          255,
                          23,
                          142,
                          239,
                        ).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.18),
                          width: 0.6,
                        ),
                      ),
                      child: Text(
                        theatre['distance'],
                        style: TextStyle(
                          color: const Color.fromARGB(255, 117, 195, 254),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: const Color.fromARGB(255, 209, 116, 246),
                      size: 20,
                    ),
                    SizedBox(width: 5),
                    Text(
                      theatre['address'],
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            color: Colors.white.withOpacity(0.1),
            height: 1,
            thickness: 0.8,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              child: Row(
                children:
                    (theatre['shows'] as List<dynamic>).map<Widget>((s) {
                      final isHighlight = s['highlight'] == true;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Container(
                          width: 90,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isHighlight
                                    ? const Color.fromARGB(
                                      255,
                                      100,
                                      60,
                                      160,
                                    ).withOpacity(0.7)
                                    : const Color.fromARGB(
                                      255,
                                      80,
                                      50,
                                      140,
                                    ).withOpacity(0.6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  isHighlight
                                      ? const Color.fromARGB(
                                        255,
                                        255,
                                        190,
                                        50,
                                      ).withOpacity(0.6)
                                      : Colors.white.withOpacity(0.12),
                              width: isHighlight ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Text(
                                    s['time'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      height: 1.0,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (isHighlight)
                                    Positioned(
                                      right: -10,
                                      top: -10,
                                      child: Icon(
                                        Icons.star,
                                        color: const Color.fromARGB(
                                          255,
                                          255,
                                          190,
                                          50,
                                        ),
                                        size: 22,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    s['format'] ?? '2D',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "\$${s['price']}",
                                    style: TextStyle(
                                      color:
                                          isHighlight
                                              ? const Color.fromARGB(
                                                255,
                                                255,
                                                190,
                                                50,
                                              )
                                              : Colors.white.withOpacity(0.9),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
