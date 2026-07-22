import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/colors.dart';
import '../models/wallet.dart';
import '../utils/formatters.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final List<Color>? gradient;
  final double blurIntensity;
  final double opacity;
  final List<BoxShadow>? boxShadow;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 24,
    this.gradient,
    this.blurIntensity = 20,
    this.opacity = 0.7,
    this.boxShadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurIntensity,
            sigmaY: blurIntensity,
          ),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: gradient != null
                  ? LinearGradient(
                      colors: gradient!,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: opacity),
                        Colors.white.withValues(alpha: opacity * 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ??
                  Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1,
                  ),
              boxShadow: boxShadow ??
                  [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GlassWalletCard extends StatefulWidget {
  final String balance;
  final List<Wallet> sources;
  final String currency;
  final VoidCallback? onTap;

  const GlassWalletCard({
    super.key,
    required this.balance,
    required this.sources,
    this.currency = 'MMK',
    this.onTap,
  });

  @override
  State<GlassWalletCard> createState() => _GlassWalletCardState();
}

class _GlassWalletCardState extends State<GlassWalletCard> {
  late List<_StackEntry> _stack;

  @override
  void initState() {
    super.initState();
    _initStack();
  }

  void _initStack() {
    _stack = widget.sources
        .asMap()
        .entries
        .map((e) => _StackEntry(
              id: e.key,
              wallet: e.value,
              currency: widget.currency,
              onTap: widget.onTap,
            ))
        .toList();
  }

  @override
  void didUpdateWidget(GlassWalletCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sources != widget.sources) {
      _initStack();
    }
  }

  void _sendToBack(int id) {
    setState(() {
      final idx = _stack.indexWhere((e) => e.id == id);
      if (idx < 0) return;
      final entry = _stack.removeAt(idx);
      _stack.insert(0, entry);
    });
  }

  void _bringToFront(int id) {
    setState(() {
      final idx = _stack.indexWhere((e) => e.id == id);
      if (idx < 0 || idx == _stack.length - 1) return;
      final entry = _stack.removeAt(idx);
      _stack.add(entry);
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallets = widget.sources;

    if (wallets.isEmpty) {
      return GestureDetector(
        onTap: widget.onTap,
        child: AspectRatio(
          aspectRatio: 85 / 54,
          child: _buildTotalBalanceCard(),
        ),
      );
    }

    final fmt = NumberFormat.currency(symbol: '', decimalDigits: 0);
    final totalBalance = wallets.fold<double>(0, (s, w) => s + w.balance);
    
    final maxVisible = widget.sources.length.clamp(0, 10);
    final totalTopOffset = (maxVisible - 1) * 16.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Total balance header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F7FFF), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F7FFF).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${fmt.format(totalBalance)} ${widget.currency}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 1),

        // Card stack layer
        SizedBox(
          height: (MediaQuery.of(context).size.width - 32) * (54 / 85) + totalTopOffset,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < _stack.length; i++)
                _buildStackedCard(i, totalTopOffset),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalBalanceCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F7FFF).withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: const Color(0xFFA855F7).withValues(alpha: 0.15),
            blurRadius: 50,
            offset: const Offset(0, 30),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            _CardBase(),
            _CardBorder(),
            _CardGlow(),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MY WALLET',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.balance,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.wallet_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStackedCard(int index, double topMarginOffset) {
    final entry = _stack[index];
    final isFront = index == _stack.length - 1;
    final stackDepth = _stack.length - 1 - index;
    final maxVisible = widget.sources.length.clamp(0, 10);

    if (stackDepth >= maxVisible) return const SizedBox.shrink();

    final topShift = topMarginOffset - (stackDepth * 14.0);
    final horizontalShift = stackDepth * 6.0;
    final cardScale = 1.0 - stackDepth * 0.02;
    final cardRotate = stackDepth * -1.2;

    return Positioned(
      left: 0,
      right: 0,
      top: topShift,
      child: GestureDetector(
        onTap: isFront
            ? null
            : () {
                _bringToFront(entry.id);
              },
        child: _CardStackLayer(
          wallet: entry.wallet,
          currency: entry.currency,
          isFront: isFront,
          verticalOffset: 0,
          horizontalOffset: horizontalShift,
          scale: cardScale,
          rotation: cardRotate,
          onSwipeUp: isFront ? () => _sendToBack(entry.id) : null,
          onTap: entry.onTap,
        ),
      ),
    );
  }
}

class _StackEntry {
  final int id;
  final Wallet wallet;
  final String currency;
  final VoidCallback? onTap;

  _StackEntry({
    required this.id,
    required this.wallet,
    required this.currency,
    this.onTap,
  });
}

