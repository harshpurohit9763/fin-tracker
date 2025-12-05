import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onIconTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onIconTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final lightShadow = Color.lerp(backgroundColor, Colors.white, 0.1)!;
    final darkShadow = Color.lerp(backgroundColor, Colors.black, 0.1)!;

    return Container(
      height: 150.h,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: darkShadow,
            blurRadius: 10.r,
            offset: Offset(5.w, 5.h),
          ),
          BoxShadow(
            color: lightShadow,
            blurRadius: 10.r,
            offset: Offset(-5.w, -5.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(icon, color: color, size: 24.sp),
              ),
              if (onIconTap != null)
                InkWell(
                  onTap: onIconTap,
                  child: Icon(
                    Icons.more_horiz,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 6.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
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
