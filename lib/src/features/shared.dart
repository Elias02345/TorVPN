import 'package:flutter/material.dart';

import '../core/core_models.dart';
import '../theme/app_theme.dart';

class PageFrame extends StatelessWidget {
  const PageFrame({
    required this.title,
    required this.subtitle,
    required this.children,
    this.trailing,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 18,
                  runSpacing: 12,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    ?trailing,
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: padding,
      color: color,
      borderColor: borderColor,
      child: child,
    );
  }
}

class Panel extends StatelessWidget {
  const Panel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor ?? AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    required this.subtitle,
    this.icon,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.cyan, size: 20),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.icon,
    required this.label,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
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
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(14),
      color: AppColors.surfaceHigh,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textHigh,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReadinessSteps extends StatelessWidget {
  const ReadinessSteps({required this.steps, super.key});

  final List<ReadinessStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          _ReadinessRow(index: index + 1, step: steps[index]),
          if (index < steps.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({required this.index, required this.step});

  final int index;
  final ReadinessStep step;

  @override
  Widget build(BuildContext context) {
    final color = readinessColor(step.status);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$index',
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(step.detail, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(
                  step.evidenceId,
                  style: const TextStyle(
                    color: AppColors.textFaint,
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          StatusPill(
            icon: readinessIcon(step.status),
            label: readinessLabel(step.status),
            color: color,
          ),
        ],
      ),
    );
  }
}

class EvidenceTable extends StatelessWidget {
  const EvidenceTable({required this.items, super.key});

  final List<LeakEvidenceItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items) ...[
          _EvidenceRow(item: item),
          if (item != items.last)
            const Divider(height: 18, color: AppColors.border),
        ],
      ],
    );
  }
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({required this.item});

  final LeakEvidenceItem item;

  @override
  Widget build(BuildContext context) {
    final color = evidenceColor(item.status);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(evidenceIcon(item.status), color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.area, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(item.message, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 5),
              Text(
                item.evidenceId,
                style: const TextStyle(
                  color: AppColors.textFaint,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        StatusPill(
          icon: evidenceIcon(item.status),
          label: evidenceLabel(item.status),
          color: color,
        ),
      ],
    );
  }
}

class ClaimList extends StatelessWidget {
  const ClaimList({required this.claims, super.key});

  final List<ProtectionClaim> claims;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final claim in claims)
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
            child: Panel(
              padding: const EdgeInsets.all(12),
              color: AppColors.surfaceHigh,
              borderColor: evidenceColor(claim.status).withValues(alpha: 0.36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusPill(
                    icon: evidenceIcon(claim.status),
                    label: claim.label,
                    color: evidenceColor(claim.status),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    claim.message,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    claim.evidenceId,
                    style: const TextStyle(
                      color: AppColors.textFaint,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

Color readinessColor(ReadinessStatus status) {
  return switch (status) {
    ReadinessStatus.verified => AppColors.good,
    ReadinessStatus.pending => AppColors.cyan,
    ReadinessStatus.notReady => AppColors.warn,
  };
}

IconData readinessIcon(ReadinessStatus status) {
  return switch (status) {
    ReadinessStatus.verified => Icons.verified_rounded,
    ReadinessStatus.pending => Icons.schedule_rounded,
    ReadinessStatus.notReady => Icons.lock_rounded,
  };
}

String readinessLabel(ReadinessStatus status) {
  return switch (status) {
    ReadinessStatus.verified => 'Verified',
    ReadinessStatus.pending => 'Pending',
    ReadinessStatus.notReady => 'Not ready',
  };
}

Color evidenceColor(EvidenceStatus status) {
  return switch (status) {
    EvidenceStatus.verified => AppColors.good,
    EvidenceStatus.pending => AppColors.cyan,
    EvidenceStatus.blocked => AppColors.warn,
    EvidenceStatus.localOnly => AppColors.good,
  };
}

IconData evidenceIcon(EvidenceStatus status) {
  return switch (status) {
    EvidenceStatus.verified => Icons.verified_rounded,
    EvidenceStatus.pending => Icons.schedule_rounded,
    EvidenceStatus.blocked => Icons.lock_rounded,
    EvidenceStatus.localOnly => Icons.laptop_mac_rounded,
  };
}

String evidenceLabel(EvidenceStatus status) {
  return switch (status) {
    EvidenceStatus.verified => 'Verified',
    EvidenceStatus.pending => 'Pending',
    EvidenceStatus.blocked => 'Blocked',
    EvidenceStatus.localOnly => 'Local',
  };
}
