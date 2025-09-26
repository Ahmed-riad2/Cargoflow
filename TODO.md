# TODO for CustomMapWidget Fixes

## Current Task: Fix CustomMapWidget.dart

### Steps:
- [ ] Step 1: Rename the widget class and state class from MapPickerWidget to CustomMapWidget.
- [ ] Step 2: Remove the CurrentLocationLayer to resolve marker conflicts and manually handle current location marker.
- [ ] Step 3: Add minZoom: 3.0 and maxZoom: 18.0 to MapOptions for proper zooming control.
- [ ] Step 4: Replace the free-text search TextField with an Autocomplete widget using predefined ports (e.g., Port Said, Alexandria, Suez, Damietta).
- [ ] Step 5: Ensure map centers on current location at start and updates markers/polyline correctly.
- [ ] Step 6: Verify reverse geocoding and route polyline functionality.
- [ ] Step 7: Finalize and test the self-contained code.

Progress: Starting implementation.
