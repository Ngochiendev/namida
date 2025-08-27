import 'package:flutter/material.dart';

import 'package:namida/class/count_per_row.dart';
import 'package:namida/class/track.dart';
import 'package:namida/controller/navigator_controller.dart';
import 'package:namida/controller/playlist_controller.dart';
import 'package:namida/controller/settings_controller.dart';
import 'package:namida/core/extensions.dart';
import 'package:namida/core/icon_fonts/broken_icons.dart';
import 'package:namida/core/translations/language.dart';
import 'package:namida/core/utils.dart';
import 'package:namida/ui/pages/playlists_page.dart';
import 'package:namida/ui/widgets/custom_widgets.dart';

void showAddToPlaylistDialog(List<Track> tracks) {
  NamidaNavigator.inst.navigateDialog(
    dialog: CustomBlurryDialog(
      horizontalInset: 30.0,
      verticalInset: 30.0,
      contentPadding: EdgeInsets.zero,
      titleWidget: Container(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Broken.music_library_2,
              size: 20.0,
            ),
            const SizedBox(
              width: 12.0,
            ),
            Text(
              lang.ADD_TO_PLAYLIST,
              style: namida.theme.textTheme.displayMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      leftAction: Obx(
        (context) => Text(
          "${PlaylistController.inst.playlistsMap.length.formatDecimal()} ${lang.PLAYLISTS}",
          style: namida.theme.textTheme.displayMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      actions: const [
        SizedBox(
          width: 128.0,
          child: CreatePlaylistButton(),
        ),
      ],
      child: SizedBox(
        height: namida.height * 0.7,
        width: namida.width,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ObxO(
                rx: settings.playlistAddTracksAtBeginning,
                builder: (context, atBeginning) => CustomSwitchListTile(
                  visualDensity: VisualDensity.compact,
                  icon: Broken.arrow_square_up,
                  title: lang.ADD_TRACKS_AT_THE_BEGINNING,
                  value: atBeginning,
                  onChanged: (val) => settings.save(playlistAddTracksAtBeginning: !val),
                ),
              ),
            ),
            SizedBox(height: 2.0),
            Expanded(
              child: PlaylistsPage(
                enableHero: true,
                tracksToAdd: tracks,
                countPerRow: CountPerRow(1),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
