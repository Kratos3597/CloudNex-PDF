import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

class WordExportService {
  /// Converts PDF content to a VALID non-corrupt Word (.docx) file
  /// Uses the OpenXML structure (Zip of XMLs) to guarantee compatibility
  static Uint8List convertToWordDocx(Uint8List pdfBytes) {
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: pdfBytes);
    final sf.PdfTextExtractor extractor = sf.PdfTextExtractor(document);
    String extractedText = extractor.extractText();
    document.dispose();

    // Escape XML special characters
    String safeText = extractedText
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('\n', '</w:t><w:br/><w:t>');

    // 1. Create the word/document.xml content
    final documentXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:r>
        <w:t>$safeText</w:t>
      </w:r>
    </w:p>
  </w:body>
</w:document>''';

    // 2. Create the [Content_Types].xml
    final contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';

    // 3. Create _rels/.rels
    final relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

    // 4. Zip it all together
    final archive = Archive();
    
    archive.addFile(ArchiveFile('word/document.xml', documentXml.length, documentXml.codeUnits));
    archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesXml.length, contentTypesXml.codeUnits));
    archive.addFile(ArchiveFile('_rels/.rels', relsXml.length, relsXml.codeUnits));

    final zipEncoder = ZipEncoder();
    final List<int>? encoded = zipEncoder.encode(archive);
    
    return Uint8List.fromList(encoded!);
  }
}
