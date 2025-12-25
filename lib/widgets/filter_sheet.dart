import 'package:cinematick/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class FilterSheetWidget extends StatefulWidget {
  final List<String> allLanguages, allExperiences, allGenres;
  final List<bool> langSelected, xpSelected, genreSelected;
  final VoidCallback onApply, onClear;
  const FilterSheetWidget({
    required this.allLanguages,
    required this.allExperiences,
    required this.allGenres,
    required this.langSelected,
    required this.xpSelected,
    required this.genreSelected,
    required this.onApply,
    required this.onClear,
  });
  @override
  State<FilterSheetWidget> createState() => _FilterSheetWidgetState();
}

class _FilterSheetWidgetState extends State<FilterSheetWidget> {
  // NEW: custom chip with gradient support
  Widget _buildGradientChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.filterGradient : null,
          color: selected ? null : const Color.fromARGB(141, 59, 69, 88),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: const BorderRadius.only(topRight: Radius.circular(24)),
      child: BackdropFilter(
        // NEW: blur effect
        filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          height: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(24),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              // CHANGED: more transparent gradient to show blur
              colors: [
                const Color(0xFF191B2E).withOpacity(0.85),

                const Color(0xFF321167).withOpacity(0.65),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Filters",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70, size: 26),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25),
                      const Text(
                        "Languages",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(widget.allLanguages.length, (
                          i,
                        ) {
                          final selected = widget.langSelected[i];
                          return _buildGradientChip(
                            label: widget.allLanguages[i],
                            selected: selected,
                            onSelected:
                                () => setState(
                                  () => widget.langSelected[i] = !selected,
                                ),
                          );
                        }),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        "Screen Experience",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(widget.allExperiences.length, (
                          i,
                        ) {
                          final selected = widget.xpSelected[i];
                          return _buildGradientChip(
                            label: widget.allExperiences[i],
                            selected: selected,
                            onSelected:
                                () => setState(
                                  () => widget.xpSelected[i] = !selected,
                                ),
                          );
                        }),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        "Genres",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(widget.allGenres.length, (i) {
                          final selected = widget.genreSelected[i];
                          return _buildGradientChip(
                            label: widget.allGenres[i],
                            selected: selected,
                            onSelected:
                                () => setState(
                                  () => widget.genreSelected[i] = !selected,
                                ),
                          );
                        }),
                      ),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: widget.onApply,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.filterGradient,

                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        alignment: Alignment.center,
                        child: const Text(
                          "Apply Filters",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onClear,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54, width: 1.6),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Clear All",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
