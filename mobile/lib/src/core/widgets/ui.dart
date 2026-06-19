import 'package:flutter/material.dart';

const ink = Color(0xFF25251F);
const green = Color(0xFF27684B);
const deepGreen = Color(0xFF12372A);
const sage = Color(0xFF9CAD74);
const gold = Color(0xFFE3B557);
const cream = Color(0xFFFFF7E9);
const blush = Color(0xFFFFE4D4);
const background = Color(0xFFFFFAF1);
const line = Color(0xFFE9DCC8);
const muted = Color(0xFF756E63);
const danger = Color(0xFFB42318);
const amber = Color(0xFFA16207);
const tomato = Color(0xFFE96D4E);
const aqua = Color(0xFF2F9F8E);
const fiber = Color(0xFF7F9457);
const cocoa = Color(0xFF6E5138);
const porcelain = Color(0xFFFFFDF8);

const pagePadding = EdgeInsets.fromLTRB(18, 18, 18, 32);

bool _dark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color appBackground(BuildContext context) {
  return _dark(context) ? const Color(0xFF07120E) : background;
}

Color appCardColor(BuildContext context) {
  return _dark(context) ? const Color(0xFF10231B) : porcelain;
}

Color appElevatedCardColor(BuildContext context) {
  return _dark(context) ? const Color(0xFF152B21) : const Color(0xFFFFFBF4);
}

Color appLineColor(BuildContext context) {
  return _dark(context) ? const Color(0xFF2D4439) : line;
}

Color appMutedColor(BuildContext context) {
  return _dark(context) ? const Color(0xFFC8C1B4) : muted;
}

Color appSecondaryFill(BuildContext context) {
  return _dark(context) ? const Color(0xFF1B3026) : const Color(0xFFF5ECD9);
}

Color appSecondaryText(BuildContext context) {
  return _dark(context) ? const Color(0xFFF9F1E3) : deepGreen;
}

Color appSoftGreen(BuildContext context) {
  return _dark(context) ? const Color(0xFF1B3B2E) : const Color(0xFFE8F2DB);
}

Color appInputFill(BuildContext context) {
  return _dark(context) ? const Color(0xFF0C1A14) : const Color(0xFFFFF8EA);
}

List<Color> appBackgroundGradient(BuildContext context) {
  return _dark(context)
      ? const [Color(0xFF07120E), Color(0xFF0F2119), Color(0xFF07120E)]
      : const [Color(0xFFFFFBF3), Color(0xFFFFF1DA), Color(0xFFF4F5DE)];
}

BoxShadow appSoftShadow(BuildContext context, {double opacity = 1}) {
  final dark = _dark(context);
  return BoxShadow(
    color: dark
        ? Colors.black.withValues(alpha: .32 * opacity)
        : const Color(0xFF7D5E33).withValues(alpha: .10 * opacity),
    blurRadius: dark ? 26 : 30,
    offset: const Offset(0, 16),
  );
}

class AppScreen extends StatelessWidget {
  const AppScreen({
    required this.child,
    this.padding = pagePadding,
    this.scrollable = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: appBackground(context),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: appBackgroundGradient(context),
        ),
      ),
      child: scrollable ? ListView(children: [content]) : content,
    );
  }
}

class BioDietixLogoMark extends StatelessWidget {
  const BioDietixLogoMark({
    this.size = 76,
    this.showGlow = true,
    this.asset = 'assets/launcher/biodietix_icon.png',
    super.key,
  });

  final double size;
  final bool showGlow;
  final String asset;

