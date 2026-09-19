# CloudNex PDF Pro - Android & Flutter Syncfusion Edition

An enterprise-grade Android PDF viewer, editor, digital signature, and sharing suite powered by **Syncfusion Flutter PDF** and **Android Native FileProvider**.

---

## Key Features
1. **Syncfusion PDF Engine (`SfPdfViewer` & `PdfDocument`)**:
   - Hardware-accelerated Skia/Impeller rendering designed to handle large, image-dense PDFs without Out-Of-Memory (OOM) crashes.
   - Continuous vertical virtualized scrolling and pinch-to-zoom (0.5x to 3.0x).
2. **Google ML Kit OCR + Syncfusion Searchable PDF Pipeline**:
   - On-device **Google ML Kit Text Recognition** (`google_mlkit_text_recognition`) extracts words, confidence ratings, and bounding boxes directly from camera scans or photos.
   - **Syncfusion `PdfDocument`** draws the high-res scan bitmap and overlays an invisible text graphics layer (`PdfSolidBrush(PdfColor(0, 0, 0, 0))`) matching word coordinates.
   - The resulting PDF is fully searchable (`Ctrl+F`), selectable, and copyable inside `SfPdfViewer` or any standard PDF reader.
3. **Android Large Heap Optimization**:
   - Configured with `android:largeHeap="true"` in `AndroidManifest.xml` to grant up to 512MB+ of Dalvik/ART RAM for scanned graphics.
4. **Digital Signature & Flattening**:
   - Interactive smooth vector signature pad.
   - Automatic flattening (`flattenAllFields()` and graphics layer burning) ensuring signatures and annotations are baked directly into the PDF content stream for 100% compatibility with third-party PDF viewers (Adobe, WhatsApp, Gmail).
5. **Android Native Share Sheet**:
   - Integrated with Android `FileProvider` (`content://` URI) and `share_plus` to dispatch PDFs directly to WhatsApp, Gmail, Google Drive, or Nearby Share without path security exceptions on Android 10+.

---

## How to Register Your Syncfusion License Key

1. Open `lib/main.dart`.
2. Locate the license registration block:
   ```dart
   const String syncfusionLicenseKey = 'PASTE_YOUR_SYNCFUSION_LICENSE_KEY_HERE';
   SyncfusionLicense.registerLicense(syncfusionLicenseKey);
   ```
   Or pass it at build time:
   ```bash
   flutter run --dart-define=SYNCFUSION_LICENSE_KEY="YOUR_KEY_HERE"
   ```

---

## How to Run in Android Studio

1. Open **Android Studio**.
2. Select **Open** and select the `/flutter_android` directory.
3. Run `flutter pub get` in the terminal to resolve Syncfusion dependencies.
4. Connect an Android phone with Developer Options enabled (or start an Android Virtual Device emulator).
5. Click **Run (Shift + F10)**.

To build a release APK:
```bash
flutter build apk --release
```
The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.
