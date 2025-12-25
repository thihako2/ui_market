import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/registry_pack.dart';
import '../models/studio/visual_widget.dart';

class PackCard extends StatefulWidget {
  final RegistryPack pack;
  final VoidCallback? onTap;

  const PackCard({
    super.key,
    required this.pack,
    this.onTap,
  });

  @override
  State<PackCard> createState() => _PackCardState();
}

class _PackCardState extends State<PackCard> {
  // We'll store compiled widgets here if we need to fetch them
  Map<String, List<VisualWidget>> _compiledWidgets = {};

  @override
  void initState() {
    super.initState();
    _checkAndCompileWidgets();
  }

  Future<void> _checkAndCompileWidgets() async {
    // Logic to check if widgets are missing and attempt compilation
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pack = widget.pack;

    // Ultra-detailed card with dominant preview
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dominant Virtual Preview Area
            Expanded(
              flex: 5, // Even more dominant
              child: pack.previews.isNotEmpty
                  ? _buildPreviewImage(pack.previews.first, theme)
                  : _buildVirtualPreview(theme),
            ),

            // Compact but elegant Info Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withAlpha(80),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pack.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildVersionBadge(theme),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pack.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  _buildFooter(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(50)),
      ),
      child: Text(
        'v${widget.pack.version}',
        style: TextStyle(
          fontSize: 10,
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: theme.colorScheme.primary.withAlpha(40),
          child: Text(
            widget.pack.author[0].toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.pack.author,
            style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildStatItem(Icons.phone_android_rounded,
            '${widget.pack.screens.length}', theme),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(150),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewImage(String url, ThemeData theme) {
    if (url.startsWith('data:')) {
      try {
        final base64Data = url.split(',').last;
        return Image.memory(
          base64Decode(base64Data),
          fit: BoxFit.cover,
          width: double.infinity,
        );
      } catch (e) {
        return _buildVirtualPreview(theme);
      }
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (_, __) => Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) => _buildVirtualPreview(theme),
    );
  }

  Widget _buildVirtualPreview(ThemeData theme) {
    if (widget.pack.screens.isEmpty) {
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.layers_outlined,
                  size: 48, color: theme.colorScheme.outline.withAlpha(100)),
              const SizedBox(height: 12),
              Text("NO SCREENS",
                  style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.outline)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
        image: DecorationImage(
          image: const NetworkImage(
              'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=2070&auto=format&fit=crop'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            theme.colorScheme.primaryContainer.withAlpha(200),
            BlendMode.overlay,
          ),
          opacity: 0.1,
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.pack.screens.length,
        itemBuilder: (context, index) {
          final screen = widget.pack.screens[index];
          // Use compiled widgets if available, otherwise use pre-packed
          final widgets = _compiledWidgets[screen.name] ?? screen.widgets;

          return Container(
            width: 170, // Ultra Wide for Detail
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withAlpha(40),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Full Screen Content
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          10, 24, 10, 10), // Space for status bar
                      child: _buildUltraFidelityWidgets(widgets, theme),
                    ),
                  ),

                  // Status Bar Placeholder
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("9:41",
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(150))),
                          Row(
                            children: [
                              Icon(Icons.wifi,
                                  size: 8,
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(150)),
                              const SizedBox(width: 2),
                              Icon(Icons.battery_full,
                                  size: 8,
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(150)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Glass Footer Label
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            theme.colorScheme.surface.withAlpha(230),
                          ],
                        ),
                      ),
                      child: Text(
                        screen.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUltraFidelityWidgets(
      List<VisualWidget> widgets, ThemeData theme) {
    if (widgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_customize_outlined,
                size: 32, color: theme.colorScheme.primary.withAlpha(50)),
            const SizedBox(height: 8),
            Text("NO WIDGETS",
                style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary.withAlpha(80))),
          ],
        ),
      );
    }

    // Reference screen size 375x812
    return LayoutBuilder(builder: (context, constraints) {
      final scaleX = constraints.maxWidth / 375;
      final scaleY = constraints.maxHeight / 812;

      return Stack(
        children: widgets.take(50).map((w) {
          final x = w.x * scaleX;
          final y = w.y * scaleY;
          final width = w.width * scaleX;
          final height = w.height * scaleY;

          Widget child;
          final props = w.properties;

          final bgColor = _safeColor(props['color'], theme.colorScheme.primary);
          final textColor =
              _safeColor(props['textColor'], theme.colorScheme.onSurface);

          switch (w.type) {
            case VisualWidgetType.text:
              child = Text(
                props['text'] ?? 'Title',
                style: TextStyle(
                  fontSize: ((props['fontSize'] ?? 16.0) as num).toDouble() *
                      scaleX *
                      1.8, // Slight boost for visibility
                  color:
                      _safeColor(props['color'], theme.colorScheme.onSurface),
                  fontWeight: props['fontWeight'] == 'bold'
                      ? FontWeight.w900
                      : FontWeight.w500,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              );
              break;
            case VisualWidgetType.button:
            case VisualWidgetType.cupertinoButton:
              child = Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(
                      ((props['borderRadius'] ?? 12.0) as num).toDouble() *
                          scaleX),
                  boxShadow: [
                    BoxShadow(
                        color: bgColor.withAlpha(100),
                        blurRadius: 4,
                        offset: const Offset(0, 2)),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  props['text'] ?? 'ACTION',
                  style: TextStyle(
                    fontSize: 10 * scaleX,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              );
              break;
            case VisualWidgetType.image:
              child = Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12 * scaleX),
                  image: const DecorationImage(
                    image: NetworkImage('https://picsum.photos/200'),
                    fit: BoxFit.cover,
                    opacity: 0.8,
                  ),
                ),
                child: Center(
                    child: Icon(Icons.image_rounded,
                        size: 24 * scaleX, color: Colors.white70)),
              );
              break;
            case VisualWidgetType.container:
            case VisualWidgetType.card:
              child = Container(
                decoration: BoxDecoration(
                  color: bgColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(
                      ((props['borderRadius'] ?? 12.0) as num).toDouble() *
                          scaleX),
                  border: Border.all(color: bgColor.withAlpha(80), width: 1),
                ),
              );
              break;
            case VisualWidgetType.appBar:
              child = Container(
                color: theme.colorScheme.primary,
                child: Row(
                  children: [
                    SizedBox(width: 16 * scaleX),
                    Icon(Icons.arrow_back,
                        color: Colors.white, size: 16 * scaleX),
                    SizedBox(width: 16 * scaleX),
                    Text(props['title'] ?? "UI SCREEN",
                        style: TextStyle(
                            fontSize: 14 * scaleX,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              );
              break;
            case VisualWidgetType.icon:
              child = Icon(
                _getIconData(props['icon']),
                size: ((props['size'] ?? 24.0) as num).toDouble() * scaleX,
                color: bgColor,
              );
              break;
            case VisualWidgetType.listTile:
              child = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: theme.colorScheme.outlineVariant, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24 * scaleX,
                      height: 24 * scaleX,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person,
                          size: 14 * scaleX, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 6 * scaleY,
                          width: 60 * scaleX,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withAlpha(200),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(height: 4 * scaleY),
                        Container(
                          height: 4 * scaleY,
                          width: 40 * scaleX,
                          color: theme.colorScheme.outline,
                        ),
                      ],
                    )
                  ],
                ),
              );
              break;
            case VisualWidgetType.floatingActionButton:
              child = Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: theme.colorScheme.primary.withAlpha(100),
                        blurRadius: 8,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Icon(Icons.add, color: Colors.white, size: 24 * scaleX),
              );
              break;
            default:
              // For layout widgets or unknown, show a subtle outline/box if it has dimensions
              if (width > 0 && height > 0) {
                child = Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(5),
                    borderRadius: BorderRadius.circular(4 * scaleX),
                    border: Border.all(
                        color: theme.colorScheme.primary.withAlpha(10),
                        width: 0.5),
                  ),
                );
              } else {
                child = const SizedBox.shrink();
              }
          }

          return Positioned(
            left: x,
            top: y,
            width: width,
            height: height,
            child: child,
          );
        }).toList(),
      );
    });
  }

  Color _safeColor(dynamic value, Color defaultColor) {
    if (value is int) {
      return Color(value);
    }
    if (value is String) {
      try {
        String hex = value.replaceAll('#', '');
        if (hex.length == 6) {
          hex = 'FF$hex';
        }
        if (hex.length == 8) {
          return Color(int.parse('0x$hex'));
        }
      } catch (_) {}
    }
    return defaultColor;
  }

  IconData _getIconData(dynamic iconName) {
    // A simple mapping or fallback
    return Icons.auto_awesome;
  }
}
