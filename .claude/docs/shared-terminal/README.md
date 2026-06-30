# Terminal Module

## Module Overview

The `shared/terminal` module provides an embedded terminal emulator for Flutter applications, enabling users to interact with system shells (CMD, PowerShell, Bash) directly within the application UI.

### Architecture

```
terminal/
├── models/
│   ├── terminal_state.dart    # State models and enums
│   └── command_history.dart   # Command history manager
├── providers/
│   └── terminal_provider.dart # Riverpod state management
├── services/
│   └── shell_service.dart     # Shell process management
└── widgets/
    ├── terminal_shell.dart    # PTY-based terminal widget (xterm)
    └── terminal_output.dart   # Output display widget (custom)
```

### Components

| Component | Type | Description |
|-----------|------|-------------|
| `TerminalShell` | Widget | Full PTY terminal using xterm + flutter_pty |
| `TerminalOutput` | Widget | Custom output display with ANSI parsing |
| `TerminalNotifier` | Provider | Riverpod state notifier for terminal state |
| `ShellService` | Service | Process management for shell execution |
| `CommandHistory` | Model | Stores and manages command history |
| `TerminalState` | Model | Immutable terminal state container |

### Dependencies

- `flutter_riverpod` - State management
- `tdesign_flutter` - UI components
- `xterm` - Terminal emulator widget
- `flutter_pty` - PTY (pseudo-terminal) support
- `dart:io` - Process management

---

## API Index

### Models

#### `TerminalState`

```dart
class TerminalState {
  final List<TerminalLine> lines;           // Output lines
  final ShellType shellType;                // Current shell type
  final TerminalStatus status;              // Running status
  final String workingDirectory;            // Current directory
  final String? errorMessage;               // Error message
  final List<String> commandHistory;        // Command history
  final String currentInput;               // Current input buffer
  final int historyIndex;                  // History navigation index

  bool get isRunning;                       // Check if running
  bool get isStarted;                       // Check if started
  TerminalState copyWith({...});            // Create modified copy
}
```

#### `TerminalLine`

```dart
class TerminalLine {
  final String id;           // Unique identifier
  final String rawText;      // Raw text (may contain ANSI codes)
  final TerminalLineType type;  // Line type
  final DateTime timestamp;  // Creation timestamp

  bool get isCommand;        // Type == command
  bool get isError;          // Type == error
  bool get isSystem;         // Type == system
}
```

#### Enums

```dart
enum ShellType { cmd, powershell }
enum TerminalStatus { idle, starting, running, stopping, stopped, error }
enum TerminalLineType { command, output, error, system }
```

#### `CommandHistory`

```dart
class CommandHistory {
  CommandHistory({int maxSize = 100});

  List<String> get history;    // Unmodifiable history list
  int get length;
  bool get isEmpty;

  void add(String command);    // Add command to history
  void clear();                // Clear all history
  String? get(int index);      // Get command at index
  List<String> search(String pattern);  // Search history
  String? getPrevious(int currentIndex); // Navigate up
  String? getNext(int currentIndex);     // Navigate down
  String export();             // Export as text
  void import(String text);    // Import from text
}
```

---

### Services

#### `ShellService`

```dart
class ShellService {
  ShellService({String? workingDirectory, ShellType shellType = ShellType.cmd});

  bool get isRunning;
  String get workingDirectory;
  ShellType get shellType;

  // Callbacks
  void Function(String line, bool isError)? onOutput;
  void Function(int exitCode)? onExit;

  // Methods
  Future<bool> start();              // Start shell process
  void execute(String command);      // Execute command
  Future<void> stop();               // Stop shell process
  Future<bool> switchShell(ShellType newType);  // Switch shell type
  void changeDirectory(String newDirectory);    // Change working directory
  Future<void> dispose();            // Cleanup resources
}
```

---

### Providers

```dart
// Main terminal state provider
final terminalProvider = StateNotifierProvider.autoDispose<TerminalNotifier, TerminalState>;

// Convenience providers
final terminalIsRunningProvider = Provider<bool>;
final terminalLinesProvider = Provider<List<TerminalLine>>;
final terminalHistoryProvider = Provider<List<String>>;
```

#### `TerminalNotifier`

```dart
class TerminalNotifier extends StateNotifier<TerminalState> {
  TerminalNotifier({int maxLines = 500});

  // Lifecycle
  Future<void> start();                    // Start terminal
  Future<void> stop();                     // Stop terminal
  Future<void> switchShell(ShellType newType);  // Switch shell type

  // Commands
  void executeCommand(String command);      // Execute command
  void updateInput(String input);           // Update current input

  // History navigation
  void navigateHistoryUp();                 // Previous command
  void navigateHistoryDown();               // Next command

  // Output management
  void clearOutput();                       // Clear output buffer
  void clearHistory();                      // Clear command history

  // Configuration
  void setWorkingDirectory(String directory);  // Set working directory

  @override
  void dispose();                           // Cleanup
}
```

---

### Widgets

#### `TerminalShell`

Full PTY-based terminal emulator using xterm widget.

```dart
TerminalShell({super.key});
```

Features:
- Real PTY terminal with keyboard input
- Automatic shell detection (CMD on Windows, Bash on Unix)
- ANSI color support
- Resize handling
- Toolbar with clear and restart buttons
- Status indicator (running/stopped)

#### `TerminalOutput`

Custom output display widget with ANSI parsing.

```dart
TerminalOutput({super.key});
```

Features:
- ANSI color code rendering
- Line type styling (command, error, system, output)
- Auto-scroll to bottom
- Empty state display
- Selectable text

---

## Usage Examples

### Basic Terminal Widget

```dart
import 'package:bkdmm/shared/terminal/widgets/terminal_shell.dart';

// In your widget tree
TerminalShell()
```

### Terminal with State Management

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bkdmm/shared/terminal/providers/terminal_provider.dart';

class MyTerminal extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(terminalProvider);
    final notifier = ref.read(terminalProvider.notifier);

    return Column(
      children: [
        // Status bar
        Text('Status: ${state.status}'),
        Text('Shell: ${state.shellType.label}'),

        // Output display
        Expanded(child: TerminalOutput()),

        // Execute button
        ElevatedButton(
          onPressed: () => notifier.executeCommand('dir'),
          child: Text('List Files'),
        ),
      ],
    );
  }
}
```

### Shell Service Standalone

```dart
import 'package:bkdmm/shared/terminal/services/shell_service.dart';

final shell = ShellService(shellType: ShellType.powershell);

shell.onOutput = (line, isError) {
  print('${isError ? "ERROR" : "OUT"}: $line');
};

shell.onExit = (code) {
  print('Shell exited with code: $code');
};

await shell.start();
shell.execute('Get-Process');
await shell.stop();
```

---

## File Reference

| File | Path |
|------|------|
| terminal_state.dart | `bkdmm/lib/shared/terminal/models/terminal_state.dart` |
| command_history.dart | `bkdmm/lib/shared/terminal/models/command_history.dart` |
| terminal_provider.dart | `bkdmm/lib/shared/terminal/providers/terminal_provider.dart` |
| shell_service.dart | `bkdmm/lib/shared/terminal/services/shell_service.dart` |
| terminal_shell.dart | `bkdmm/lib/shared/terminal/widgets/terminal_shell.dart` |
| terminal_output.dart | `bkdmm/lib/shared/terminal/widgets/terminal_output.dart` |