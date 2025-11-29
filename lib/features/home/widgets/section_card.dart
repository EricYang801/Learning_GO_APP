import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  /// 左上角標題
  final String title;

  /// 內容區塊
  final Widget child;

  /// 右上角的小按鈕 / 圖示（例如 +、更多 …）
  final Widget? trailing;

  /// 卡片底色（用於你截圖中的淡藍、淡綠、淡橘、淡灰）
  final Color? tint;

  /// 是否讓 child 撐滿剩餘高度（放可滾動清單時很有用）
  final bool expandChild;

  /// 卡片固定高度（通常不需要）
  final double? height;

  /// 卡片外圍的間距（控制四個區塊彼此的距離）
  final EdgeInsetsGeometry outerMargin;

  /// 標題列的內距
  final EdgeInsetsGeometry headerPadding;

  /// 內容區域的內距（預設 top = 0，避免把標題往下推）
  final EdgeInsetsGeometry contentPadding;

  /// 邊角
  final BorderRadius borderRadius;

  ///（新增）標題樣式（可覆蓋預設）
  final TextStyle? titleStyle;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.tint,
    this.expandChild = false,
    this.height,
    this.outerMargin = const EdgeInsets.fromLTRB(16, 10, 16, 0),
    this.headerPadding = const EdgeInsets.fromLTRB(20, 16, 20, 6),
    this.contentPadding = const EdgeInsets.fromLTRB(20, 0, 20, 16),
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = tint ?? Colors.white;
    final header = Padding(
      padding: headerPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 預設較小一點
          Text(
            title,
            style:
                titleStyle ??
                const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );

    // 統一由 contentPadding 控制「標題與內容的距離」與左右寬度
    final content = Padding(
      padding: contentPadding,
      // 若 child 是可滾動（ListView 等），避免多一層系統 top padding
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: child,
      ),
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (expandChild) Expanded(child: content) else content,
      ],
    );

    return Container(
      height: height,
      margin: outerMargin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: borderRadius, child: body),
    );
  }
}
