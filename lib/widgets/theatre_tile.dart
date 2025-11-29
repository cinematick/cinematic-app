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
                      return Padding(
                        padding: const EdgeInsets.only(right: 11),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                s['highlight'] == true
                                    ? const Color.fromARGB(
                                      255,
                                      23,
                                      142,
                                      239,
                                    ).withOpacity(0.25)
                                    : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border:
                                s['highlight'] == true
                                    ? Border.all(
                                      color: const Color.fromARGB(
                                        255,
                                        23,
                                        142,
                                        239,
                                      ).withOpacity(0.6),
                                      width: 1.8,
                                    )
                                    : null,
                          ),
                          child: Column(
                            children: [
                              Text(
                                s['time'] as String,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                "\$${s['price']}",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
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
