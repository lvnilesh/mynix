{pkgs, ...}: {
  /*
  * Document Processing Tools
  * Tools for PDF manipulation, OCR, and document creation
  * Added: April 2026
  */

  environment.systemPackages = with pkgs; [
    # PDF manipulation
    poppler-utils # pdftoppm, pdfunite, pdfinfo, pdftotext
    qpdf # PDF inspection, encryption, repair
    ghostscript # gs for PDF processing and conversion

    # OCR (Optical Character Recognition)
    tesseract # OCR engine for image -> text extraction

    # Image processing (already in apps.nix, but listed here for context)
    # imagemagick      # convert, composite for image/PDF operations

    # Python packages for document processing
    python313Packages.pillow # PIL for image manipulation with text rendering
    python313Packages.pymupdf # PDF reading, editing, and text extraction
    python313Packages.pypdf # Pure-python PDF manipulation
    python313Packages.reportlab # PDF generation from scratch
  ];

  # Fonts needed for PIL/reportlab text rendering
  fonts.packages = with pkgs; [
    dejavu_fonts # DejaVu Sans for PIL/ReportLab text
  ];
}
