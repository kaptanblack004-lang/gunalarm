import 'package:flutter/material.dart';

class SwipeActionTile extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDelete;
  final VoidCallback? onSnooze;
  final VoidCallback? onEdit;
  final Color deleteColor;
  final Color snoozeColor;
  final Color editColor;

  const SwipeActionTile({
    super.key,
    required this.child,
    this.onDelete,
    this.onSnooze,
    this.onEdit,
    this.deleteColor = Colors.red,
    this.snoozeColor = Colors.blue,
    this.editColor = Colors.green,
  });

  @override
  State<SwipeActionTile> createState() => _SwipeActionTileState();
}

class _SwipeActionTileState extends State<SwipeActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  bool _isSwipingRight = false;
  bool _isSwipingLeft = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleSwipeEnd() {
    if (_isSwipingRight && widget.onSnooze != null) {
      widget.onSnooze!();
    } else if (_isSwipingLeft && widget.onDelete != null) {
      widget.onDelete!();
    }
    
    _animationController.reverse();
    setState(() {
      _isSwipingRight = false;
      _isSwipingLeft = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final swipeThreshold = 100.0;
        
        if (details.delta.dx > swipeThreshold) {
          setState(() {
            _isSwipingRight = true;
            _isSwipingLeft = false;
          });
          _animationController.forward();
        } else if (details.delta.dx < -swipeThreshold) {
          setState(() {
            _isSwipingLeft = true;
            _isSwipingRight = false;
          });
          _animationController.forward();
        }
      },
      onPanEnd: (details) {
        _handleSwipeEnd();
      },
      child: Stack(
        children: [
          // Background actions
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.transparent,
                ),
                child: Row(
                  children: [
                    // Left side - Snooze
                    if (widget.onSnooze != null)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: widget.snoozeColor.withOpacity(_slideAnimation.value * 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.snoozeColor.withOpacity(_slideAnimation.value * 0.5),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: AnimatedOpacity(
                                  opacity: _isSwipingRight ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.snooze,
                                        color: widget.snoozeColor,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Ertele',
                                        style: TextStyle(
                                          color: widget.snoozeColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Swipe indicator
                              if (_isSwipingRight)
                                Positioned(
                                  left: 8,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      color: widget.snoozeColor,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Right side - Delete
                    if (widget.onDelete != null)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: widget.deleteColor.withOpacity(_slideAnimation.value * 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.deleteColor.withOpacity(_slideAnimation.value * 0.5),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: AnimatedOpacity(
                                  opacity: _isSwipingLeft ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        color: widget.deleteColor,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Sil',
                                        style: TextStyle(
                                          color: widget.deleteColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Swipe indicator
                              if (_isSwipingLeft)
                                Positioned(
                                  right: 8,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: Icon(
                                      Icons.arrow_back_ios,
                                      color: widget.deleteColor,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          
          // Foreground content
          AnimatedSlide(
            offset: Offset(
              _isSwipingRight ? -0.3 : (_isSwipingLeft ? 0.3 : 0.0),
              0.0,
            ),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class AdvancedSwipeActionTile extends StatefulWidget {
  final Widget child;
  final List<SwipeAction> actions;
  final double actionWidth;
  final double actionThreshold;

  const AdvancedSwipeActionTile({
    super.key,
    required this.child,
    required this.actions,
    this.actionWidth = 80.0,
    this.actionThreshold = 100.0,
  });

  @override
  State<AdvancedSwipeActionTile> createState() => _AdvancedSwipeActionTileState();
}

class _AdvancedSwipeActionTileState extends State<AdvancedSwipeActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  double _dragOffset = 0.0;
  SwipeAction? _activeAction;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
      _dragOffset = _dragOffset.clamp(-widget.actionWidth * widget.actions.length, widget.actionWidth * widget.actions.length);
      
      // Find active action based on drag offset
      _activeAction = _findActiveAction();
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_activeAction != null) {
      _activeAction!.onPressed();
    }
    
    // Reset animation
    _animationController.reverse();
    setState(() {
      _dragOffset = 0.0;
      _activeAction = null;
    });
  }

  SwipeAction? _findActiveAction() {
    if (_dragOffset.abs() < widget.actionThreshold) return null;
    
    final actionIndex = (_dragOffset.abs() / widget.actionWidth).floor();
    if (actionIndex < widget.actions.length) {
      return widget.actions[actionIndex];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Stack(
        children: [
          // Background actions
          Container(
            height: 80,
            child: Row(
              children: widget.actions.map((action) {
                final isActive = _activeAction == action;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isActive ? action.color : action.color.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            action.icon,
                            color: Colors.white,
                            size: isActive ? 28 : 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            action.label,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Foreground content
          AnimatedSlide(
            offset: Offset(_dragOffset / widget.actionWidth, 0.0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class SwipeAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  SwipeAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });
}
