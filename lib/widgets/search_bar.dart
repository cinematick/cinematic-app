import 'package:flutter/material.dart';
import 'app_colors.dart';

class SearchBarWidget extends StatefulWidget {
  final String hint;
  final Function(String)? onSearch;
  final VoidCallback? onClear;

  const SearchBarWidget({
    super.key,
    required this.hint,
    this.onSearch,
    this.onClear,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _hasText = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    _controller.addListener(_handleTextChange);
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleTextChange() {
    if (mounted) {
      setState(() {
        _hasText = _controller.text.isNotEmpty;
      });
    }
    widget.onSearch?.call(_controller.text);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    _focusNode.removeListener(_handleFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color:
              _isFocused
                  ? const Color(0xFFB863D7)
                  : AppColors.accentOrange.withOpacity(0.5),
          width: _isFocused ? 2.5 : 2,
        ),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon:
              _hasText
                  ? GestureDetector(
                    onTap: () {
                      _controller.clear();
                      widget.onClear?.call();
                    },
                    child: const Icon(Icons.close, color: Colors.white),
                  )
                  : null,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 8,
          ),
        ),
      ),
    );
  }
}
