import 'package:flutter/material.dart';

import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:namida/class/count_per_row.dart';
import 'package:namida/class/route.dart';
import 'package:namida/controller/history_controller.dart';
import 'package:namida/controller/scroll_search_controller.dart';
import 'package:namida/controller/search_sort_controller.dart';
import 'package:namida/controller/settings_controller.dart';
import 'package:namida/core/dimensions.dart';
import 'package:namida/core/enums.dart';
import 'package:namida/core/extensions.dart';
import 'package:namida/core/icon_fonts/broken_icons.dart';
import 'package:namida/core/namida_converter_ext.dart';
import 'package:namida/core/translations/language.dart';
import 'package:namida/core/utils.dart';
import 'package:namida/ui/widgets/custom_widgets.dart';
import 'package:namida/ui/widgets/expandable_box.dart';
import 'package:namida/ui/widgets/library/album_card.dart';
import 'package:namida/ui/widgets/library/album_tile.dart';
import 'package:namida/ui/widgets/sort_by_button.dart';

class AlbumsPage extends StatelessWidget with NamidaRouteWidget {
  @override
  RouteType get route => RouteType.PAGE_albums;

  final RxList<String>? albumIdentifiers;
  final CountPerRow countPerRow;
  final bool enableGridIconButton;
  final bool animateTiles;
  final bool enableHero;

  const AlbumsPage({
    super.key,
    this.albumIdentifiers,
    required this.countPerRow,
    this.enableGridIconButton = true,
    this.animateTiles = true,
    this.enableHero = true,
  });

  bool get _shouldAnimate => animateTiles && LibraryTab.albums.shouldAnimateTiles;

  @override
  Widget build(BuildContext context) {
    final scrollController = LibraryTab.albums.scrollController;
    final countPerRowResolved = countPerRow.resolve(context);
    final artistTypeColor = context.theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.8);

