import 'package:flutter/material.dart';

class CustomKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onTextChanged;

  const CustomKeyboard({
    super.key,
    required this.controller,
    this.onTextChanged,
  });

  @override
  State<CustomKeyboard> createState() => _CustomKeyboardState();
}

class _CustomKeyboardState extends State<CustomKeyboard> {
  bool _isNumeric = false;
  bool _isShiftActive = false;
  bool _isCapsLock = false;

  // Modern color scheme
  static const Color _bgColor = Colors.transparent;
  static const Color _keyColor = Color(0xFF2A2A2E);
  static const Color _keyHighlight = Color(0xFF3A3A3E);
  static const Color _specialKeyColor = Color(0xFF1E1E22);
  static const Color _accentColor = Color(0xFF0A84FF);
  static const Color _accentGlow = Color(0xFF0A84FF);
  static const Color _textColor = Color(0xFFF5F5F7);

  final List<String> _row1Alpha = [
    'q',
    'w',
    'e',
    'r',
    't',
    'y',
    'u',
    'i',
    'o',
    'p',
  ];
  final List<String> _row2Alpha = ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'];
  final List<String> _row3Alpha = ['z', 'x', 'c', 'v', 'b', 'n', 'm'];

  final List<String> _row1Numeric = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '0',
  ];
  final List<String> _row2Numeric = [
    '-',
    '/',
    ':',
    ';',
    '(',
    ')',
    '\$',
    '&',
    '@',
    '"',
  ];
  final List<String> _row3Numeric = [
    '.',
    ',',
    '?',
    '!',
    "'",
    '#',
    '%',
    '*',
    '+',
  ];

  void _onKeyTap(String key) {
    final controller = widget.controller;
    final text = controller.text;
    final selection = controller.selection;
    final cursorPos = selection.baseOffset < 0
        ? text.length
        : selection.baseOffset;
    final endPos = selection.extentOffset < 0
        ? text.length
        : selection.extentOffset;

    String insertText = key;
    if (!_isNumeric && (_isShiftActive || _isCapsLock)) {
      insertText = key.toUpperCase();
    }

    final newText =
        text.substring(0, cursorPos) + insertText + text.substring(endPos);
    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: cursorPos + 1);

    if (_isShiftActive && !_isCapsLock) {
      setState(() => _isShiftActive = false);
    }

    widget.onTextChanged?.call();
  }

  void _onBackspace() {
    final controller = widget.controller;
    final text = controller.text;
    final selection = controller.selection;
    final cursorPos = selection.baseOffset < 0
        ? text.length
        : selection.baseOffset;
    final endPos = selection.extentOffset < 0
        ? text.length
        : selection.extentOffset;

    if (selection.isCollapsed && cursorPos > 0) {
      final newText =
          text.substring(0, cursorPos - 1) + text.substring(cursorPos);
      controller.text = newText;
      controller.selection = TextSelection.collapsed(offset: cursorPos - 1);
      widget.onTextChanged?.call();
    } else if (!selection.isCollapsed) {
      final newText = text.substring(0, cursorPos) + text.substring(endPos);
      controller.text = newText;
      controller.selection = TextSelection.collapsed(offset: cursorPos);
      widget.onTextChanged?.call();
    }
  }

  void _onSpace() {
    _onKeyTap(' ');
  }

  void _onReturn() {
    _onKeyTap('\n');
  }

  void _onShift() {
    setState(() {
      if (_isCapsLock) {
        _isCapsLock = false;
        _isShiftActive = false;
      } else if (_isShiftActive) {
        _isCapsLock = true;
      } else {
        _isShiftActive = true;
      }
    });
  }

  void _toggleNumeric() {
    setState(() {
      _isNumeric = !_isNumeric;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate key size to be square based on available width
        // Account for 10 keys + padding (3px * 2 per key = 6px per key) + container padding
        final availableWidth =
            constraints.maxWidth - 24; // 12px padding on each side
        final keySize =
            (availableWidth - (10 * 6)) / 10; // 10 keys, 6px padding each
        // Determine if tablet based on available width (> 500px suggests tablet)
        final isTablet = availableWidth > 500;
        // Use larger max key size for tablets to fill the space
        final maxKeySize = isTablet ? 70.0 : 44.0;
        final clampedKeySize = keySize.clamp(28.0, maxKeySize);

        return Container(
          color: _bgColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Row 1
              _buildRow1(clampedKeySize),
              const SizedBox(height: 8),
              // Row 2
              _buildRow2(clampedKeySize),
              const SizedBox(height: 8),
              // Row 3 (with shift and backspace)
              _buildRow3(clampedKeySize),
              const SizedBox(height: 8),
              // Row 4 (123, space, return)
              _buildRow4(clampedKeySize),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow1(double keySize) {
    final keys = _isNumeric ? _row1Numeric : _row1Alpha;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) => _buildSquareKey(key, keySize)).toList(),
    );
  }

  Widget _buildRow2(double keySize) {
    final keys = _isNumeric ? _row2Numeric : _row2Alpha;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) => _buildSquareKey(key, keySize)).toList(),
    );
  }

  Widget _buildRow3(double keySize) {
    final keys = _isNumeric ? _row3Numeric : _row3Alpha;
    final specialKeyWidth = keySize * 1.3;
    // In numeric mode, use regular key size for backspace to fit 10 items
    final backspaceWidth = _isNumeric ? keySize : specialKeyWidth;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Shift key (only for alpha)
        if (!_isNumeric)
          _buildSpecialKeySquare(
            width: specialKeyWidth,
            height: keySize,
            child: Icon(
              _isCapsLock ? Icons.keyboard_capslock : Icons.arrow_upward,
              color: (_isShiftActive || _isCapsLock) ? _bgColor : _textColor,
              size: 18,
            ),
            onTap: _onShift,
            isActive: _isShiftActive || _isCapsLock,
          ),

        // Letter/Symbol keys
        ...keys.map((key) => _buildSquareKey(key, keySize)),

        // Backspace key
        _buildSpecialKeySquare(
          width: backspaceWidth,
          height: keySize,
          child: Icon(
            Icons.backspace_outlined,
            color: _textColor,
            size: _isNumeric ? 16 : 18,
          ),
          onTap: _onBackspace,
        ),
      ],
    );
  }

  Widget _buildRow4(double keySize) {
    final specialKeyWidth = keySize * 1.3;
    // Calculate space bar width based on row width minus special keys
    final totalRowWidth = (keySize * 10) + (10 * 6);
    final spaceBarWidth = totalRowWidth - (2 * specialKeyWidth) - (4 * 6);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 123/ABC toggle
        _buildSpecialKeySquare(
          width: specialKeyWidth,
          height: keySize,
          child: Text(
            _isNumeric ? 'ABC' : '123',
            style: const TextStyle(
              color: _textColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: _toggleNumeric,
        ),
        // Space bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: SizedBox(
            width: spaceBarWidth,
            height: keySize,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_keyHighlight, _keyColor],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _onSpace,
                  borderRadius: BorderRadius.circular(8),
                  splashColor: _accentColor.withValues(alpha: 0.3),
                  highlightColor: _accentColor.withValues(alpha: 0.1),
                  child: const Center(
                    child: Text(
                      'space',
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Return key
        _buildSpecialKeySquare(
          width: specialKeyWidth,
          height: keySize,
          child: const Icon(
            Icons.keyboard_return,
            color: Colors.white,
            size: 18,
          ),
          onTap: _onReturn,
          color: _accentColor,
        ),
      ],
    );
  }

  Widget _buildSquareKey(String key, double size) {
    String displayKey = key;
    if (!_isNumeric && (_isShiftActive || _isCapsLock)) {
      displayKey = key.toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: SizedBox(
        width: size,
        height: size,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_keyHighlight, _keyColor],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.05),
                offset: const Offset(0, -1),
                blurRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onKeyTap(key),
              borderRadius: BorderRadius.circular(8),
              splashColor: _accentColor.withValues(alpha: 0.3),
              highlightColor: _accentColor.withValues(alpha: 0.1),
              child: Center(
                child: Text(
                  displayKey,
                  style: const TextStyle(
                    color: _textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKeySquare({
    required double width,
    required double height,
    required Widget child,
    required VoidCallback onTap,
    bool isActive = false,
    Color? color,
  }) {
    final isAccent = color == _accentColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0)],
                  )
                : isAccent
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _accentColor.withValues(alpha: 1),
                      const Color(0xFF0066CC),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF252528), _specialKeyColor],
                  ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: isAccent
                    ? _accentGlow.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.4),
                offset: const Offset(0, 2),
                blurRadius: isAccent ? 8 : 4,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              splashColor: Colors.white.withValues(alpha: 0.2),
              highlightColor: Colors.white.withValues(alpha: 0.1),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
