import 'dart:math';

import 'flutter_flexible_polyline.dart';

///
/// Stateful instance for encoding and decoding on a sequence of Coordinates
/// part of a request.
/// Instance should be specific to type of coordinates (e.g. Lat, Lng)
/// so that specific type delta is computed for encoding.
/// Lat0 Lng0 3rd0 (Lat1-Lat0) (Lng1-Lng0) (3rdDim1-3rdDim0)
///
class Converter {
  final int precision;
  late BigInt multiplier;
  BigInt lastValue = BigInt.zero;

  Converter(this.precision) {
    multiplier = BigInt.from(pow(10, precision));
  }

  // Returns decoded BigInt, new index in tuple
  static (BigInt, int) decodeUnsignedVarint(List<String> encoded, int index) {
    int shift = 0;
    BigInt delta = BigInt.zero;
    BigInt value;

    while (index < encoded.length) {
      value = BigInt.from(decodeChar(encoded[index]));
      if (value < BigInt.zero) {
        throw ArgumentError("Invalid encoding");
      }
      index++;
      delta |= (value & BigInt.from(0x1F)) << shift;
      if ((value & BigInt.from(0x20)) == BigInt.zero) {
        return (delta, index);
      } else {
        shift += 5;
      }
    }

    if (shift > 0) {
      throw ArgumentError("Invalid encoding");
    }
    return (BigInt.zero, index);
  }

  // Decode single coordinate (say lat|lng|z) starting at index
  // Returns decoded coordinate, new index in tuple
  (double, int) decodeValue(List<String> encoded, int index) {
    final (BigInt, int) result = decodeUnsignedVarint(encoded, index);
    double coordinate = 0;
    BigInt delta = result.$1;
    if ((delta & BigInt.one) != BigInt.zero) {
      delta = ~delta;
    }
    delta = delta >> 1;
    lastValue += delta;
    coordinate = lastValue.toDouble() / multiplier.toDouble();
    return (coordinate, result.$2);
  }

  static String encodeUnsignedVarint(BigInt value) {
    String result = '';
    while (value > BigInt.from(0x1F)) {
      int pos = ((value & BigInt.from(0x1F)) | BigInt.from(0x20)).toInt();
      result += FlexiblePolyline.encodingTable[pos];
      value >>= 5;
    }
    result += (FlexiblePolyline.encodingTable[value.toInt()]);
    return result;
  }

  // Encode a single double to a string
  String encodeValue(double value) {
    /*
     * Round-half-up
     * round(-1.4) --> -1
     * round(-1.5) --> -2
     * round(-2.5) --> -3
     */
    final double scaledValue =
        (value * multiplier.toDouble()).abs().round() * value.sign;
    BigInt delta = (BigInt.from(scaledValue.toInt()) - lastValue);
    final bool negative = delta < BigInt.zero;

    lastValue = BigInt.from(scaledValue.toInt());

    // make room on lowest bit
    delta <<= 1;

    // invert bits if the value is negative
    if (negative) {
      delta = ~delta;
    }
    return encodeUnsignedVarint(delta);
  }

  //Decode a single char to the corresponding value
  static int decodeChar(String charValue) {
    final int pos = charValue.codeUnitAt(0) - 45;
    if (pos < 0 || pos > 77) {
      return -1;
    }
    return FlexiblePolyline.decodingTable[pos];
  }
}
