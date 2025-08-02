import 'package:flutter/material.dart';

import 'package:youtipie/class/result_wrapper/playlist_user_result.dart';
import 'package:youtipie/class/youtipie_feed/playlist_info_item_user.dart';
import 'package:youtipie/core/enum.dart';
import 'package:youtipie/youtipie.dart';

import 'package:namida/class/route.dart';
import 'package:namida/core/dimensions.dart';
import 'package:namida/core/enums.dart';
import 'package:namida/core/icon_fonts/broken_icons.dart';
import 'package:namida/core/translations/language.dart';
import 'package:namida/core/utils.dart';
import 'package:namida/ui/widgets/custom_widgets.dart';
import 'package:namida/youtube/controller/youtube_account_controller.dart';
import 'package:namida/youtube/controller/youtube_info_controller.dart';
import 'package:namida/youtube/functions/yt_playlist_utils.dart';
import 'package:namida/youtube/pages/user/youtube_account_manage_page.dart';
import 'package:namida/youtube/pages/youtube_main_page_fetcher_acc_base.dart';
import 'package:namida/youtube/pages/youtube_user_history_page.dart';
import 'package:namida/youtube/widgets/yt_playlist_card.dart';
import 'package:namida/youtube/widgets/yt_thumbnail.dart';
import 'package:namida/youtube/widgets/yt_video_card.dart';

class YoutubeUserPlaylistsPage extends StatefulWidget {
  const YoutubeUserPlaylistsPage({super.key});

  @override
  State<YoutubeUserPlaylistsPage> createState() => _YoutubeUserPlaylistsPageState();
}

class _YoutubeUserPlaylistsPageState extends State<YoutubeUserPlaylistsPage> {
  final horizontalHistoryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    const multiplier = 0.8;
    const thumbnailHeight = multiplier * Dimensions.youtubeThumbnailHeight;
    const thumbnailWidth = multiplier * Dimensions.youtubeThumbnailWidth;
    const thumbnailItemExtent = thumbnailHeight + 8.0 * 2;
    final horizontalHistory = YoutubeUserHistoryPageHorizontal(pageKey: horizontalHistoryKey);
    return YoutubeMainPageFetcherAccBase<YoutiPieUserPlaylistsResult, PlaylistInfoItemUser>(
        operation: YoutiPieOperation.fetchUserPlaylists,
        transparentShimmer: true,
        topPadding: 12.0,
        pageHeader: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _AccountHeader(),
            horizontalHistory,
          ],
        ),
        onInitState: (wrapper) {
          YtUtilsPlaylist.activeUserPlaylistsList = wrapper;
        },
        onDispose: (wrapper) {
          YtUtilsPlaylist.activeUserPlaylistsList = null;
        },
        onPullToRefresh: () => (horizontalHistoryKey.currentState as dynamic)?.forceFetchFeed() as Future<void>,
        title: lang.PLAYLISTS,
        isSortable: true,
        headerTrailing: NamidaIconButton(
          icon: Broken.add_circle,
          iconSize: 22.0,
          onPressed: () {
            YtUtilsPlaylist().promptCreatePlaylist(
              onButtonConfirm: (playlistTitle, privacy) async {
                privacy ??= PlaylistPrivacy.private;
                final newPlaylistId = await YoutubeInfoController.userplaylist.createPlaylist(
                  mainList: YtUtilsPlaylist.activeUserPlaylistsList,
                  title: playlistTitle,
                  initialVideoIds: [],
                  privacy: privacy,
                );
                if (newPlaylistId != null) return true;
                return false;
              },
            );
          },
        ),
        cacheReader: YoutiPie.cacheBuilder.forUserPlaylists(),
        cacheReadFn: (reader) async {
          final res = await reader.read();
          await YoutiPie.userplaylist.injectDefaultPlaylistsInUserPlaylists(res);
          return res;
        },
        networkFetcher: (details) => YoutubeInfoController.userplaylist.getUserPlaylists(details: details),
        itemExtent: thumbnailItemExtent,
        dummyCard: const YoutubeVideoCardDummy(
          thumbnailWidth: thumbnailWidth,
          thumbnailHeight: thumbnailHeight,
          shimmerEnabled: true,
        ),
        itemBuilder: (playlist, index, list) {
          return YoutubePlaylistCard(
            queueSource: QueueSourceYoutubeID.playlistHosted,
            key: Key(playlist.id),
            playlist: playlist,
            subtitle: playlist.infoTexts?.join(' - '), // the second text is mostly like 'updated today' etc
            thumbnailWidth: thumbnailWidth,
            thumbnailHeight: thumbnailHeight,
            firstVideoID: null,
            isMixPlaylist: playlist.isMix,
            playOnTap: false,
          );
        });
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader();

  @override
  Widget build(BuildContext context) {
    return ObxO(
      rx: YoutubeAccountController.current.activeAccountChannel,
      builder: (context, acc) {
        if (acc == null) return const SizedBox();
        final title = acc.title;
        final handler = acc.handler;
        final showTitle = title != null && title.isNotEmpty;
        final showHandler = handler.isNotEmpty;
        return Padding(
          padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
          child: Row(
            children: [
              const SizedBox(width: 24.0),
              YoutubeThumbnail(
                type: ThumbnailType.channel,
                key: Key(acc.id),
                width: 54.0,
                forceSquared: false,
                isImportantInCache: true,
                customUrl: acc.thumbnails.pick()?.url,
                isCircle: true,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showTitle)
                      Text(
                        title,
                        style: context.textTheme.displayMedium,
                      ),
                    if (showTitle || showHandler) const SizedBox(height: 2.0),
                    if (showHandler)
                      Text(
                        acc.handler,
                        style: context.textTheme.displaySmall,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),
              IconButton.filledTonal(
                onPressed: const YoutubeAccountManagePage().navigate,
                icon: const Icon(
                  Broken.edit,
                ),
              ),
              const SizedBox(width: 18.0),
            ],
          ),
        );
      },
    );
  }
}
