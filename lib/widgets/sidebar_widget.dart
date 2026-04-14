import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum NavItem { dashboard, produk, penjualan }

class SidebarWidget extends StatelessWidget {
  final NavItem selectedItem;
  final ValueChanged<NavItem> onItemSelected;

  const SidebarWidget({
    super.key,
    required this.selectedItem,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo / App Name
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.storefront,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Gerai\nSerambi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),

          // Nav Items
          _NavItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            isSelected: selectedItem == NavItem.dashboard,
            onTap: () => onItemSelected(NavItem.dashboard),
          ),
          _NavItem(
            icon: Icons.inventory_2_rounded,
            label: 'Produk',
            isSelected: selectedItem == NavItem.produk,
            onTap: () => onItemSelected(NavItem.produk),
          ),
          _NavItem(
            icon: Icons.receipt_long_rounded,
            label: 'Penjualan',
            isSelected: selectedItem == NavItem.penjualan,
            onTap: () => onItemSelected(NavItem.penjualan),
          ),
          const Spacer(),
          const Divider(color: Colors.white24, height: 1),
        ],
      ),
    );  
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? iconColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.iconColor,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isSelected || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Colors.white.withOpacity(0.2)
                : _hovered
                    ? Colors.white.withOpacity(0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: widget.iconColor ??
                    (active ? Colors.white : Colors.white70),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.iconColor ??
                      (active ? Colors.white : Colors.white70),
                  fontSize: 13.5,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              if (widget.isSelected) ...[
                const Spacer(),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
