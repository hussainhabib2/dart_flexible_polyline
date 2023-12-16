import 'package:flexible_polyline_dart/flutter_flexible_polyline.dart';
import 'package:flexible_polyline_dart/latlngz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Decode Polyline', () {
    const encoded = "BFoz5xJ67i1B1B7PzIhaxL7Y";
    final cords = FlexiblePolyline.decode(encoded);
    expect(cords.isNotEmpty, true);
  });

  test('Encode Polyline', () {
    List<LatLngZ> cords = [
      LatLngZ(50.10228, 8.69821),
      LatLngZ(50.10201, 8.69567),
      LatLngZ(50.10063, 8.69150),
      LatLngZ(50.09878, 8.68752),
    ];
    final encoded = FlexiblePolyline.encode(cords, 5, ThirdDimension.ABSENT, 0);
    expect(encoded, 'BFoz5xJ67i1B1B7PzIhaxL7Y');
  });
}
