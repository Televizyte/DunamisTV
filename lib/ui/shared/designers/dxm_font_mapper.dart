import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared quote designer font mapper.
///
/// The backend stores compact font keys such as `impact`, `anton`,
/// `archivo_black`, `bebas_neue`, etc. Flutter does not automatically have
/// browser/system fonts like Impact, so this mapper converts backend font keys
/// into frontend-safe GoogleFonts/system TextStyles.
class DxmFontMapper {
  const DxmFontMapper._();

  static TextStyle style(
    String? rawFont, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    List<Shadow>? shadows,
  }) {
    final key = normalize(rawFont);
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      shadows: shadows,
    );

    switch (key) {
      // Backend legacy Impact key. Impact itself is not bundled in Flutter;
      // Anton is the closest safe headline replacement and must also be used
      // by the backend preview for layout parity.
      case 'impact':
      case 'impact_bold':
      case 'impact_style':
      case 'anton':
        return GoogleFonts.anton(textStyle: base);
      case 'archivo':
      case 'archivo_black':
      case 'arial_black':
        return GoogleFonts.archivoBlack(textStyle: base);
      case 'bebas':
      case 'bebas_neue':
        return GoogleFonts.bebasNeue(textStyle: base);
      case 'oswald':
        return GoogleFonts.oswald(textStyle: base);
      case 'montserrat':
        return GoogleFonts.montserrat(textStyle: base);
      case 'poppins':
      case 'inter':
        return GoogleFonts.poppins(textStyle: base);
      case 'playfair':
      case 'playfair_display':
        return GoogleFonts.playfairDisplay(textStyle: base);
      case 'merriweather':
        return GoogleFonts.merriweather(textStyle: base);
      case 'lora':
        return GoogleFonts.lora(textStyle: base);
      case 'roboto_slab':
      case 'slab':
        return GoogleFonts.robotoSlab(textStyle: base);
      case 'serif':
      case 'georgia':
      case 'times':
      case 'garamond':
        return GoogleFonts.merriweather(textStyle: base);
      case 'mono':
      case 'courier':
        return GoogleFonts.robotoMono(textStyle: base);
      case 'system':
      case 'arial':
      case 'verdana':
      case 'tahoma':
      case 'trebuchet':
      default:
        return base;
    }
  }

  static String normalize(String? rawFont) {
    final raw = (rawFont ?? '').trim().toLowerCase();
    if (raw.isEmpty) return 'system';

    var key = raw
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    switch (key) {
      case 'impact_bold':
      case 'impact':
      case 'impact_style':
        return 'impact';
      case 'arial_black':
      case 'black':
        return 'archivo_black';
      case 'archivo_black':
      case 'archivo':
        return 'archivo_black';
      case 'bebas_neue':
      case 'bebas':
        return 'bebas_neue';
      case 'playfair_display':
      case 'playfair':
        return 'playfair_display';
      case 'roboto_slab':
        return 'roboto_slab';
      case 'classic_serif':
        return 'serif';
      case 'modern_sans':
        return 'poppins';
      default:
        return key;
    }
  }
}
