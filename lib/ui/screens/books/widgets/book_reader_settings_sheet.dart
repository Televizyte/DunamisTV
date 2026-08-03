import 'package:flutter/material.dart';

import '../../../../features/books/state/book_reader_progress_service.dart';
import '../../../../theme/theme_controller.dart';

Future<BookReaderSettings?> showBookReaderSettingsSheet({
  required BuildContext context,
  required BookReaderSettings settings,
  String backendFont = 'serif',
  String backendTheme = 'classic',
  String backendPageSize = 'Standard Book 6×9',
}) {
  final isLight = ThemeController.instance.isLightMode;

  return showModalBottomSheet<BookReaderSettings>(
    context: context,
    isScrollControlled: true,
    backgroundColor:
        isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0D1228),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _BookReaderSettingsSheet(
      settings: settings,
      isLight: isLight,
      backendFont: backendFont,
      backendTheme: backendTheme,
      backendPageSize: backendPageSize,
    ),
  );
}

class _BookReaderSettingsSheet extends StatefulWidget {
  final BookReaderSettings settings;
  final bool isLight;
  final String backendFont;
  final String backendTheme;
  final String backendPageSize;

  const _BookReaderSettingsSheet({
    required this.settings,
    required this.isLight,
    required this.backendFont,
    required this.backendTheme,
    required this.backendPageSize,
  });

  @override
  State<_BookReaderSettingsSheet> createState() =>
      _BookReaderSettingsSheetState();
}

class _BookReaderSettingsSheetState extends State<_BookReaderSettingsSheet> {
  late BookReaderSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  void _update(BookReaderSettings value) => setState(() => _settings = value);