class _CardStackLayer extends StatefulWidget {
  final Wallet wallet;
  final String currency;
  final bool isFront;
  final double verticalOffset;
  final double horizontalOffset;
  final double scale;
  final double rotation;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onTap;

  const _CardStackLayer({
    required this.wallet,
    required this.currency,
    required this.isFront,
    required this.verticalOffset,
    this.horizontalOffset = 0,
    required this.scale,
    this.rotation = 0,
    this.onSwipeUp,
    this.onTap,
  });

  @override
  State<_CardStackLayer> createState() => _CardStackLayerState();
}

class _CardStackLayerState extends State<_CardStackLayer>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  double _dragRotate = 0;
  late AnimationController _springController;
  late Animation<double> _springAnim;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _springAnim = CurvedAnimation(
      parent: _springController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _animateBack() {
    _springController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '', decimalDigits: 0);
    final icon = WalletHelper.iconFor(widget.wallet.name);
    final baseColor = WalletHelper.colorFor(widget.wallet.name);

    final hsl = HSLColor.fromColor(baseColor);
    final lighter = hsl.withLightness((hsl.lightness + 0.18).clamp(0, 1)).toColor();
    final darker = hsl.withLightness((hsl.lightness - 0.3).clamp(0, 1)).toColor();

    final baseOffset = widget.verticalOffset + _dragOffset;
    final offset = baseOffset * (1 - _springAnim.value * 0.3);
    final baseRot = widget.rotation * 3.14159 / 180;
    final dragRot = _dragRotate * 3.14159 / 180;
    final rot = (baseRot + dragRot) * (1 - _springAnim.value * 0.5);

    return GestureDetector(
      onVerticalDragUpdate: widget.isFront
          ? (details) {
              setState(() {
                _dragOffset = (details.delta.dy * 0.7).clamp(0, 180) + _dragOffset;
                _dragRotate = (_dragOffset / 180 * 8).clamp(0, 8);
              });
            }
          : null,
      onVerticalDragEnd: widget.isFront
          ? (details) {
              if (_dragOffset > 70 && widget.onSwipeUp != null) {
                widget.onSwipeUp!();
              }
              setState(() {
                _dragOffset = 0;
                _dragRotate = 0;
              });
              _animateBack();
            }
          : null,
      child: AnimatedBuilder(
        animation: _springAnim,
        builder: (context, child) {
          return Transform(
            transform: Matrix4.identity()
              ..setTranslationRaw(widget.horizontalOffset, offset, 0.0)
              ..setEntry(0, 0, widget.scale)
              ..setEntry(1, 1, widget.scale)
              ..setEntry(2, 2, widget.scale)
              ..rotateZ(rot),
            alignment: Alignment.bottomCenter,
            child: child,
          );
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AspectRatio(
            aspectRatio: 85 / 54,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: widget.isFront
                    ? [
                        BoxShadow(
                          color: baseColor.withValues(alpha: 0.4),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [lighter, baseColor, darker],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: widget.isFront ? 0.25 : 0.1),
                            width: widget.isFront ? 1.5 : 1.0,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: widget.isFront ? 0.0 : 0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(icon, color: Colors.white, size: 12),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.wallet.name,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: widget.isFront ? 0.95 : 0.85),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${fmt.format(widget.wallet.balance)} ${widget.currency}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: widget.isFront ? 1.0 : 0.0),
                                fontSize: widget.isFront ? 24 : 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.isFront) ...[
                              const SizedBox(height: 2),
                              Text(
                                'BALANCE',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBase extends StatefulWidget {
  @override
  State<_CardBase> createState() => _CardBaseState();
}

class _CardBaseState extends State<_CardBase>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _anim = Tween<double>(begin: -0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4F7FFF),
                  Color(0xFF6C63FF),
                  Color(0xFF8B5CF6),
                  Color(0xFFA855F7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _anim,
            builder: (context, child) {
              return Positioned(
                left: (_anim.value * 300).toDouble(),
                top: 0,
                width: 80,
                height: 200,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CardBorder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(1.5),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26.5),
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: const Alignment(0.3, 0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardGlow extends StatefulWidget {
  @override
  State<_CardGlow> createState() => _CardGlowState();
}

class _CardGlowState extends State<_CardGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Positioned(
          top: -50 + (1 - _anim.value) * 20,
          right: -40 + (1 - _anim.value) * 15,
          child: Container(
            width: 160 * _anim.value,
            height: 160 * _anim.value,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.25 * _anim.value),
                  Colors.white.withValues(alpha: 0.05 * _anim.value),
                  Colors.transparent,
                ],
                radius: 0.8,
              ),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}