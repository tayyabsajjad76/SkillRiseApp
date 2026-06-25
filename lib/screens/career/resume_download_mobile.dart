import 'dart:typed_data';
import 'package:printing/printing.dart';

Future<void> downloadResume(List<int> bytes) async {
  await Printing.sharePdf(
    bytes: Uint8List.fromList(bytes),
    filename: 'resume.pdf',
  );
}