  @override
  Widget build(BuildContext context) {
    final radius = size * .28;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .07),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _dark(context)
              ? const [Color(0xFF1DA38F), Color(0xFF22634D)]
              : const [Color(0xFF35B79E), Color(0xFF27684B)],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: aqua.withValues(alpha: _dark(context) ? .30 : .22),
                  blurRadius: size * .42,
                  spreadRadius: size * .04,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius * .78),
        child: Image.asset(asset, fit: BoxFit.cover),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.title,
    this.subtitle,
    this.padding = const EdgeInsets.all(18),
    this.margin = const EdgeInsets.only(bottom: 14),
    this.trailing,
    this.accentColor,
    super.key,
  });

  final String? title;
  final String? subtitle;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Widget? trailing;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? green;
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: appCardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: appLineColor(context)),
        boxShadow: [appSoftShadow(context, opacity: .65)],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -36,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: _dark(context) ? .08 : .055),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null || trailing != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title!,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                subtitle!,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: appMutedColor(context)),
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      const Spacer(),
                    if (trailing != null) ...[
                      const SizedBox(width: 12),
                      trailing!,
                    ],
                  ],
                ),
                const SizedBox(height: 16),
              ],
              child,
            ],
          ),
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
              ? const [Color(0xFF1C4334), Color(0xFF0E241B)]
              : const [Color(0xFF2F8667), Color(0xFF173B2B)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: dark ? const Color(0xFF3D6656) : cream.withValues(alpha: .35),
        ),
        boxShadow: [
          BoxShadow(
            color: deepGreen.withValues(alpha: dark ? .32 : .20),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -34,
            child: Icon(
              Icons.local_dining_rounded,
              color: Colors.white.withValues(alpha: .065),
              size: 150,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: cream.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: cream.withValues(alpha: .22)),
                  ),
                  child: Icon(icon, color: cream, size: 25),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                kicker,
                style: const TextStyle(
                  color: Color(0xFFFFD883),
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
                  fontSize: 28,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFF4E9D7),
                  height: 1.45,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.title,
    this.subtitle,
    this.kicker,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? kicker;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kicker != null) ...[
                  Text(
                    kicker!.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: green,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _dark(context) ? cream : ink,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: appMutedColor(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
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
    this.prefixIcon,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? hint;
  final bool enabled;
  final bool obscureText;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 7),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            enabled: enabled,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
            ),
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
    this.prefixIcon,
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
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            enabled: enabled,
            obscureText: obscureText,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
            ),
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
    this.icon,
    this.destructive = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool secondary;
  final bool busy;
  final IconData? icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final mainColor = destructive ? danger : green;
    final disabledFill = _dark(context)
        ? const Color(0xFF23342B)
        : const Color(0xFFE6DAC8);
    final child = busy
        ? SizedBox(
            width: 19,
            height: 19,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: secondary ? mainColor : Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          );

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: secondary ? appSecondaryFill(context) : mainColor,
          foregroundColor: secondary ? appSecondaryText(context) : Colors.white,
          disabledBackgroundColor: disabledFill,
          disabledForegroundColor: appMutedColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: secondary
                ? BorderSide(color: appLineColor(context))
                : BorderSide.none,
          ),
        ),
        onPressed: busy ? null : onPressed,
        child: child,
      ),
    );
  }
}

class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      avatar: icon == null
          ? null
          : Icon(
              icon,
              size: 17,
              color: selected
                  ? appSecondaryText(context)
                  : appMutedColor(context),
            ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: appSoftGreen(context),
      checkmarkColor: _dark(context) ? Colors.white : green,
      backgroundColor: appSecondaryFill(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide(color: selected ? green : appLineColor(context)),
      labelStyle: TextStyle(
        color: selected ? appSecondaryText(context) : appMutedColor(context),
        fontWeight: FontWeight.w800,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    );
  }
}

class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
  });

  final T value;
  final List<AppSegment<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: appSecondaryFill(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appLineColor(context)),
      ),
      child: Row(
        children: items.map((item) {
          final selected = item.value == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(item.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? green : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: green.withValues(alpha: .20),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.icon != null) ...[
                      Icon(
                        item.icon,
                        size: 17,
                        color: selected ? Colors.white : appMutedColor(context),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : appMutedColor(context),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class AppSegment<T> {
  const AppSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

class NoticeBox extends StatelessWidget {
  const NoticeBox({
    required this.message,
    this.warning = false,
    this.icon,
    super.key,
  });

  final String message;
  final bool warning;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = warning ? amber : green;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _dark(context) ? .18 : .10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? (warning ? Icons.info_rounded : Icons.cloud_done_rounded),
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: _dark(context) ? cream : ink,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.color = green,
    this.subtitle,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: appCardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: appLineColor(context)),
        boxShadow: [appSoftShadow(context, opacity: .42)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: _dark(context) ? .18 : .12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: appMutedColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MealCard extends StatelessWidget {
  const MealCard({
    required this.title,
    required this.subtitle,
    required this.calories,
    required this.kcalLabel,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final String title;
  final String subtitle;
  final int calories;
  final String kcalLabel;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appElevatedCardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: appLineColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gold.withValues(alpha: .92),
                  tomato.withValues(alpha: .82),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.restaurant_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: appMutedColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '$calories $kcalLabel',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: green),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class StatePanel extends StatelessWidget {
  const StatePanel({
    required this.title,
    required this.message,
    required this.icon,
    this.action,
    this.color = green,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _dark(context) ? .16 : .09),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: .26)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: appMutedColor(context)),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({this.photoUrl, this.radius = 38, this.onTap, super.key});

  final String? photoUrl;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final image = photoUrl == null ? null : NetworkImage(photoUrl!);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: appSoftGreen(context),
            backgroundImage: image,
            child: image == null
                ? Icon(Icons.person_rounded, size: radius, color: green)
                : null,
          ),
          if (onTap != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: green,
                  shape: BoxShape.circle,
                  border: Border.all(color: appCardColor(context), width: 3),
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AppBottomSheetScaffold extends StatelessWidget {
  const AppBottomSheetScaffold({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: appBackground(context)),
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: appLineColor(context),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

void showAppSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      margin: const EdgeInsets.all(14),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
