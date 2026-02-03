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

  // Static method to clear the search bar from parent widget
  static void clearFromKey(GlobalKey<_SearchBarWidgetState> key) {
    key.currentState?.clearSearchBar();
  }
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

  // Method to clear search bar from parent widget
  void clearSearchBar() {
    if (mounted) {
      _controller.clear();
      _focusNode.unfocus();
      setState(() {
        _hasText = false;
        _isFocused = false;
      });
    }
  }

  // Method to focus search bar from parent widget
  void focusSearchBar() {
    if (mounted) {
      _focusNode.requestFocus();
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
    return SizedBox(
      height: 42,
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 25, 35, 70),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color:
              
                     const Color.fromARGB(255, 247, 151, 25).withOpacity(0.5),
            width: _isFocused ? 2.5 : 2,
          ),
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          minLines: 1,
          maxLines: 1,
          decoration: InputDecoration(
            filled: false,
            hintText: widget.hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: Colors.white, size: 20),
            suffixIcon:
                _hasText
                    ? GestureDetector(
                      onTap: () {
                        _controller.clear();
                        widget.onClear?.call();
                      },
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    )
                    : null,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 8,
            ),
          ),
          cursorColor: Colors.white,
        ),
      ),
    );
  }
}
