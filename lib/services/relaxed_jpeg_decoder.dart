import 'package:collection/collection.dart';
import 'package:image_size_getter/image_size_getter.dart';

// This replaces the default JPEG validator/analyser
// It was failing because some Google Pixels append debugging information to
// JPEG files, and the validation was failing becuse the final byes we not the
// expected FF D9

class RelaxedJpegDecoder extends BaseDecoder {
  const RelaxedJpegDecoder();

  @override
  String get decoderName => 'jpeg';

  @override
  Size getSize(ImageInput input) {
    int start = 2;
    BlockEntity? block;
    var orientation = 1;

    while (true) {
      block = _getBlockSync(input, start);

      if (block == null) {
        throw Exception('Invalid jpeg file');
      }

      // Check for App1 block
      if (block.type == 0xE1) {
        final app1BlockData = input.getRange(
          start,
          block.start + block.length,
        );
        final exifOrientation = _getOrientation(app1BlockData);
        if (exifOrientation != null) {
          orientation = exifOrientation;
        }
      }

      if (block.type == 0xC0 || block.type == 0xC2) {
        final widthList = input.getRange(start + 7, start + 9);
        final heightList = input.getRange(start + 5, start + 7);
        return _getSize(widthList, heightList, orientation);
      } else {
        start += block.length;
      }
    }
  }

  Size _getSize(List<int> widthList, List<int> heightList, int orientation) {
    final width = convertRadix16ToInt(widthList);
    final height = convertRadix16ToInt(heightList);
    final needRotate = [5, 6, 7, 8].contains(orientation);
    return Size(width, height, needRotate: needRotate);
  }

  @override
  Future<Size> getSizeAsync(AsyncImageInput input) async {
    int start = 2;
    BlockEntity? block;
    var orientation = 1;

    while (true) {
      block = await _getBlockAsync(input, start);

      if (block == null) {
        throw Exception('Invalid jpeg file');
      }

      if (block.type == 0xE1) {
        final app1BlockData = await input.getRange(
          start,
          block.start + block.length,
        );
        final exifOrientation = _getOrientation(app1BlockData);
        if (exifOrientation != null) {
          orientation = exifOrientation;
        }
      }

      if (block.type == 0xC0 || block.type == 0xC2) {
        final widthList = await input.getRange(start + 7, start + 9);
        final heightList = await input.getRange(start + 5, start + 7);
        orientation = (await input.getRange(start + 9, start + 10))[0];
        return _getSize(widthList, heightList, orientation);
      } else {
        start += block.length;
      }
    }
  }

  BlockEntity? _getBlockSync(ImageInput input, int blockStart) {
    try {
      final blockInfoList = input.getRange(blockStart, blockStart + 4);

      if (blockInfoList[0] != 0xFF) {
        return null;
      }

      final blockSizeList = input.getRange(blockStart + 2, blockStart + 4);

      return _createBlock(blockSizeList, blockStart, blockInfoList);
    } catch (e) {
      return null;
    }
  }

  Future<BlockEntity?> _getBlockAsync(
      AsyncImageInput input, int blockStart) async {
    try {
      final blockInfoList = await input.getRange(blockStart, blockStart + 4);

      if (blockInfoList[0] != 0xFF) {
        return null;
      }

      final blockSizeList =
          await input.getRange(blockStart + 2, blockStart + 4);

      return _createBlock(blockSizeList, blockStart, blockInfoList);
    } catch (e) {
      return null;
    }
  }

  BlockEntity _createBlock(
    List<int> sizeList,
    int blockStart,
    List<int> blockInfoList,
  ) {
    final blockLength =
        convertRadix16ToInt(sizeList) + 2; // +2 for 0xFF and TYPE
    final typeInt = blockInfoList[1];

    return BlockEntity(typeInt, blockLength, blockStart);
  }

  SimpleFileHeaderAndFooter get simpleFileHeaderAndFooter => _JpegInfo();

