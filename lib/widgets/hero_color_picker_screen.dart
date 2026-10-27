import 'package:fab_dracailles/core/data/fab_heroes.dart';
import 'package:fab_dracailles/core/utils/localization_util.dart';
import 'package:flutter/material.dart';

/// Full screen (pushed via Navigator, never a stacked dialog) letting the
/// player pick either a flat color or a hero to represent them. Picking
/// either calls the matching callback then pops back to the caller.
class HeroColorPickerScreen extends StatefulWidget {
  final String playerLabel;
  final List<Color> colors;
  final void Function(Color color) onColorSelected;
  final void Function(FabHero hero, bool isYoung) onHeroSelected;

  const HeroColorPickerScreen({
    super.key,
    required this.playerLabel,
    required this.colors,
    required this.onColorSelected,
    required this.onHeroSelected,
  });

  @override
  State<HeroColorPickerScreen> createState() => _HeroColorPickerScreenState();
}

class _HeroColorPickerScreenState extends State<HeroColorPickerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _showYoung = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.playerLabel,
          style: const TextStyle(color: Colors.white),
        ),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: context.translate('player.color')),
            Tab(text: context.translate('player.hero')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildColorGrid(context),
          _buildHeroPicker(context),
        ],
      ),
    );
  }

  Widget _buildColorGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 72,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: widget.colors.length,
      itemBuilder: (context, index) {
        final color = widget.colors[index];
        return GestureDetector(
          onTap: () {
            widget.onColorSelected(color);
            Navigator.of(context).pop();
          },
          child: CircleAvatar(radius: 28, backgroundColor: color),
        );
      },
    );
  }

  Widget _buildHeroPicker(BuildContext context) {
    final heroes = _showYoung ? fabHeroesYoung : fabHeroesAdult;
    final byClass = <FabHeroClass, List<FabHero>>{};
    for (final hero in heroes) {
      // Multi-class heroes show up under each of their classes.
      for (final heroClass in hero.heroClasses) {
        byClass.putIfAbsent(heroClass, () => []).add(hero);
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                label: Text(context.translate('player.heroAdult')),
              ),
              ButtonSegment(
                value: true,
                label: Text(context.translate('player.heroYoung')),
              ),
            ],
            selected: {_showYoung},
            onSelectionChanged: (selection) =>
                setState(() => _showYoung = selection.first),
          ),
        ),
        Expanded(
          child: byClass.isEmpty
              ? Center(
                  child: Text(
                    context.translate('player.noHeroes'),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: byClass.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key.displayName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: entry.value.map((hero) {
                              return GestureDetector(
                                onTap: () {
                                  widget.onHeroSelected(hero, _showYoung);
                                  Navigator.of(context).pop();
                                },
                                child: SizedBox(
                                  width: 72,
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: Colors.grey[300],
                                        backgroundImage:
                                            AssetImage(hero.thumbnailPath),
                                        onBackgroundImageError:
                                            (exception, stackTrace) {},
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        hero.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
