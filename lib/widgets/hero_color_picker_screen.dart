import 'dart:math' as math;

import 'package:fab_dracailles/core/data/fab_heroes.dart';
import 'package:fab_dracailles/core/utils/localization_util.dart';
import 'package:fab_dracailles/theme/fantasy_theme.dart';
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
    // The hero grid below sizes each cell to a fixed height (avatar + a
    // 2-line caption) - a boosted system/accessibility text scale factor
    // was inflating that caption past what the cell left room for and
    // overflowing. Capping it here (rather than disabling it) keeps larger
    // text genuinely larger, just not enough to break this fixed-height
    // grid or push the app bar title past the available width.
    final clampedTextScaler =
        MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: clampedTextScaler),
      child: Transform.rotate(
        angle: widget.inverted ? math.pi : 0,
        child: Scaffold(
          backgroundColor: FantasyPalette.obsidian,
          appBar: AppBar(
            backgroundColor: FantasyPalette.obsidianLight,
            surfaceTintColor: Colors.transparent,
            // FittedBox instead of letting it ellipsize - "Choisir une
            // apparence" in the Cinzel display face is wide, and shrinking
            // it to fit stays fully readable where truncating to
            // "Choisir une appar…" wouldn't.
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                context.translate('player.chooseAppearance'),
                style: fantasyDisplay(fontSize: 20),
              ),
            ),
            foregroundColor: FantasyPalette.gold,
            iconTheme: const IconThemeData(color: FantasyPalette.gold),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: FantasyPalette.gold, width: 1),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: FantasyPalette.gold,
                  unselectedLabelColor: FantasyPalette.parchmentDim,
                  indicatorColor: FantasyPalette.gold,
                  tabs: [
                    Tab(text: context.translate('player.color')),
                    Tab(text: context.translate('player.hero')),
                  ],
                ),
              ),
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
                  style: TextStyle(
                      fontSize: 9,
                      color:
                          FantasyPalette.parchmentDim.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
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
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: FantasyPalette.gold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
            child: CircleAvatar(radius: 26, backgroundColor: color),
          ),
        );
      },
    );
  }

  Widget _buildHeroPicker(BuildContext context) {
    final heroes = _showYoung ? fabHeroesYoung : fabHeroesAdult;
    // Alphabetical is easier to scan for a specific hero than grouping by
    // class - Living Legend heroes are still pulled into their own section
    // below, since that's a format-legality status rather than a class.
    final heroesInOrder = heroes.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final livingLegendHeroes =
        heroesInOrder.where((hero) => hero.isLivingLegend).toList();
    final regularHeroes =
        heroesInOrder.where((hero) => !hero.isLivingLegend).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: SegmentedButton<bool>(
            style: SegmentedButton.styleFrom(
              backgroundColor: FantasyPalette.obsidianLight,
              foregroundColor: FantasyPalette.parchmentDim,
              selectedBackgroundColor: FantasyPalette.gold,
              selectedForegroundColor: FantasyPalette.obsidian,
              side: const BorderSide(color: FantasyPalette.gold),
            ),
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
                    style: const TextStyle(color: FantasyPalette.parchmentDim),
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
                  final crossAxisCount =
                      math.max(4, (availableWidth / idealCellWidth).floor());
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
                          style: fantasyDisplay(
                              fontSize: 16, color: FantasyPalette.gold),
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
        // Gold ring Container adds its own border width on top of the
        // avatar's diameter, and the 2-line caption below it needs enough
        // headroom to not clip even with a boosted text scale factor (now
        // clamped above, but with some margin to spare).
        mainAxisExtent: avatarRadius * 2 + 48,
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
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: FantasyPalette.gold, width: 2),
                ),
                child: CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: FantasyPalette.obsidianLight,
                  backgroundImage: AssetImage(hero.thumbnailPath),
                  onBackgroundImageError: (exception, stackTrace) {},
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hero.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: FantasyPalette.parchment),
              ),
            ],
          ),
        );
      },
    );
  }
}
