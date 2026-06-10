import 'package:flutter/material.dart';

const ink = Color(0xFF151B18);
const green = Color(0xFF11847A);
const deepGreen = Color(0xFF0A2D28);
const gold = Color(0xFFC7A45D);
const background = Color(0xFFF7F7F3);
const line = Color(0xFFE2E5DF);
const muted = Color(0xFF6B746F);
const danger = Color(0xFFB42318);
const amber = Color(0xFFA16207);
const violet = Color(0xFF7C3AED);

const pagePadding = EdgeInsets.fromLTRB(18, 18, 18, 118);

bool _dark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color appBackground(BuildContext context) {
  return _dark(context) ? const Color(0xFF050A09) : background;
}

Color appCardColor(BuildContext context) {
  return _dark(context) ? const Color(0xFF101715) : Colors.white;
}

Color appLineColor(BuildContext context) {
  return _dark(context) ? const Color(0xFF26322F) : line;
}

Color appMutedColor(BuildContext context) {
  return _dark(context) ? const Color(0xFFAAB5AF) : muted;
}

Color appSecondaryFill(BuildContext context) {
  return _dark(context) ? const Color(0xFF17211F) : const Color(0xFFF0F3EE);
}

Color appSecondaryText(BuildContext context) {
  return _dark(context) ? const Color(0xFFE8EFEB) : deepGreen;
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appLineColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _dark(context) ? .20 : .045),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _dark(context) ? const Color(0xFF0D1816) : deepGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _dark(context)
              ? const Color(0xFF223A35)
              : Colors.white.withValues(alpha: .18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _dark(context) ? .22 : .10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            kicker,
            style: const TextStyle(
              color: gold,
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
              fontSize: 26,
              height: 1.13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFFDBE7E1),
              height: 1.45,
              fontSize: 15,
            ),
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
      height: 50,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: secondary ? appSecondaryFill(context) : green,
          foregroundColor: secondary ? appSecondaryText(context) : Colors.white,
          disabledBackgroundColor: _dark(context)
              ? const Color(0xFF213A34)
              : const Color(0xFFE0E7E2),
          disabledForegroundColor: appMutedColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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
          ? const Color(0xFF183B36)
          : const Color(0xFFE5F2EF),
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
        ? (_dark(context) ? const Color(0xFF3D2A12) : const Color(0xFFFFF8E8))
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(message),
    );
  }
}

void showAppSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
