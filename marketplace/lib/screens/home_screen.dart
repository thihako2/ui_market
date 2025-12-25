import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/registry_pack.dart';
import '../services/registry_service.dart';
import '../widgets/pack_card.dart';
import 'pack_detail_screen.dart';
import 'studio/studio_home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _registryService = RegistryService();
  final _searchController = TextEditingController();

  List<RegistryPack> _packs = [];
  List<RegistryPack> _filteredPacks = [];
  List<String> _tags = [];
  String? _selectedTag;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    RegistryService.packsNotifier.addListener(_onPacksChanged);
    _loadPacks();
  }

  void _onPacksChanged() {
    if (mounted) {
      setState(() {
        _packs = RegistryService.packsNotifier.value;
      });
      _filterPacks();
    }
  }

  @override
  void dispose() {
    RegistryService.packsNotifier.removeListener(_onPacksChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPacks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final packs = await _registryService.fetchPacks();
      final tags = await _registryService.getTags();

      setState(() {
        _packs = packs;
        _filteredPacks = packs;
        _tags = tags;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterPacks() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredPacks = _packs.where((pack) {
        final matchesSearch = query.isEmpty ||
            pack.name.toLowerCase().contains(query) ||
            pack.description.toLowerCase().contains(query);

        final matchesTag =
            _selectedTag == null || pack.tags.contains(_selectedTag);

        return matchesSearch && matchesTag;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.widgets_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Flutter UI Marketplace',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Beautiful UI packs for your Flutter apps',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const StudioHomeScreen()),
                                );
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Creator Studio'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: _loadPacks,
                              icon: const Icon(Icons.refresh,
                                  color: Colors.white),
                              tooltip: 'Refresh Registry',
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _filterPacks(),
                decoration: InputDecoration(
                  hintText: 'Search UI packs...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // Tags
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildTagChip(null, 'All'),
                  ..._tags.map((tag) => _buildTagChip(tag, tag)),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64),
                    const SizedBox(height: 16),
                    Text('Failed to load packs'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadPacks,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_filteredPacks.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No packs found',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try a different search or tag',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final pack = _filteredPacks[index];
                    return PackCard(
                      pack: pack,
                      onTap: () => _openPackDetail(pack),
                    );
                  },
                  childCount: _filteredPacks.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudioHomeScreen()),
          );
        },
        icon: const Icon(Icons.edit),
        label: const Text('Creator Studio'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildTagChip(String? tag, String label) {
    final isSelected = _selectedTag == tag;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedTag = tag);
          _filterPacks();
        },
        selectedColor: theme.colorScheme.primaryContainer,
        checkmarkColor: theme.colorScheme.primary,
      ),
    );
  }

  void _openPackDetail(RegistryPack pack) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PackDetailScreen(pack: pack),
      ),
    );
  }
}
