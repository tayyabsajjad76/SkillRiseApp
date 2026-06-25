import 'dart:html' as html;

Future<void> downloadResume(List<int> bytes) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', 'resume.pdf')
    ..click();
  html.Url.revokeObjectUrl(url);
}