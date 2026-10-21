Livinkey app fixes

Changes (this update):
1. Agreement document upload is now image-based (camera/gallery), same as passport, signature, Aadhaar, etc. Removed PDF-only FilePicker path for agreement so it matches other document types in Documents Management.
2. Tenant Documents Management: bulk download (Download All / Download Selected) now requests a ZIP from the backend endpoint POST /documents/my-documents/download (ownership-checked). Zip is saved to temp storage and opened via open_filex. Web falls back to sequential open.
3. App version (from package_info_plus / pubspec version) is shown on Tenant Profile and Guest Profile screens as "Version x.y.z+build".

New dependencies (run flutter pub get):
- path_provider
- package_info_plus
- open_filex

Backend companion changes:
- tenant.document.controller: downloadMyDocumentsBulk
- tenant.document.routes: POST /my-documents/download (tenant auth)

Notes:
- Electronic agreement acceptance + generated PDF download (Agreements screen) is unchanged; only the uploaded "Agreement" document type is now image-based.
- Legacy agreement PDFs already in Cloudinary still preview as PDF icon; new uploads are images.
- Flutter SDK was not available in this environment; run `flutter pub get` and test locally.