  int? _getOrientation(List<int> app1blockData) {
    // About EXIF, See: https://www.media.mit.edu/pia/Research/deepview/exif.html#orientation

    // app1 block buffer:
    // header (2 bytes)
    // length (2 bytes)
    // exif header (6 bytes)
    // exif for little endian (2 bytes), 0x4d4d is for big endian, 0x4949 is for little endian
    // tag mark (2 bytes)
    // offset first IFD (4 bytes)
    // IFD data :
    // number of entries (2 bytes)
    // for each entry:
    //   exif tag (2 bytes)
    //   data format (2 bytes), 1 = unsigned byte, 2 = ascii, 3 = unsigned short, 4 = unsigned long, 5 = unsigned rational, 6 = signed byte, 7 = undefined, 8 = signed short, 9 = signed long, 10 = signed rational
    //   number of components (4 bytes)
    //   value (4 bytes)
    //   padding (0 ~ 3 bytes, depends on data format)
    // So, the IFD data starts at offset 14.

    // Check app1 block exif info is valid
    if (app1blockData.length < 14) {
      return null;
    }

    // Check app1 block exif info is valid
    final exifIdentifier = app1blockData.sublist(4, 10);

    final listEquality = ListEquality();

    if (!listEquality
        .equals(exifIdentifier, [0x45, 0x78, 0x69, 0x66, 0x00, 0x00])) {
      return null;
    }

    final littleEndian = app1blockData[10] == 0x49;

    int getNumber(int start, int end) {
      final numberList = app1blockData.sublist(start, end);
      return convertRadix16ToInt(numberList, reverse: littleEndian);
    }

    // Get idf byte
    var idf0Start = 18;
    final tagEntryCount = getNumber(idf0Start, idf0Start + 2);

    var currentIndex = idf0Start + 2;

    for (var i = 0; i < tagEntryCount; i++) {
      final tagType = getNumber(currentIndex, currentIndex + 2);

      if (tagType == 0x0112) {
        return getNumber(currentIndex + 8, currentIndex + 10);
      }

      // every tag length is 0xC bytes
      currentIndex += 0xC;
    }

    return null;
  }

  @override
  Future<bool> isValidAsync(AsyncImageInput input) async {
    final length = await input.length;
    final header = await input.getRange(
      0,
      simpleFileHeaderAndFooter.startBytes.length,
    );
    final footer = await input.getRange(
      length - simpleFileHeaderAndFooter.endBytes.length,
      length,
    );

    final headerEquals = compareTwoList(
      header,
      simpleFileHeaderAndFooter.startBytes,
    );
    final footerEquals = compareTwoList(
      footer,
      simpleFileHeaderAndFooter.endBytes,
    );
    return headerEquals && footerEquals;
  }

  @override
  bool isValid(ImageInput input) {
    // final length = input.length;
    final header = input.getRange(
      0,
      simpleFileHeaderAndFooter.startBytes.length,
    );
    // final footer = input.getRange(
    //   length - simpleFileHeaderAndFooter.endBytes.length,
    //   length,
    // );

    final headerEquals = compareTwoList(
      header,
      simpleFileHeaderAndFooter.startBytes,
    );
    // final footerEquals = compareTwoList(
    //   footer,
    //   simpleFileHeaderAndFooter.endBytes,
    // );
    // return headerEquals && footerEquals;
    return headerEquals;
  }
}

class _JpegInfo with SimpleFileHeaderAndFooter {
  static const start = [0xFF, 0xD8];
  static const end = [0xFF, 0xD9];

  @override
  List<int> get endBytes => end;

  @override
  List<int> get startBytes => start;
}

/// The block of jpeg format.
class BlockEntity {
  /// The block of jpeg format.
  BlockEntity(this.type, this.length, this.start);

  /// The type of the block.
  int type;

  /// The length of the block.
  int length;

  /// Start of offset
  int start;

  /// Error block.
  static BlockEntity error = BlockEntity(-1, -1, -1);

  @override
  String toString() {
    return "BlockEntity (type:$type, length:$length)";
  }
}
