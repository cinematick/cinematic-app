import 'package:cinematick/widgets/app_colors.dart';
import 'package:cinematick/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';

class TickScreen extends StatefulWidget {
  const TickScreen({super.key});
  @override
  State<TickScreen> createState() => _TickScreenState();
}

class _TickScreenState extends State<TickScreen> {
  int _selectedTab = 0;

  final List<Map<String, dynamic>> hotMovies = [
    {
      'title': 'Dune: Part Two',
      'sold': '62% sold',
      'status': 'Heating up',
      'poster': 'https://picsum.photos/200/300?random=1',
    },
    {
      'title': 'Inside Out 2',
      'sold': '71% sold',
      'status': 'On Fire',
      'poster': 'https://picsum.photos/200/300?random=2',
    },
    {
      'title': 'Furiosa: A Mad Max Saga',
      'sold': '55% sold',
      'status': 'Rising',
      'poster': 'https://picsum.photos/200/300?random=3',
    },
  ];

  final sessions = [
    {
      'poster': 'https://picsum.photos/seed/dune/60/90',
      'titleMain': 'Dune:\n',
      'titleRest': 'Part Two',
      'cinema': 'Cineplex\nGrand Central',
      'startsHours': '3h',
      'startsMinutes': '59m',
      'seatsLeft': 7,
      'capacity': '92%',
    },
    {
      'poster': 'https://picsum.photos/seed/dune/60/90',
      'titleMain': 'Dune:\n',
      'titleRest': 'Part Two',
      'cinema': 'Cineplex\nGrand Central',
      'startsHours': '3h',
      'startsMinutes': '59m',
      'seatsLeft': 7,
      'capacity': '92%',
    },
    {
      'poster': 'https://picsum.photos/seed/dune/60/90',
      'titleMain': 'Dune:\n',
      'titleRest': 'Part Two',
      'cinema': 'Cineplex\nGrand Central',
      'startsHours': '3h',
      'startsMinutes': '59m',
      'seatsLeft': 7,
      'capacity': '92%',
    },
  ];

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback:
                            (bounds) => LinearGradient(
                              colors: [
                                Color.fromARGB(255, 191, 170, 251),
                                Color.fromARGB(255, 133, 205, 244),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                        child: const Text(
                          'Cinema Pulse',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Real-time cinema intelligence & hot deals',
                        style: TextStyle(
                          color: AppColors.searchHint,
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          const Text('🔥 ', style: TextStyle(fontSize: 18)),
                          const Text(
                            'Hot Right Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    itemCount: hotMovies.length,
                    itemBuilder: (context, index) {
                      final movie = hotMovies[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 18),
                        child: buildHotReleaseCard(movie),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 48)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('⚡ ', style: TextStyle(fontSize: 20)),
                          const Text(
                            'Live Pulse & Capacity',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.9,
                        children: [
                          _buildMetricCard('⏱️', '20', 'Tickets/min'),
                          _buildMetricCard('👥', '67%', 'Avg seat fill'),
                          _buildMetricCard('\$', '\$15.55', 'Median price'),
                          _buildMetricCard(
                            '📍',
                            '30',
                            'Active\ncinemas',
                            'Peak!',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
              SliverToBoxAdapter(child: buildActivityTimeline()),
              SliverToBoxAdapter(child: const SizedBox(height: 10)),
              SliverToBoxAdapter(child: buildDontMissOutSection(sessions)),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
              SliverToBoxAdapter(child: buildPriceWatchSection()),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String icon,
    String value,
    String label, [
    String? tag,
  ]) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
          if (tag != null)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Color(0xFFFFB366),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildHotReleaseCard(Map<String, dynamic> movie) {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  movie['poster'],
                  width: 90,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: 90,
                        height: 135,
                        color: Colors.black26,
                        child: const Icon(Icons.movie, color: Colors.white24),
                      ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5F5E).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            movie['sold'],
                            style: const TextStyle(
                              color: Color(0xFFFFB366),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5F5E).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥 ', style: TextStyle(fontSize: 12)),
                              Text(
                                movie['status'],
                                style: const TextStyle(
                                  color: Color(0xFFFFB366),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: CustomPaint(painter: MiniChartPainter()),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9D5FFF), Color(0xFFC857FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'View Sessions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildActivityTimeline() {
    return Container(
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Activity Timeline",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _selectedTab == 0
                                ? Colors.black.withOpacity(0.7)
                                : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Movies",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color:
                              _selectedTab == 0 ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _selectedTab == 1
                                ? Colors.black.withOpacity(0.7)
                                : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Cinemas",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color:
                              _selectedTab == 1 ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 1.6,
            child: CustomPaint(painter: _ActivityLineChartPainter()),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5A5E).withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "Peak activity detected!",
              style: TextStyle(
                color: Color(0xFFE8B5A8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MiniChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFFB366FF).withOpacity(0.6)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    final points = [
      Offset(10, size.height * 0.6),
      Offset(30, size.height * 0.5),
      Offset(50, size.height * 0.4),
      Offset(70, size.height * 0.3),
      Offset(90, size.height * 0.35),
      Offset(110, size.height * 0.25),
      Offset(130, size.height * 0.2),
    ];

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(MiniChartPainter oldDelegate) => false;
}

class _ActivityLineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.12)
          ..strokeWidth = 0.8;

    final labelStyle = TextStyle(color: Colors.white70, fontSize: 11);

    for (int i = 0; i < 5; i++) {
      double dy = size.height * (1 - i / 4);
      canvas.drawLine(Offset(40, dy), Offset(size.width, dy), gridPaint);
    }

    for (int i = 0; i < 6; i++) {
      double dx = 40 + (size.width - 40) * i / 5;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }

    final chartPaint =
        Paint()
          ..color = const Color(0xFFB799FF)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

    final points = [
      Offset(40, size.height * 0.3),
      Offset(40 + (size.width - 40) * 0.15, size.height * 0.1),
      Offset(40 + (size.width - 40) * 0.35, size.height * 0.4),
      Offset(40 + (size.width - 40) * 0.5, size.height * 0.55),
      Offset(40 + (size.width - 40) * 0.7, size.height * 0.2),
      Offset(40 + (size.width - 40) * 0.85, size.height * 0.5),
      Offset(size.width, size.height * 0.35),
    ];

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, chartPaint);

    final yLabels = ["120", "90", "60", "30", "0"];
    for (int i = 0; i < yLabels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: yLabels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      double dy = size.height * (i / 4) - tp.height / 2;
      tp.paint(canvas, Offset(8, dy));
    }

    final xLabels = ["02:00", "06:00", "10:00", "14:00", "18:00", "23:00"];
    for (int i = 0; i < xLabels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: xLabels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      double dx = 40 + (size.width - 40) * (i / 5) - tp.width / 2;
      tp.paint(canvas, Offset(dx, size.height + 8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget buildPriceWatchSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
        child: Row(
          children: const [
            Icon(Icons.show_chart, color: Color(0xFF00D9A3), size: 26),
            SizedBox(width: 6),
            Text(
              "Price Watch",
              style: TextStyle(
                color: Colors.white,
                fontSize: 21.6,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "30-Day Price Trend",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 1.4,
              child: CustomPaint(painter: _PriceTrendChartPainter()),
            ),
          ],
        ),
      ),
    ],
  );
}

class _PriceTrendChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.12)
          ..strokeWidth = 0.8;

    final labelStyle = TextStyle(color: Colors.white70, fontSize: 11);

    for (int i = 0; i < 5; i++) {
      double dy = size.height * (1 - i / 4);
      canvas.drawLine(Offset(40, dy), Offset(size.width, dy), gridPaint);
    }

    for (int i = 0; i < 6; i++) {
      double dx = 40 + (size.width - 40) * i / 5;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }

    final chartPaint =
        Paint()
          ..color = const Color(0xFF00D9A3)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

    final points = [
      Offset(40, size.height * 0.4),
      Offset(40 + (size.width - 40) * 0.12, size.height * 0.35),
      Offset(40 + (size.width - 40) * 0.25, size.height * 0.25),
      Offset(40 + (size.width - 40) * 0.38, size.height * 0.3),
      Offset(40 + (size.width - 40) * 0.5, size.height * 0.2),
      Offset(40 + (size.width - 40) * 0.62, size.height * 0.35),
      Offset(40 + (size.width - 40) * 0.75, size.height * 0.28),
      Offset(40 + (size.width - 40) * 0.88, size.height * 0.32),
      Offset(size.width, size.height * 0.38),
    ];

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, chartPaint);

    final yLabels = ["24", "18", "12", "6", "0"];
    for (int i = 0; i < yLabels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: yLabels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      double dy = size.height * (i / 4) - tp.height / 2;
      tp.paint(canvas, Offset(8, dy));
    }

    final xLabels = ["Oct 18", "Oct 23", "Oct 28", "Nov 2", "Nov 7", "Nov 13"];
    for (int i = 0; i < xLabels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: xLabels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      double dx = 40 + (size.width - 40) * (i / 5) - tp.width / 2;
      tp.paint(canvas, Offset(dx, size.height + 8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget buildDontMissOutSection(List<Map<String, dynamic>> sessions) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
        child: Row(
          children: const [
            Icon(Icons.emoji_events, color: Color(0xFFFFC943), size: 26),
            SizedBox(width: 6),
            Text(
              "Don't Miss Out",
              style: TextStyle(
                color: Colors.white,
                fontSize: 21.6,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.055),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: Colors.white.withOpacity(0.13), width: 0.8),
        ),
        child: Column(
          children: [
            Container(
              color: Colors.white.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: const [
                  Expanded(
                    flex: 5,
                    child: Text(
                      'Movie × Cinema',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Starts\nIn',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14.7,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Seats\nLeft',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14.8,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Capacity',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14.4,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              separatorBuilder:
                  (_, __) => Divider(
                    height: 1,
                    color: Colors.white.withOpacity(0.085),
                    thickness: 1,
                    indent: 13,
                    endIndent: 13,
                  ),
              itemBuilder: (context, index) {
                final s = sessions[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.5),
                              child: Image.network(
                                s['poster'],
                                width: 44,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (c, e, t) => Container(
                                      width: 44,
                                      height: 60,
                                      color: Colors.black12,
                                      child: Icon(
                                        Icons.movie,
                                        color: Colors.white24,
                                        size: 22,
                                      ),
                                    ),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.2,
                                        fontWeight: FontWeight.w700,
                                        height: 1.18,
                                      ),
                                      children: [
                                        TextSpan(text: s['titleMain'] ?? ""),
                                        TextSpan(
                                          text: s['titleRest'] ?? "",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s['cinema'] ?? "",
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                s['startsHours'],
                                style: const TextStyle(
                                  color: Color(0xFFFF9F5A),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.2,
                                  height: 1.08,
                                ),
                              ),
                              Text(
                                s['startsMinutes'],
                                style: const TextStyle(
                                  color: Color(0xFFFF9F5A),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.2,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            s['seatsLeft'].toString(),
                            style: TextStyle(
                              color:
                                  (s['seatsLeft'] as int) <= 9
                                      ? Colors.pinkAccent[100]
                                      : Colors.yellow[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 17.2,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 3.3,
                              horizontal: 15,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.brown.withOpacity(0.33),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              s['capacity'],
                              style: const TextStyle(
                                color: Color(0xFFFECF9A),
                                fontWeight: FontWeight.w800,
                                fontSize: 15.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ],
  );
}
