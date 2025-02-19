import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/modules/map/ui/map_thumbnail.dart';
import 'package:immich_mobile/modules/search/ui/curated_row.dart';
import 'package:immich_mobile/modules/search/ui/thumbnail_with_info.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/shared/models/store.dart';
import 'package:latlong2/latlong.dart';

class CuratedPlacesRow extends CuratedRow {
  final bool isMapEnabled;

  const CuratedPlacesRow({
    super.key,
    required super.content,
    this.isMapEnabled = true,
    super.imageSize,
    super.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Calculating the actual index of the content based on the whether map is enabled or not.
    // If enabled, inject map as the first item in the list (index 0) and so the actual content will start from index 1
    final int actualContentIndex = isMapEnabled ? 1 : 0;
    Widget buildMapThumbnail() {
      return GestureDetector(
        onTap: () => context.autoPush(
          const MapRoute(),
        ),
        child: SizedBox.square(
          dimension: imageSize,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: MapThumbnail(
                  zoom: 2,
                  coords: LatLng(
                    47,
                    5,
                  ),
                  height: imageSize,
                  width: imageSize,
                  showAttribution: false,
                  isDarkTheme: context.isDarkTheme,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black,
                    gradient: LinearGradient(
                      begin: FractionalOffset.topCenter,
                      end: FractionalOffset.bottomCenter,
                      colors: [
                        Colors.blueGrey.withOpacity(0.0),
                        Colors.black.withOpacity(0.4),
                      ],
                      stops: const [0.0, 0.4],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: const Text(
                    "search_page_your_map",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ).tr(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Return empty thumbnail
    if (!isMapEnabled && content.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: imageSize,
            height: imageSize,
            child: ThumbnailWithInfo(
              textInfo: '',
              onTap: () {},
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      itemBuilder: (context, index) {
        // Injecting Map thumbnail as the first element
        if (isMapEnabled && index == 0) {
          return buildMapThumbnail();
        }
        final actualIndex = index - actualContentIndex;
        final object = content[actualIndex];
        final thumbnailRequestUrl =
            '${Store.get(StoreKey.serverEndpoint)}/asset/thumbnail/${object.id}';
        return SizedBox(
          width: imageSize,
          height: imageSize,
          child: Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: ThumbnailWithInfo(
              imageUrl: thumbnailRequestUrl,
              textInfo: object.label,
              onTap: () => onTap?.call(object, actualIndex),
            ),
          ),
        );
      },
      itemCount: content.length + actualContentIndex,
    );
  }
}
