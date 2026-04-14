import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TopBarWidget extends StatelessWidget {
  final String pageTitle;

  const TopBarWidget({
    super.key,
    this.pageTitle = 'Dashboard',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: AppColors.bgTopbar,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Page title breadcrumb
          Row(
            children: [
              const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                pageTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
//             AnimatedContainer(
//               duration: const Duration(milliseconds: 150),
//               width: 36,
//               height: 36,
//               decoration: BoxDecoration(
//                 color: _hovered
//                     ? AppColors.primaryLighter
//                     : const Color(0xFFF0F0F0),
//                 shape: BoxShape.circle,
//               ),
//               alignment: Alignment.center,
//               child: Icon(
//                 widget.icon,
//                 size: 19,
//                 color: _hovered ? AppColors.primary : AppColors.textSecondary,
//               ),
//             ),
//             if (widget.badgeCount > 0)
//               Positioned(
//                 top: 1,
//                 right: 1,
//                 child: Container(
//                   width: 15,
//                   height: 15,
//                   decoration: const BoxDecoration(
//                     color: AppColors.accentRed,
//                     shape: BoxShape.circle,
//                   ),
//                   alignment: Alignment.center,
//                   child: Text(
//                     '${widget.badgeCount}',
//                     style: const TextStyle(
//                       color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
