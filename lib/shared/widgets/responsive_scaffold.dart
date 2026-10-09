import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

class ResponsiveScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  const ResponsiveScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final isMobile = responsive.isMobile;

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              centerTitle: true,
              elevation: 0,
              actions: actions,
              toolbarHeight: isMobile ? 56 : 64,
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 40,
            vertical: isMobile ? 16 : 24,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // For tablets and larger screens, use max width
              if (!isMobile) {
                return Center(child: SizedBox(width: 600, child: body));
              }
              return body;
            },
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
