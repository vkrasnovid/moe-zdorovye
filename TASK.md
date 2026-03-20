# Current Tasks

## TASK 1: Complete UI Redesign

The current UI looks terrible — uneven grid, cards of different sizes, buttons overlapping. Redesign the ENTIRE app to look modern and premium.

### Home Screen:
- Even 2-column grid with EQUAL sized cards
- Each card: gradient background (unique color per category), large centered icon in a white circle, category name below, record count badge
- Color scheme per category:
  - Анализы: blue gradient (#1565C0 to #42A5F5)
  - Снимки: purple gradient (#6A1B9A to #AB47BC)
  - Рецепты: green gradient (#2E7D32 to #66BB6A)
  - Вакцинации: orange gradient (#E65100 to #FF9800)
  - Хр. заболевания: red gradient (#C62828 to #EF5350)
  - Показатели здоровья: teal gradient (#00695C to #26A69A)
- ALL 6 categories as identical cards in the grid (including Показатели здоровья — same style!)
- Rounded corners (16px), subtle shadows, 12px gap between cards
- App bar: clean, with search icon and settings icon
- Bottom section: Последние записи list with nice styling
- FAB button: positioned properly, not overlapping content
- Smooth hero animations between screens

### All Screens:
- Consistent styling across all screens
- Nice form inputs with proper spacing
- Modern bottom sheets instead of full-page forms where appropriate
- Empty states with illustrations/icons when no records
- Proper padding and margins everywhere (16px)
- Smooth page transitions

### General:
- Material Design 3 with proper theming
- Light theme only (for now)
- All text in Russian
- No text overflow or clipping anywhere

## TASK 2: Document Parsing and PDF Viewing

Currently uploaded PDFs cannot be opened or viewed. Fix this:

### PDF Viewing:
- Tapping an attached PDF must open it in a full-screen PDF viewer
- Add pinch-to-zoom support
- Add page navigation (page X of Y)
- Back button to return to record

### Image Viewing:
- Tapping an attached image opens full-screen with zoom (photo_view)
- Swipe to dismiss

### File Management:
- Show file thumbnails in record detail (image preview, PDF icon for PDFs)
- Show file size and type
- Allow deleting individual attachments
- Allow downloading/sharing files to other apps

### Document Preview in Records List:
- Show small thumbnail of first attachment in record list items

## After ALL changes:
1. Run: flutter pub get
2. Run: flutter analyze — fix ALL issues until 0 errors
3. Git add, commit with message "feat: complete UI redesign + document parsing", and push to origin main
