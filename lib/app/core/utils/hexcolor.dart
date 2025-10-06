
import 'dart:ui';

class HexColor extends Color {
  HexColor(final String hexColor)
      : super(int.parse(hexColor.replaceAll('#', '0xff')));
}
