import 'dart:math' as math;

import 'package:fab_dracailles/core/data/fab_heroes.dart';
import 'package:fab_dracailles/core/utils/localization_util.dart';
import 'package:flutter/material.dart';

/// Full screen (pushed via Navigator, never a stacked dialog) letting the
/// player pick either a flat color or a hero to represent them. Picking
/// either calls the matching callback then pops back to the caller.
class HeroColorPickerScreen extends StatefulWidget {
  final List<Color> colors;
  final void Function(Color color) onColorSelected;
  final void Function(FabHero hero, bool isYoung) onHeroSelected;
  // Opens on the hero tab when the player already has one picked, and on
  // the color tab otherwise, since that's the tab they're most likely here
  // to change. Same idea for the Adult/Young segment, when they do have a
  // hero.
  final bool startOnHeroTab;
  final bool startOnYoung;
  // True when opened from the top player's (rotated) side of the match
  // screen, so this screen renders upside down too and reads right-side up
  // for them - same idea as LifeTrackerWidget's own invertMode.
  final bool inverted;

  const HeroColorPickerScreen({
    super.key,
    required this.colors,
    required this.onColorSelected,
    required this.onHeroSelected,
    this.startOnHeroTab = false,
    this.startOnYoung = false,
    this.inverted = false,
  });

  @override
  State<HeroColorPickerScreen> createState() => _HeroColorPickerScreenState();
}

class _HeroColorPickerScreenState extends State<HeroColorPickerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late bool _showYoung;

  @override
  void initState() {
    super.initState();
    _showYoung = widget.startOnYoung;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.startOnHeroTab ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: widget.inverted ? math.pi : 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.translate('player.chooseAppearance'),
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
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildColorGrid(context),
                  _buildHeroPicker(context),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'Flesh and Blood™ is a registered trademark of Legend Story '
                'Studios. Flesh and Blood™ and all associated images are '
                'copyright © Legend Story Studios. All rights reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
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
      // Multi-class heroes show up once per class they belong to.
      for (final heroClass in hero.heroClasses) {
        byClass.putIfAbsent(heroClass, () => []).add(hero);
      }
    }
    // FabHeroClass's declaration order is the intended display order, not
    // whichever order a class is first met while scanning heroes above.
    // Sorted by class, but not split into per-class sections below - one
    // continuous grid, classes just follow each other in it. Living Legend
    // heroes are pulled out into their own section below instead - that's
    // a format-legality status, not a class, so grouping them in with the
    // rest wouldn't mean anything.
    final orderedClasses =
        FabHeroClass.values.where(byClass.containsKey).toList();
    final heroesInOrder =
        orderedClasses.expand((heroClass) => byClass[heroClass]!).toList();
    final livingLegendHeroes =
        heroesInOrder.where((hero) => hero.isLivingLegend).toList();
    final regularHeroes =
        heroesInOrder.where((hero) => !hero.isLivingLegend).toList();

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
          child: heroesInOrder.isEmpty
              ? Center(
                  child: Text(
                    context.translate('player.noHeroes'),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : LayoutBuilder(builder: (context, constraints) {
                  const horizontalPadding = 20.0;
                  const spacing = 12.0;
                  // The bubble shrinks to keep at least 4 columns on any
                  // screen, rather than keeping a fixed bubble size and
                  // wrapping down to 3 (or fewer) on a narrow phone.
                  const idealCellWidth = 84.0;
                  final availableWidth =
                      constraints.maxWidth - horizontalPadding * 2;
                  final crossAxisCount = math.max(
                      4, (availableWidth / idealCellWidth).floor());
                  final cellWidth =
                      (availableWidth - spacing * (crossAxisCount - 1)) /
                          crossAxisCount;
                  final avatarRadius = (cellWidth / 2).clamp(18.0, 28.0);
                  return ListView(
                    padding: const EdgeInsets.all(horizontalPadding),
                    children: [
                      if (regularHeroes.isNotEmpty)
                        _buildHeroGrid(
                          regularHeroes,
                          crossAxisCount: crossAxisCount,
                          spacing: spacing,
                          avatarRadius: avatarRadius,
                        ),
                      if (livingLegendHeroes.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          context.translate('player.livingLegend'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        _buildHeroGrid(
                          livingLegendHeroes,
                          crossAxisCount: crossAxisCount,
                          spacing: spacing,
                          avatarRadius: avatarRadius,
                        ),
                      ],
                    ],
                  );
                }),
        ),
      ],
    );
  }

  Widget _buildHeroGrid(
    List<FabHero> heroes, {
    required int crossAxisCount,
    required double spacing,
    required double avatarRadius,
  }) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        mainAxisExtent: avatarRadius * 2 + 36,
      ),
      itemCount: heroes.length,
      itemBuilder: (context, index) {
        final hero = heroes[index];
        return GestureDetector(
          onTap: () {
            widget.onHeroSelected(hero, _showYoung);
            Navigator.of(context).pop();
          },
          child: Column(
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Colors.grey[300],
                backgroundImage: AssetImage(hero.thumbnailPath),
                onBackgroundImageError: (exception, stackTrace) {},
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
        );
      },
    );
  }
}
