import 'package:flutter/material.dart';
import '../utils/enhanced_design_tokens.dart';

/// شريط تنقل سفلي محسن بتصميم حديث ومرن
class EnhancedBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<EnhancedBottomNavItem> items;

  const EnhancedBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(EnhancedRadius.xl),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: EnhancedAppColors.primary,
          unselectedItemColor: EnhancedAppColors.gray400,
          selectedLabelStyle: const TextStyle(
            fontSize: EnhancedTypography.labelMedium,
            fontWeight: EnhancedTypography.semiBold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: EnhancedTypography.labelSmall,
            fontWeight: EnhancedTypography.regular,
          ),
          items: items.map((item) => _buildBottomNavItem(item)).toList(),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem(EnhancedBottomNavItem item) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(EnhancedSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(EnhancedRadius.md),
        ),
        child: Icon(item.icon, size: 24),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.all(EnhancedSpacing.sm),
        decoration: BoxDecoration(
          color: EnhancedAppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(EnhancedRadius.md),
        ),
        child: Icon(item.activeIcon ?? item.icon, size: 24),
      ),
      label: item.label,
    );
  }
}

class EnhancedBottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Color? color;

  const EnhancedBottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.color,
  });
}

/// زر عائم متعدد الإجراءات مع تأثيرات بصرية حديثة
class EnhancedFloatingActionButton extends StatefulWidget {
  final List<FloatingAction> actions;
  final IconData mainIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const EnhancedFloatingActionButton({
    super.key,
    required this.actions,
    this.mainIcon = Icons.add,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<EnhancedFloatingActionButton> createState() =>
      _EnhancedFloatingActionButtonState();
}

class _EnhancedFloatingActionButtonState
    extends State<EnhancedFloatingActionButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: EnhancedAnimations.normal,
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.75, // 270 degrees rotation
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // خلفية الظلال عند التوسع
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleExpansion,
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),
        
        // الأزرار الفرعية
        ...widget.actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          return _buildSubActionButton(action, index);
        }),
        
        // الزر الرئيسي
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return FloatingActionButton(
              onPressed: _toggleExpansion,
              backgroundColor: widget.backgroundColor ?? EnhancedAppColors.primary,
              foregroundColor: widget.foregroundColor ?? Colors.white,
              elevation: _isExpanded ? 8 : 4,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159,
                child: Icon(
                  _isExpanded ? Icons.close : widget.mainIcon,
                  size: 24,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubActionButton(FloatingAction action, int index) {
    final double bottomOffset = 80.0 + (index * 70.0);
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Positioned(
          bottom: bottomOffset,
          right: 8,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // تسمية الإجراء
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EnhancedSpacing.md,
                    vertical: EnhancedSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(EnhancedRadius.md),
                    boxShadow: EnhancedShadows.soft,
                  ),
                  child: Text(
                    action.label,
                    style: const TextStyle(
                      fontSize: EnhancedTypography.bodySmall,
                      fontWeight: EnhancedTypography.medium,
                      color: EnhancedAppColors.gray700,
                    ),
                  ),
                ),
                
                const SizedBox(width: EnhancedSpacing.sm),
                
                // زر الإجراء
                FloatingActionButton.small(
                  onPressed: () {
                    _toggleExpansion();
                    action.onPressed();
                  },
                  backgroundColor: action.backgroundColor ?? EnhancedAppColors.secondary,
                  foregroundColor: Colors.white,
                  heroTag: 'fab_${index}',
                  child: Icon(action.icon, size: 20),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FloatingAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  const FloatingAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
  });
}

/// شريط بحث محسن مع اقتراحات تفاعلية
class EnhancedSearchBar extends StatefulWidget {
  final String? hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onFilter;
  final List<String> suggestions;
  final bool showSuggestions;

  const EnhancedSearchBar({
    super.key,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onFilter,
    this.suggestions = const [],
    this.showSuggestions = false,
  });

  @override
  State<EnhancedSearchBar> createState() => _EnhancedSearchBarState();
}

