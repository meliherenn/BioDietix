import 'package:flutter/material.dart';

const ink = Color(0xFF242A20);
const green = Color(0xFF2E7A55);
const deepGreen = Color(0xFF173B2B);
const sage = Color(0xFF9FAF73);
const gold = Color(0xFFD7A84E);
const cream = Color(0xFFFFF8EA);
const blush = Color(0xFFFFE7D6);
const background = Color(0xFFFFFBF3);
const line = Color(0xFFE9DECE);
const muted = Color(0xFF786F63);
const danger = Color(0xFFB42318);
const amber = Color(0xFFA16207);
const tomato = Color(0xFFE96D4E);

const pagePadding = EdgeInsets.fromLTRB(18, 20, 18, 118);

bool _dark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color appBackground(BuildContext context) {
  return _dark(context) ? const Color(0xFF0D130F) : background;
}

Color appCardColor(BuildContext context) {
  return _dark(context) ? const Color(0xFF182119) : const Color(0xFFFFFCF6);
}

Color appLineColor(BuildContext context) {
  return _dark(context) ? const Color(0xFF334333) : line;
}

Color appMutedColor(BuildContext context) {
  return _dark(context) ? const Color(0xFFC1B8A8) : muted;
}

Color appSecondaryFill(BuildContext context) {
  return _dark(context) ? const Color(0xFF222C20) : const Color(0xFFF5EDDC);
}

Color appSecondaryText(BuildContext context) {
  return _dark(context) ? const Color(0xFFF7EEDC) : deepGreen;
}

class AppCard extends StatelessWidget {
  const AppCard({required this.child, this.title, this.subtitle, super.key});

  final String? title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: appCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: appLineColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _dark(context) ? .24 : .055),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: appMutedColor(context)),
              ),
            ],
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class HeroPanel extends StatelessWidget {
  const HeroPanel({
    required this.title,
    required this.subtitle,
    this.kicker = 'BIODIETIX',
    this.icon,
    super.key,
  });

  final String kicker;
  final String title;
  final String subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final dark = _dark(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF1D2D20), Color(0xFF102018)]
              : const [Color(0xFF275A3F), Color(0xFF173B2B)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dark
              ? const Color(0xFF3D563E)
              : const Color(0xFFB6C99D).withValues(alpha: .45),
        ),
        boxShadow: [
          BoxShadow(
            color: deepGreen.withValues(alpha: dark ? .30 : .18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -28,
            child: Icon(
              Icons.eco_rounded,
              color: Colors.white.withValues(alpha: .06),
              size: 128,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cream.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cream.withValues(alpha: .22)),
                  ),
                  child: Icon(icon, color: cream, size: 25),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                kicker,
                style: const TextStyle(
                  color: Color(0xFFEAD083),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFF0E7D5),
                  height: 1.45,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.hint,
    this.enabled = true,
    this.obscureText = false,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? hint;
  final bool enabled;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            enabled: enabled,
            obscureText: obscureText,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}

class AppFormTextField extends StatelessWidget {
  const AppFormTextField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.hint,
    this.enabled = true,
    this.obscureText = false,
    this.validator,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? hint;
  final bool enabled;
  final bool obscureText;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            enabled: enabled,
            obscureText: obscureText,
            validator: validator,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.secondary = false,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool secondary;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: secondary ? appSecondaryFill(context) : green,
          foregroundColor: secondary ? appSecondaryText(context) : Colors.white,
          disabledBackgroundColor: _dark(context)
              ? const Color(0xFF29372B)
              : const Color(0xFFE5DAC9),
          disabledForegroundColor: appMutedColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: secondary
                ? BorderSide(color: appLineColor(context))
                : BorderSide.none,
          ),
        ),
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: _dark(context)
          ? const Color(0xFF2A412B)
          : const Color(0xFFEAF3D9),
      checkmarkColor: _dark(context) ? Colors.white : green,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: selected ? green : appLineColor(context)),
      labelStyle: TextStyle(
        color: selected ? appSecondaryText(context) : appMutedColor(context),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class NoticeBox extends StatelessWidget {
  const NoticeBox({required this.message, this.warning = false, super.key});

  final String message;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final fill = warning
        ? (_dark(context) ? const Color(0xFF3A2A16) : const Color(0xFFFFF2D7))
        : appSecondaryFill(context);
    final border = warning
        ? (_dark(context) ? const Color(0xFF8A661F) : const Color(0xFFE3C989))
        : appLineColor(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Text(message),
    );
  }
}

void showAppSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
