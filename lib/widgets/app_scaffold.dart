import 'package:flutter/material.dart';
import '../utils/design_tokens.dart';

/// غلاف موحد للشاشات يوفر AppBar شفاف اختياري وScrollable body نمطي
class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool scrollable;
  final EdgeInsetsGeometry padding;
  final PreferredSizeWidget? bottom;

  const AppScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.scrollable = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final content = scrollable
        ? SingleChildScrollView(padding: padding, child: body)
        : Padding(padding: padding, child: body);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: title != null
            ? Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              )
            : null,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: actions,
        bottom: bottom,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(child: content),
      ),
      floatingActionButton: floatingActionButton,
      backgroundColor: AppColors.neutral50,
    );
  }
}
