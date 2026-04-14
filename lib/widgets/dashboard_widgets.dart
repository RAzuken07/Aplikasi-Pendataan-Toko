import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// ─── Sales Summary Card ───────────────────────────────────────────────────────
class SalesSummaryCard extends StatelessWidget {
  final String totalRevenue;
  final int transactionCount;

  const SalesSummaryCard({
    super.key,
    required this.totalRevenue,
    required this.transactionCount,
  });

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan Penjualan',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 11.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Hari Ini',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            totalRevenue,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$transactionCount Transaksi',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Best Selling Products Card ───────────────────────────────────────────────
class BestSellerCard extends StatelessWidget {
  final List<Map<String, dynamic>> products;

  const BestSellerCard({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Produk Terlaris',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Belum ada penjualan',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: products.map((p) => _ProductChip(product: p)).toList(),
            ),
        ],
      ),
    );
  }
}

class _ProductChip extends StatelessWidget {
  final Map<String, dynamic> product;

  const _ProductChip({required this.product});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: (product['color'] as Color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              product['icon'] as IconData,
              color: product['color'] as Color,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product['name'] as String,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryLighter,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${product['sold'] ?? 0} Terjual',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Weekly Sales Chart Card ──────────────────────────────────────────────────
class WeeklyChartCard extends StatefulWidget {
  final List<double> values;
  final List<String> labels;
  final List<String> tooltipValues;

  const WeeklyChartCard({super.key, required this.values, required this.labels, required this.tooltipValues});

  @override
  State<WeeklyChartCard> createState() => _WeeklyChartCardState();
}

class _WeeklyChartCardState extends State<WeeklyChartCard> {
  String? _tooltipText;
  Offset? _tooltipPosition;

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grafik Penjualan Mingguan',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: MouseRegion(
              onHover: (event) {
                final index = ((event.localPosition.dx / 400) * widget.values.length).floor();
                if (index >= 0 && index < widget.tooltipValues.length) {
                  setState(() {
                    _tooltipText = widget.tooltipValues[index];
                    _tooltipPosition = event.position;
                  });
                } else {
                  setState(() {
                    _tooltipText = null;
                    _tooltipPosition = null;
                  });
                }
              },
              onExit: (_) {
                setState(() {
                  _tooltipText = null;
                  _tooltipPosition = null;
                });
              },
              child: Stack(
                children: [
                  CustomPaint(
                    painter: _SimpleChartPainter(values: widget.values, labels: widget.labels),
                    size: Size.infinite,
                  ),
                  if (_tooltipText != null && _tooltipPosition != null)
                    Positioned(
                      left: _tooltipPosition!.dx - 50,
                      top: _tooltipPosition!.dy - 40,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _tooltipText!,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: widget.labels.map((label) => Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))).toList(),
          ),
        ],
      ),
    );
  }
}

class _SimpleChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;

  _SimpleChartPainter({required this.values, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.primaryLight
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryLight.withValues(alpha: 0.35),
          AppColors.primaryLight.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = i * size.width / (values.length - 1);
      final y = size.height * (1 - values[i]);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
      } else {
        final prevX = (i - 1) * size.width / (values.length - 1);
        final prevY = size.height * (1 - values[i - 1]);
        final cp1x = prevX + (x - prevX) * 0.5;
        path.cubicTo(cp1x, prevY, cp1x, y, x, y);
        fillPath.cubicTo(cp1x, prevY, cp1x, y, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Draw dots on data points
    final dotPaint = Paint()
      ..color = AppColors.primaryLight
      ..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < values.length; i++) {
      final x = i * size.width / (values.length - 1);
      final y = size.height * (1 - values[i]);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
      canvas.drawCircle(Offset(x, y), 4, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Product Grid Card ────────────────────────────────────────────────────────
class ProductGridCard extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final ValueChanged<Map<String, dynamic>>? onProductTap;

  const ProductGridCard({super.key, required this.products, this.onProductTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'List Produk',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _ProductGridItem(product: products[index], onTap: onProductTap);
          },
        ),
      ],
    );
  }
}

class _ProductGridItem extends StatefulWidget {
  final Map<String, dynamic> product;
  final ValueChanged<Map<String, dynamic>>? onTap;

  const _ProductGridItem({required this.product, this.onTap});

  @override
  State<_ProductGridItem> createState() => _ProductGridItemState();
}

class _ProductGridItemState extends State<_ProductGridItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : AppColors.cardShadow,
              blurRadius: _hovered ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (widget.product['color'] as Color).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                widget.product['icon'] as IconData,
                color: widget.product['color'] as Color,
                size: 28,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.product['name'] as String,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              'Harga',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.product['price'] as String,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Low Stock Card ───────────────────────────────────────────────────────────
class LowStockCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const LowStockCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Daftar Stok Rendah',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _LowStockItem(item: item)),
        ],
      ),
    );
  }
}

class _LowStockItem extends StatelessWidget {
  final Map<String, dynamic> item;

  const _LowStockItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFE082), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(
              item['icon'] as IconData,
              color: Colors.orange.shade700,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${item['stock']} stok',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Rendah',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Card wrapper ────────────────────────────────────────────────────
class _DashCard extends StatelessWidget {
  final Widget child;

  const _DashCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
