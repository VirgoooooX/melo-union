part of 'provider_tabs.dart';

class ProviderTabItem {
  const ProviderTabItem({
    required this.id,
    required this.label,
    this.leading,
    this.enabled = true,
    this.trailing,
  });

  final String id;
  final String label;
  final Widget? leading;
  final bool enabled;
  final IconData? trailing;
}
