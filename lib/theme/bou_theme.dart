// lib/theme/bou_theme.dart
import 'dart:ui';
import 'package:flutter/material.dart';

/// ALPHA palette — power & challenge
class Alpha {
  // Bases (gym-floor graphite)
  static const Color bg0 = Color(0xFF0A0B0D); // near-black
  static const Color bg1 = Color(0xFF0E1114);
  static const Color bg2 = Color(0xFF14181E); // elevated surfaces

  // Text (crisp, assertive)
  static const Color textHi = Color(0xFFF2F5F9); // off-white
  static const Color textLo = Color(0xFFA3ADBA); // steel grey

  // Accents (power cues)
  static const Color focus = Color(0xFF00D2FF);  // electric cyan (effort/focus)
  static const Color fire  = Color(0xFFFF4C2E);  // magma (PR / warnings)
  static const Color pump  = Color(0xFF00E18D);  // neon green (successful sets)

  // Strokes / separators
  static const Color stroke = Color(0x15FFFFFF); // subtle 8–10% white
}

ThemeData bouDarkTheme() {
  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary:   Alpha.focus,
    onPrimary: Colors.black,
    secondary: Alpha.pump,
    onSecondary: Colors.black,
    tertiary:  Alpha.fire,
    onTertiary: Colors.white,
    error:     Alpha.fire,
    onError:   Colors.white,
    surface:   Alpha.bg2,
    onSurface: Alpha.textHi,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent, // let the power gradient show
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.4),
      titleLarge:    TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
      titleMedium:   TextStyle(fontWeight: FontWeight.w700),
      bodyLarge:     TextStyle(color: Alpha.textLo, height: 1.36),
      bodyMedium:    TextStyle(color: Alpha.textLo, height: 1.36),
      labelLarge:    TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
    ).apply(bodyColor: Alpha.textHi, displayColor: Alpha.textHi),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: Alpha.textHi, fontWeight: FontWeight.w900, fontSize: 18),
      iconTheme: IconThemeData(color: Alpha.textHi),
    ),

    // Harder card edges, athletic feel
    cardTheme: CardThemeData(
      color: Alpha.bg2,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Alpha.stroke),
      ),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Alpha.bg2.withOpacity(0.95),
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: Alpha.bg2,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Alpha.stroke),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Alpha.bg1,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Alpha.stroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Alpha.focus, width: 1.8),
      ),
      labelStyle: const TextStyle(color: Alpha.textLo),
      hintStyle:  const TextStyle(color: Alpha.textLo),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 14, horizontal: 16)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        backgroundColor: const WidgetStatePropertyAll(Alpha.focus),
        foregroundColor: const WidgetStatePropertyAll(Colors.black),
        elevation: const WidgetStatePropertyAll(0),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 14, horizontal: 16)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        side: const WidgetStatePropertyAll(BorderSide(color: Alpha.stroke)),
        foregroundColor: const WidgetStatePropertyAll(Alpha.textHi),
      ),
    ),

    textButtonTheme: const TextButtonThemeData(
      style: ButtonStyle(foregroundColor: WidgetStatePropertyAll(Alpha.focus)),
    ),

    sliderTheme: const SliderThemeData(trackHeight: 3, thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8)),

    navigationBarTheme: NavigationBarThemeData(
      height: 66,
      backgroundColor: Alpha.bg1.withOpacity(0.94),
      surfaceTintColor: Colors.transparent,
      indicatorColor: Alpha.focus.withOpacity(0.18),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? Alpha.focus : Alpha.textLo, size: selected ? 28 : 26);
      }),
      labelTextStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w800)),
    ),

    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Alpha.bg1,
      contentTextStyle: TextStyle(color: Alpha.textHi, fontWeight: FontWeight.w700),
      behavior: SnackBarBehavior.floating,
    ),

    dividerTheme: const DividerThemeData(color: Alpha.stroke, thickness: 1),
  );
}

/// Global “power” gradient + subtle vignette
class BouBackground extends StatelessWidget {
  final Widget child;
  const BouBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Alpha.bg0, Color(0xFF0B0E12), Alpha.bg0],
        ),
      ),
      child: Stack(
        children: [
          // Cyan glow accent (top-right)
          Positioned(
            right: -80, top: -80,
            child: _GlowCircle(color: Alpha.focus.withOpacity(0.18), size: 220),
          ),
          // Magma glow accent (bottom-left)
          Positioned(
            left: -90, bottom: -100,
            child: _GlowCircle(color: Alpha.fire.withOpacity(0.10), size: 260),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color; final double size;
  const _GlowCircle({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: size * 0.6, spreadRadius: size * 0.2)],
      ),
    );
  }
}

/// Aggressive “glass” panel (thicker, more contrast)
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// PR badge / status chip
class PRChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const PRChip({super.key, required this.label, this.icon = Icons.flash_on, this.color = Alpha.fire});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.16), color.withOpacity(0.05)]),
        border: Border.all(color: color.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

/// Power button with glow
class GlowButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool tonal; // subtle version
  final Color color;
  const GlowButton(this.label, {super.key, this.onPressed, this.tonal = false, this.color = Alpha.focus});
  @override
  Widget build(BuildContext context) {
    final bg = tonal ? color.withOpacity(0.14) : color;
    final fg = tonal ? color : Colors.black;
    return Container(
      decoration: !tonal ? BoxDecoration(
        boxShadow: [BoxShadow(color: color.withOpacity(0.45), blurRadius: 20, spreadRadius: 1)],
        borderRadius: BorderRadius.circular(12),
      ) : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(bg),
          foregroundColor: WidgetStatePropertyAll(fg),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 14, horizontal: 16)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          elevation: const WidgetStatePropertyAll(0),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.2)),
      ),
    );
  }
}
