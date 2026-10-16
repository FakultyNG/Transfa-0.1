import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/assets.dart';

/// Scaffold for "modal sheet" surfaces that hover above the home wallpaper.
/// Used by the entire identity, CashDrop, wallet, add-money cluster — these
/// are routes (so go_router back works) but render with the wallpaper photo
/// behind, dimmed/blurred to surface the floating glass cards.
///
/// Optional features:
/// - [sheetHandle] — top pill grabber (face-scan, CashDrop scan).
/// - [swipeDownToDismiss] — quick gesture to pop the route.
/// - [contentAlignment] — where to anchor body within the available space.
class ModalScaffold extends StatelessWidget {
  final Widget child;
  final bool sheetHandle;
  final bool swipeDownToDismiss;
  final AlignmentGeometry contentAlignment;
  final double horizontalPadding;
  final double darken;
  final double blurSigma;

  const ModalScaffold({
    super.key,
    required this.child,
    this.sheetHandle = false,
    this.swipeDownToDismiss = true,
    this.contentAlignment = Alignment.center,
    this.horizontalPadding = 20,
    this.darken = 0.45,
    this.blurSigma = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _Wallpaper(),
            // BackdropFilter(
            //   filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            //   child: Container(color: Colors.black.withValues(alpha: darken)),
            // ),
            SafeArea(
              child: GestureDetector(
                onVerticalDragEnd: (d) {
                  if (swipeDownToDismiss && (d.primaryVelocity ?? 0) > 250) {
                    if (context.canPop()) context.pop();
                  }
                },
                behavior: HitTestBehavior.translucent,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    children: [
                      if (sheetHandle) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                      Expanded(
                        child: Align(
                          alignment: contentAlignment,
                          child: TapRegion(
                            key: const Key('modal-background-dismiss'),
                            onTapOutside: (_) {
                              if (context.canPop()) context.pop();
                            },
                            child: child,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wallpaper extends StatelessWidget {
  const _Wallpaper();

  @override
  Widget build(BuildContext context) {
    return Image.asset(Assets.wallpaper, fit: BoxFit.cover);
  }
}