  @override
  Widget build(BuildContext context) {
    final isLight = widget.isLight;
    final titleColor = isLight ? const Color(0xFF1E1B16) : Colors.white;
    final subColor =
        isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.74);
    final dividerColor =
        isLight ? const Color(0xFFE6D8C3) : Colors.white.withOpacity(0.10);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: ListView(
          primary: false,
          shrinkWrap: true,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xFFD2C2AC)
                      : Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Reader Settings',
              style: TextStyle(
                color: titleColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Backend page size: ${widget.backendPageSize}. Choose how this book should read and listen on your device.',
              style: TextStyle(
                color: subColor,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Divider(color: dividerColor),
            const SizedBox(height: 8),
            _SectionTitle('Reading Mode', isLight: isLight),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChoiceChip(
                  label: 'Scroll',
                  selected: _settings.readingMode == BookReadingMode.scroll,
                  isLight: isLight,
                  onTap: () => _update(
                    _settings.copyWith(readingMode: BookReadingMode.scroll),
                  ),
                ),
                _ChoiceChip(
                  label: 'Pages',
                  selected: _settings.readingMode == BookReadingMode.pages,
                  isLight: isLight,
                  onTap: () => _update(
                    _settings.copyWith(readingMode: BookReadingMode.pages),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SectionTitle('Page Animation', isLight: isLight),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChoiceChip(
                  label: 'Off',
                  selected: _settings.pageAnimation == BookPageAnimation.off,
                  isLight: isLight,
                  onTap: () => _update(
                    _settings.copyWith(pageAnimation: BookPageAnimation.off),
                  ),
                ),
                _ChoiceChip(
                  label: 'Slide',
                  selected: _settings.pageAnimation == BookPageAnimation.slide,
                  isLight: isLight,
                  onTap: () => _update(
                    _settings.copyWith(pageAnimation: BookPageAnimation.slide),
                  ),
                ),
                _ChoiceChip(
                  label: 'Soft Flip',
                  selected:
                      _settings.pageAnimation == BookPageAnimation.softFlip,
                  isLight: isLight,
                  onTap: () => _update(
                    _settings.copyWith(
                        pageAnimation: BookPageAnimation.softFlip),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SectionTitle('Font Size', isLight: isLight),
            Slider(
              value: _settings.fontSize.clamp(13.0, 26.0),
              min: 13,
              max: 26,
              divisions: 13,
              label: _settings.fontSize.round().toString(),
              onChanged: (value) =>
                  _update(_settings.copyWith(fontSize: value)),
            ),
            _SliderHint(
              text: '${_settings.fontSize.round()} px',
              isLight: isLight,
            ),
            const SizedBox(height: 16),
            _SectionTitle('Line Spacing', isLight: isLight),
            Slider(
              value: _settings.lineHeight.clamp(1.20, 2.20),
              min: 1.20,
              max: 2.20,
              divisions: 20,
              label: _settings.lineHeight.toStringAsFixed(2),
              onChanged: (value) =>
                  _update(_settings.copyWith(lineHeight: value)),
            ),
            _SliderHint(
              text: '${_settings.lineHeight.toStringAsFixed(2)} line height',
              isLight: isLight,
            ),
            const SizedBox(height: 16),
            _SectionTitle('Font Style', isLight: isLight),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChoiceChip(
                  label: 'Backend (${_cleanLabel(widget.backendFont)})',
                  selected: _settings.fontFamily == 'backend',
                  isLight: isLight,
                  onTap: () =>
                      _update(_settings.copyWith(fontFamily: 'backend')),
                ),
                _ChoiceChip(
                  label: 'Serif',
                  selected: _settings.fontFamily == 'serif',
                  isLight: isLight,
                  onTap: () => _update(_settings.copyWith(fontFamily: 'serif')),
                ),
                _ChoiceChip(
                  label: 'Sans',
                  selected: _settings.fontFamily == 'sans',
                  isLight: isLight,
                  onTap: () => _update(_settings.copyWith(fontFamily: 'sans')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionTitle('Page Theme', isLight: isLight),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChoiceChip(
                  label: 'Backend (${_cleanLabel(widget.backendTheme)})',
                  selected: _settings.pageTheme == 'backend',
                  isLight: isLight,
                  onTap: () =>
                      _update(_settings.copyWith(pageTheme: 'backend')),
                ),
                _ChoiceChip(
                  label: 'Classic',
                  selected: _settings.pageTheme == 'classic',
                  isLight: isLight,
                  onTap: () =>
                      _update(_settings.copyWith(pageTheme: 'classic')),
                ),
                _ChoiceChip(
                  label: 'White',
                  selected: _settings.pageTheme == 'white',
                  isLight: isLight,
                  onTap: () => _update(_settings.copyWith(pageTheme: 'white')),
                ),
                _ChoiceChip(
                  label: 'Sepia',
                  selected: _settings.pageTheme == 'sepia',
                  isLight: isLight,
                  onTap: () => _update(_settings.copyWith(pageTheme: 'sepia')),
                ),
                _ChoiceChip(
                  label: 'Night',
                  selected: _settings.pageTheme == 'night',
                  isLight: isLight,
                  onTap: () => _update(_settings.copyWith(pageTheme: 'night')),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Divider(color: dividerColor),
            const SizedBox(height: 8),
            _SectionTitle('Read Aloud Speed', isLight: isLight),
            Slider(
              value: _settings.speechRate.clamp(0.25, 0.85),
              min: 0.25,
              max: 0.85,
              divisions: 12,
              label: _settings.speechRate.toStringAsFixed(2),
              onChanged: (value) =>
                  _update(_settings.copyWith(speechRate: value)),
            ),
            _SliderHint(
              text: '${_settings.speechRate.toStringAsFixed(2)} speech rate',
              isLight: isLight,
            ),
            const SizedBox(height: 16),
            _SectionTitle('Read Aloud Pitch', isLight: isLight),
            Slider(
              value: _settings.speechPitch.clamp(0.75, 1.35),
              min: 0.75,
              max: 1.35,
              divisions: 12,
              label: _settings.speechPitch.toStringAsFixed(2),
              onChanged: (value) =>
                  _update(_settings.copyWith(speechPitch: value)),
            ),
            _SliderHint(
              text: '${_settings.speechPitch.toStringAsFixed(2)} voice pitch',
              isLight: isLight,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, _settings),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Apply Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2C96),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cleanLabel(String value) {
    final clean = value.trim().replaceAll('_', ' ');
    if (clean.isEmpty) return 'Default';
    return clean.split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final bool isLight;

  const _SectionTitle(this.text, {required this.isLight});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            color: isLight
                ? const Color(0xFF1E1B16)
                : Colors.white.withOpacity(0.82),
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
        ),
      );
}

class _SliderHint extends StatelessWidget {
  final String text;
  final bool isLight;

  const _SliderHint({required this.text, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: isLight ? const Color(0xFF6B6256) : Colors.white60,
        fontWeight: FontWeight.w700,
        fontSize: 11.5,
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isLight;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final normalBg =
        isLight ? const Color(0xFFF2E8D8) : Colors.white.withOpacity(0.06);
    final normalBorder =
        isLight ? const Color(0xFFE0D0BC) : Colors.white.withOpacity(0.10);
    final normalText = isLight ? const Color(0xFF1E1B16) : Colors.white;

    return ActionChip(
      onPressed: onTap,
      backgroundColor: selected ? const Color(0xFFFF2C96) : normalBg,
      side: BorderSide(
        color: selected ? const Color(0xFFFF2C96) : normalBorder,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : normalText,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
