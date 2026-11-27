import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('geometry shader retains all uniforms written by the renderer', () async {
    final program = await ui.FragmentProgram.fromAsset(
      'packages/liquid_glass_widgets/shaders/liquid_glass_geometry_blended.frag',
    );
    final shader = program.fragmentShader();
    try {
      // Optical properties (4), shape settings (2), shape data, native edge.
      const count = 6 + LiquidGlassBlendGroup.maxShapesPerLayer * 7 + 1;
      for (var index = 0; index < count; index++) {
        shader.setFloat(index, 0);
      }
    } finally {
      shader.dispose();
    }
  });

  test('translated glass geometry keeps its right edge visible', () async {
    final program = await ui.FragmentProgram.fromAsset(
      'packages/liquid_glass_widgets/shaders/liquid_glass_geometry_blended.frag',
    );
    final shader = program.fragmentShader();
    final values = [1.5, 0.0, 12.0, 0.0, 1.0, 1.0,
      3.0, 250.0, 350.0, 100.0, 100.0, 12.0, 12.0];
    for (var index = 0; index < values.length; index++) {
      shader.setFloat(index, values[index]);
    }
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)..translate(-200, -300);
    canvas.drawRect(const ui.Rect.fromLTWH(200, 300, 100, 100), ui.Paint()..shader = shader);
    final picture = recorder.endRecording();
    final image = await picture.toImage(100, 100);
    final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(pixels!.getUint8((50 * 100 + 90) * 4 + 3), greaterThan(240));
    image.dispose();
    picture.dispose();
    shader.dispose();
  });
}
