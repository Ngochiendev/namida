// ignore_for_file: non_constant_identifier_names

import 'dart:collection';
import 'dart:io';

import 'package:history_manager/history_manager.dart';

import 'package:namida/class/track.dart';
import 'package:namida/controller/settings_controller.dart';
import 'package:namida/core/constants.dart';
import 'package:namida/core/dimensions.dart';
import 'package:namida/core/enums.dart';
import 'package:namida/core/extensions.dart';
import 'package:namida/core/utils.dart';
import 'package:namida/ui/widgets/library/track_tile.dart';

class HistoryController with HistoryManager<TrackWithDate, Track> {
  static HistoryController get inst => _instance;
  static final HistoryController _instance = HistoryController._internal();
  HistoryController._internal() {
    onTopItemsMapModified = TrackTileManager.onTrackItemPropChange;
    latestUpdatedMostPlayedItem.addListener(() => TrackTileManager.rebuildTrackInfo(latestUpdatedMostPlayedItem.value! /* not null bet */));
  }

  @override
  double daysToSectionExtent(List<int> days) {
    final trackTileExtent = Dimensions.inst.trackTileItemExtent;
    const dayHeaderExtent = kHistoryDayHeaderHeightWithPadding;
    double total = 0;
    days.loop((day) => total += dayToSectionExtent(day, trackTileExtent, dayHeaderExtent));
    return total;
  }

  Future<void> replaceTracksDirectoryInHistory(String oldDir, String newDir, {Iterable<String>? forThesePathsOnly, bool ensureNewFileExists = false}) async {
    String getNewPath(String old) => old.replaceFirst(oldDir, newDir);
    await replaceTheseTracksInHistory(
      (e) {
        final trackPath = e.track.path;
        if (ensureNewFileExists) {
          if (!File(getNewPath(trackPath)).existsSync()) return false;
        }
        final firstC = forThesePathsOnly != null ? forThesePathsOnly.contains(e.track.path) : true;
        final secondC = trackPath.startsWith(oldDir);
        return firstC && secondC;
      },
      (old) => TrackWithDate(
        dateAdded: old.dateAdded,
        track: Track.fromTypeParameter(old.track.runtimeType, getNewPath(old.track.path)),
        source: old.source,
      ),
    );
  }

  Future<void> replaceAllTracksInsideHistory(Selectable oldTrack, Track newTrack) async {
    await replaceTheseTracksInHistory(
      (e) => e.track == oldTrack.track,
      (old) => TrackWithDate(
        dateAdded: old.dateAdded,
        track: newTrack,
        source: old.source,
      ),
    );
  }

  Future<int> removeSourcesTracksFromHistory(List<TrackSource> sources, {DateTime? oldestDate, DateTime? newestDate}) async {
    if (sources.isEmpty) return 0;

    int totalRemoved = 0;
    List<int>? daysToSave;

    // -- remove all sources (i.e all history)
    if (oldestDate == null && newestDate == null && sources.isEqualTo(TrackSource.values)) {
      totalRemoved = totalHistoryItemsCount.value;
      historyMap.value.clear();
      daysToSave = null;
    } else {
      final daysToRemoveFrom = historyDays.toList();

      final oldestDay = oldestDate?.toDaysSince1970();
      final newestDay = newestDate?.toDaysSince1970();

      if (oldestDay != null && newestDay == null) {
        daysToRemoveFrom.retainWhere((day) => day >= oldestDay);
      }
      if (oldestDay == null && newestDay != null) {
        daysToRemoveFrom.retainWhere((day) => day <= newestDay);
      }

      if (oldestDay != null && newestDay != null) {
        daysToRemoveFrom.retainWhere((day) => day >= oldestDay && day <= newestDay);
      }

      // -- will loop the whole days.
      /* if (oldestDay == null && newestDay == null) {} */

      final history = historyMap.value;
      daysToRemoveFrom.loop((d) {
        totalRemoved += history[d]?.removeWhereWithDifference((twd) => sources.contains(twd.source)) ?? 0;
      });
      daysToSave = daysToRemoveFrom;
    }

    if (totalRemoved > 0) {
      totalHistoryItemsCount.value -= totalRemoved;
      historyMap.refresh();
      updateMostPlayedPlaylist();
      await saveHistoryToStorage(daysToSave);
    } else if (daysToSave != null) {
      // just in case its edited but `totalRemoved` uh
      await saveHistoryToStorage(daysToSave);
    }

    return totalRemoved;
  }

  @override
  String get HISTORY_DIRECTORY => AppDirs.HISTORY_PLAYLIST;

  @override
  Map<String, dynamic> itemToJson(TrackWithDate item) => item.toJson();

  @override
  Track mainItemToSubItem(TrackWithDate item) => item.track;

  @override
  Future<HistoryPrepareInfo<TrackWithDate, Track>> prepareAllHistoryFilesFunction(String directoryPath) async {
    return await _readHistoryFilesCompute.thready(directoryPath);
  }

  static HistoryPrepareInfo<TrackWithDate, Track> _readHistoryFilesCompute(String path) {
    final map = SplayTreeMap<int, List<TrackWithDate>>((date1, date2) => date2.compareTo(date1));
    final tempMapTopItems = <Track, List<int>>{};
    int totalCount = 0;
    final files = Directory(path).listSyncSafe();
    final filesL = files.length;
    for (int i = 0; i < filesL; i++) {
      var f = files[i];
      if (f is File) {
        try {
          final response = f.readAsJsonSync(ensureExists: false) as List?;
          final dayOfTrack = int.parse(f.path.getFilenameWOExt);
          final listTracks = <TrackWithDate>[];
          if (response != null) {
            for (var i = 0; i < response.length; i++) {
              var twd = TrackWithDate.fromJson(response[i]);
              listTracks.add(twd);
              tempMapTopItems.addForce(twd.track, twd.dateAdded);
            }
          }

          map[dayOfTrack] = listTracks;
          totalCount += listTracks.length;
        } catch (_) {}
      }
    }

    final topItems = ListensSortedMap<Track>();
    topItems.assignAll(tempMapTopItems);
    topItems.sortAllInternalLists();

    return HistoryPrepareInfo(
      historyMap: map,
      topItems: topItems,
      totalItemsCount: totalCount,
    );
  }

  @override
  Rx<MostPlayedTimeRange> get currentMostPlayedTimeRange => settings.mostPlayedTimeRange;

  @override
  Rx<DateRange> get mostPlayedCustomDateRange => settings.mostPlayedCustomDateRange;

  @override
  Rx<bool> get mostPlayedCustomIsStartOfDay => settings.mostPlayedCustomisStartOfDay;
}
