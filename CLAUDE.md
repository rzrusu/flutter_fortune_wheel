# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter Fortune Wheel is a Flutter package that provides customizable wheel of fortune and fortune bar widgets for visualizing random selection processes. The package works across mobile, desktop, and web platforms.

## Architecture

### Core Components

The package follows a modular architecture with these main components:

- **Core (`lib/src/core/`)**: Base classes and utilities
  - `FortuneWidget`: Abstract base class for all fortune widgets
  - `FortuneItem`: Data model for items displayed in fortune widgets
  - `PanPhysics`: Gesture handling and animation physics
  - `StyleStrategy`: Item styling system
  - Animation and gesture detection utilities

- **Wheel (`lib/src/wheel/`)**: Circular fortune wheel implementation
  - `FortuneWheel`: Main wheel widget
  - `SliceClipper`, `SlicePainter`: Custom painting for wheel slices
  - `SliceLayoutDelegate`: Layout management for wheel items

- **Bar (`lib/src/bar/`)**: Horizontal fortune bar implementation
  - `FortuneBar`: Main bar widget
  - `InfiniteBar`: Infinite scrolling bar variant

- **Indicators (`lib/src/indicators/`)**: Position indicators
  - `TriangleIndicator`: Default wheel indicator
  - `RectangleIndicator`: Default bar indicator

### Key Dependencies

- `flutter_hooks`: For state management in widgets
- `quiver`: Utility functions
- `effective_dart`: Linting rules

## Development Commands

### Testing
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/fortune_wheel_test.dart
```

### Code Quality
```bash
# Run dart analyzer
flutter analyze

# Format code
dart format .

# Check for lint issues
flutter analyze
```

### Example App
The `example/` directory contains a demonstration app:

```bash
# Run example app
cd example
flutter run

# Build web version
cd example
flutter build web
```

### Publishing
```bash
# Check package health
dart pub publish --dry-run

# Publish (maintainers only)
dart pub publish
```

## Code Organization

### Widget Pattern
Fortune widgets follow a consistent pattern:
1. Extend `FortuneWidget` abstract class
2. Use `StreamController<int>` for selection state
3. Support customizable styling via `StyleStrategy`
4. Handle gestures via `PanPhysics` implementations

### Styling System
- Individual items: Use `FortuneItemStyle` on `FortuneItem`
- Batch styling: Implement `StyleStrategy` (e.g., `AlternatingStyleStrategy`)
- Common properties: colors, borders, text styles

### Physics System
Pan behavior is customizable via `PanPhysics`:
- `CircularPanPhysics`: For wheel widgets
- `DirectionalPanPhysics`: For bar widgets  
- `NoPanPhysics`: Disable dragging

## Important Files

- `lib/flutter_fortune_wheel.dart`: Main package export
- `lib/src/core/core.dart`: Core abstractions and utilities
- `analysis_options.yaml`: Lint rules (uses effective_dart)
- `example/`: Demonstration app with routing via go_router

## Testing Notes

Tests use Flutter's widget testing framework. Key test utilities are in `test/test_helpers.dart`. Tests cover:
- Widget rendering and behavior
- Custom painters and clippers
- Animation and gesture handling
- Indicator positioning