import 'package:flutter/material.dart';

/// A stable horizontal canvas; only the media inside changes aspect ratio.
class VideoViewport extends StatelessWidget {
  const VideoViewport({
    super.key,
    required this.child,
    this.videoSize = Size.zero,
  });

  final Widget child;
  final Size videoSize;

  @override
  Widget build(BuildContext context) {
    final validSize =
        videoSize.width.isFinite &&
        videoSize.height.isFinite &&
        videoSize.width > 0 &&
        videoSize.height > 0;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRect(
        child: ColoredBox(
          color: Colors.black,
          child: validSize
              ? FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox.fromSize(size: videoSize, child: child),
                )
              : Center(child: child),
        ),
      ),
    );
  }
}