class _EnhancedSearchBarState extends State<EnhancedSearchBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isFocused = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _animationController = AnimationController(
      duration: EnhancedAnimations.normal,
      vsync: this,
    );
    _expandAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
      _showSuggestions = _isFocused && widget.suggestions.isNotEmpty;
    });
    
    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _expandAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(EnhancedSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(EnhancedRadius.xl),
                  boxShadow: _isFocused 
                      ? EnhancedShadows.glow 
                      : EnhancedShadows.soft,
                  border: Border.all(
                    color: _isFocused 
                        ? EnhancedAppColors.primary 
                        : EnhancedAppColors.gray200,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    // أيقونة البحث
                    Padding(
                      padding: const EdgeInsets.all(EnhancedSpacing.lg),
                      child: Icon(
                        Icons.search,
                        color: _isFocused 
                            ? EnhancedAppColors.primary 
                            : EnhancedAppColors.gray400,
                        size: 24,
                      ),
                    ),
                    
                    // حقل النص
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: const TextStyle(
                          fontSize: EnhancedTypography.bodyMedium,
                          color: EnhancedAppColors.gray800,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.hintText ?? 'ابحث عن كتاب، مؤلف، أو فئة...',
                          hintStyle: const TextStyle(
                            color: EnhancedAppColors.gray400,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          widget.onChanged?.call(value);
                          setState(() {
                            _showSuggestions = value.isNotEmpty && 
                                widget.suggestions.isNotEmpty;
                          });
                        },
                        onSubmitted: widget.onSubmitted,
                      ),
                    ),
                    
                    // زر التصفية
                    if (widget.onFilter != null)
                      Padding(
                        padding: const EdgeInsets.all(EnhancedSpacing.sm),
                        child: IconButton(
                          onPressed: widget.onFilter,
                          icon: Icon(
                            Icons.tune,
                            color: EnhancedAppColors.gray400,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        
        // قائمة الاقتراحات
        if (_showSuggestions && widget.showSuggestions)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: EnhancedSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(EnhancedRadius.lg),
              boxShadow: EnhancedShadows.medium,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = widget.suggestions[index];
                return ListTile(
                  leading: Icon(
                    Icons.history,
                    color: EnhancedAppColors.gray400,
                    size: 20,
                  ),
                  title: Text(
                    suggestion,
                    style: const TextStyle(
                      fontSize: EnhancedTypography.bodyMedium,
                      color: EnhancedAppColors.gray700,
                    ),
                  ),
                  onTap: () {
                    _controller.text = suggestion;
                    widget.onSubmitted?.call(suggestion);
                    _focusNode.unfocus();
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

/// كارت إشعار تفاعلي
class EnhancedNotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final bool showDismiss;

  const EnhancedNotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.backgroundColor,
    this.iconColor,
    this.onTap,
    this.onDismiss,
    this.showDismiss = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(EnhancedSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor ?? EnhancedAppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(EnhancedRadius.lg),
        border: Border.all(
          color: (iconColor ?? EnhancedAppColors.info).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(EnhancedRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(EnhancedSpacing.lg),
            child: Row(
              children: [
                // أيقونة الإشعار
                Container(
                  padding: const EdgeInsets.all(EnhancedSpacing.sm),
                  decoration: BoxDecoration(
                    color: iconColor ?? EnhancedAppColors.info,
                    borderRadius: BorderRadius.circular(EnhancedRadius.sm),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: EnhancedSpacing.lg),
                
                // محتوى الإشعار
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: EnhancedTypography.titleMedium,
                          fontWeight: EnhancedTypography.semiBold,
                          color: EnhancedAppColors.gray800,
                        ),
                      ),
                      
                      const SizedBox(height: EnhancedSpacing.xs),
                      
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: EnhancedTypography.bodySmall,
                          color: EnhancedAppColors.gray600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // زر الإغلاق
                if (showDismiss && onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.close,
                      color: EnhancedAppColors.gray400,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
