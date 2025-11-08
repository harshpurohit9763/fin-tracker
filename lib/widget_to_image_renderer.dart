import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class WidgetToImageRenderer {
  static Future<String> render(
      {required BuildContext context, required GlobalKey key}) async {
    // Find the RenderRepaintBoundary from the GlobalKey
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;

    // Render the boundary to an image
    final image = await boundary.toImage(pixelRatio: 2.0);

    // Convert the image to byte data
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    // Save the byte data to a temporary file
    final tempDir = await getTemporaryDirectory();
    final file = await File(
            '${tempDir.path}/emi_notification_${DateTime.now().millisecondsSinceEpoch}.png')
        .create();
    await file.writeAsBytes(pngBytes);

    return file.path;
  }

  /// A utility to render a widget off-screen.
  /// This is useful for background services where no UI is visible.
  static Future<String> renderOffScreen(Widget widget) async {
    final RenderRepaintBoundary boundary = RenderRepaintBoundary();
    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    // Define the size of the image
    const imageSize = Size(800, 800 * (1 / 1.586));

    final RenderView renderView = RenderView(
      view: ui.PlatformDispatcher.instance.views.first,
      child: RenderPositionedBox(alignment: Alignment.center, child: boundary),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(imageSize),
        physicalConstraints: BoxConstraints.tight(imageSize),
        devicePixelRatio: 1.0,
      ),
    );

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
            container: boundary,
            child:
                Directionality(textDirection: TextDirection.ltr, child: widget))
        .attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final file = await File(
            '${tempDir.path}/emi_notification_${DateTime.now().millisecondsSinceEpoch}.png')
        .create();
    await file.writeAsBytes(pngBytes);

    return file.path;
  }
}