    return BackgroundWrapper(
      child: NamidaScrollbar(
        controller: scrollController,
        child: AnimationLimiter(
          child: ObxO(
            rx: albumIdentifiers ?? SearchSortController.inst.albumSearchList,
            builder: (context, finalAlbums) => Column(
              children: [
                Obx(
                  (context) {
                    final sort = settings.albumSort.valueR;
                    final sortReverse = settings.albumSortReversed.valueR;

                    return ExpandableBox(
                      enableHero: enableHero,
                      gridWidget: enableGridIconButton
                          ? ChangeGridCountWidget(
                              tab: LibraryTab.albums,
                              forStaggered: settings.useAlbumStaggeredGridView.valueR,
                            )
                          : null,
                      isBarVisible: LibraryTab.albums.isBarVisible.valueR,
                      showSearchBox: LibraryTab.albums.isSearchBoxVisible.valueR,
                      leftText: '',
                      leftWidgets: [
                        NamidaPopupWrapper(
                          children: _getSinglesAndAlbumsToggles,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Broken.arrange_circle,
                                size: 14.0,
                                color: artistTypeColor,
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                finalAlbums.length.displayAlbumKeyword,
                                style: context.textTheme.displayMedium?.copyWith(
                                  color: artistTypeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onFilterIconTap: () => ScrollSearchController.inst.switchSearchBoxVisibilty(LibraryTab.albums),
                      onCloseButtonPressed: () => ScrollSearchController.inst.clearSearchTextField(LibraryTab.albums),
                      sortByMenuWidget: SortByMenu(
                        title: sort.toText(),
                        popupMenuChild: () => const SortByMenuAlbums(),
                        isCurrentlyReversed: sortReverse,
                        onReverseIconTap: () => SearchSortController.inst.sortMedia(MediaType.album, reverse: !settings.albumSortReversed.value),
                      ),
                      textField: () => CustomTextFiled(
                        textFieldController: LibraryTab.albums.textSearchController,
                        textFieldHintText: lang.FILTER_ALBUMS,
                        onTextFieldValueChanged: (value) => SearchSortController.inst.searchMedia(value, MediaType.album),
                      ),
                    );
                  },
                ),
                Obx(
                  (context) {
                    settings.albumListTileHeight.valueR;

                    final sort = settings.albumSort.valueR;
                    final sortTextIsUseless = sort == GroupSortType.album ||
                        sort == GroupSortType.year ||
                        sort == GroupSortType.albumArtist ||
                        sort == GroupSortType.numberOfTracks ||
                        sort == GroupSortType.duration;

                    final extraTextResolver = sortTextIsUseless ? null : SearchSortController.inst.getGroupSortExtraTextResolver(sort);

                    return ObxPrefer(
                      enabled: sort.requiresHistory,
                      rx: HistoryController.inst.topTracksMapListens,
                      builder: (context, _) => countPerRowResolved == 1
                          ? Expanded(
                              child: ListView.builder(
                                controller: scrollController,
                                itemCount: finalAlbums.length,
                                itemExtent: settings.albumListTileHeight.valueR + 4.0 * 5,
                                padding: kBottomPaddingInsets,
                                itemBuilder: (BuildContext context, int i) {
                                  final albumId = finalAlbums[i];
                                  final tracks = albumId.getAlbumTracks();
                                  return AnimatingTile(
                                    position: i,
                                    shouldAnimate: _shouldAnimate,
                                    child: AlbumTile(
                                      identifier: albumId,
                                      album: tracks,
                                      extraText: extraTextResolver?.call(tracks),
                                    ),
                                  );
                                },
                              ),
                            )
                          : settings.useAlbumStaggeredGridView.valueR
                              ? Expanded(
                                  child: MasonryGridView.builder(
                                    controller: scrollController,
                                    padding: kBottomPaddingInsets,
                                    itemCount: finalAlbums.length,
                                    mainAxisSpacing: 8.0,
                                    gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: countPerRowResolved,
                                    ),
                                    itemBuilder: (context, i) {
                                      final albumId = finalAlbums[i];
                                      final tracks = albumId.getAlbumTracks();
                                      return AnimatingGrid(
                                        columnCount: finalAlbums.length,
                                        position: i,
                                        shouldAnimate: _shouldAnimate,
                                        child: AlbumCard(
                                          identifier: albumId,
                                          album: tracks,
                                          staggered: true,
                                          extraInfo: extraTextResolver?.call(tracks),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Expanded(
                                  child: GridView.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: countPerRowResolved,
                                      childAspectRatio: 0.75,
                                      mainAxisSpacing: 8.0,
                                    ),
                                    controller: scrollController,
                                    itemCount: finalAlbums.length,
                                    padding: kBottomPaddingInsets,
                                    itemBuilder: (BuildContext context, int i) {
                                      final albumId = finalAlbums[i];
                                      final tracks = albumId.getAlbumTracks();
                                      return AnimatingGrid(
                                        columnCount: finalAlbums.length,
                                        position: i,
                                        shouldAnimate: _shouldAnimate,
                                        child: AlbumCard(
                                          identifier: albumId,
                                          album: tracks,
                                          staggered: false,
                                          extraInfo: extraTextResolver?.call(tracks),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<MapEntry<VoidCallback?, Widget>> _getSinglesAndAlbumsToggles() {
    MapEntry<VoidCallback?, Widget> buildTile(AlbumType type, IconData icon, String title) {
      void onTap() {
        final wasActive = settings.activeAlbumTypes.value[type] ?? true;
        settings.updateActiveAlbumTypes(type, !wasActive);
        SearchSortController.inst.searchMedia(LibraryTab.albums.textSearchController?.text ?? '', MediaType.album);
      }

      return MapEntry(
        onTap,
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: ObxO(
            rx: settings.activeAlbumTypes,
            builder: (context, activeAlbumTypes) => ListTileWithCheckMark(
              icon: icon,
              title: title,
              active: activeAlbumTypes[type] ?? true,
              onTap: onTap,
            ),
          ),
        ),
      );
    }

    return [
      buildTile(AlbumType.single, Broken.music_square, lang.SINGLES),
      buildTile(AlbumType.normal, Broken.music_dashboard, lang.ALBUMS),
    ];
  }
}
