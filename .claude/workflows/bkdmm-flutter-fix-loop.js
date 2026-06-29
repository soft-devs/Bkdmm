export const meta = {
  name: 'bkdmm-flutter-fix-loop',
  description: 'Iteratively fix Flutter project errors until flutter analyze passes - loops until no errors remain',
  phases: [
    { title: 'Initialize', detail: 'Run flutter pub get to resolve dependencies' },
    { title: 'Analyze', detail: 'Run flutter analyze to identify errors' },
    { title: 'Fix', detail: 'Fix identified errors in parallel' },
    { title: 'Verify', detail: 'Verify fixes with flutter analyze' },
    { title: 'Loop', detail: 'Repeat until no errors remain' },
  ],
  whenToUse: 'Use when the Flutter project has compilation errors that need iterative fixing until clean',
};

// Phase 1: Initialize - run flutter pub get
phase('Initialize');
log('Running flutter pub get to resolve dependencies...');

const initResult = await agent(`
Run 'flutter pub get' in F:\\projects\\Bkdmm\\bkdmm
Then run 'dart run build_runner build --delete-conflicting-outputs' to generate JSON serialization code.

Report any errors from these commands.

Return JSON:
{
  "success": boolean,
  "pubGetOutput": "summary of pub get",
  "buildRunnerOutput": "summary of build_runner",
  "errors": ["any errors encountered"]
}
`, { schema: {
  type: 'object',
  properties: {
    success: { type: 'boolean' },
    pubGetOutput: { type: 'string' },
    buildRunnerOutput: { type: 'string' },
    errors: { type: 'array', items: { type: 'string' } },
  },
  required: ['success'],
}});

if (!initResult.success) {
  log('Initialization failed, but continuing to fix errors...');
}

// Loop variables
let iteration = 0;
const maxIterations = 5; // Prevent infinite loops
let hasErrors = true;
let allFixedFiles = [];

// Main fix loop
while (hasErrors && iteration < maxIterations) {
  iteration++;
  log(`\n=== Iteration ${iteration}/${maxIterations} ===\n`);

  // Phase 2: Analyze
  phase('Analyze');
  log('Running flutter analyze...');

  const analysisResult = await agent(`
Run 'flutter analyze' in F:\\projects\\Bkdmm\\bkdmm

Parse ALL error messages. For each error, extract:
- File path
- Line number (if available)
- Error code
- Error message

Return JSON:
{
  "success": boolean,
  "errorCount": number,
  "warningCount": number,
  "errors": [
    {"file": "relative/path.dart", "line": 42, "code": "CODE", "message": "description", "severity": "error|warning|info"}
  ],
  "rawOutput": "first 100 lines of raw output for debugging"
}
`, { schema: {
  type: 'object',
  properties: {
    success: { type: 'boolean' },
    errorCount: { type: 'number' },
    warningCount: { type: 'number' },
    errors: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          file: { type: 'string' },
          line: { type: 'number' },
          code: { type: 'string' },
          message: { type: 'string' },
          severity: { type: 'string' },
        },
        required: ['file', 'message'],
      },
    },
    rawOutput: { type: 'string' },
  },
  required: ['success', 'errorCount', 'errors'],
}});

  // Check if we're done
  if (analysisResult.errorCount === 0) {
    hasErrors = false;
    log('No errors found! Analysis passed.');
    break;
  }

  log(`Found ${analysisResult.errorCount} errors and ${analysisResult.warningCount} warnings`);

  // Phase 3: Fix errors
  phase('Fix');

  // Group errors by file
  const errorsByFile = {};
  for (const error of analysisResult.errors) {
    if (error.severity === 'error' || error.severity === 'warning') {
      const file = error.file;
      if (!errorsByFile[file]) {
        errorsByFile[file] = [];
      }
      errorsByFile[file].push(error);
    }
  }

  const fileCount = Object.keys(errorsByFile).length;
  log(`Fixing errors in ${fileCount} files...`);

  // Fix each file in parallel
  const fixResults = await parallel(
    Object.entries(errorsByFile).map(([file, errors]) => () =>
      agent(`
Fix ALL errors in this file: ${file}

Project root: F:\\projects\\Bkdmm\\bkdmm

Errors to fix:
${errors.map(e => `• Line ${e.line || '?'}: [${e.code || 'error'}] ${e.message}`).join('\n')}

Common fixes to apply:
1. **Import paths**: Fix relative imports
   - From lib/features/home/views/ to lib/shared/ → use ../../../shared/
   - From lib/features/home/widgets/ to lib/shared/ → use ../../../shared/
   - From lib/features/project/views/ to lib/shared/ → use ../../../shared/

2. **Type errors**:
   - CardTheme → CardThemeData (Flutter 3.x API)
   - DialogTheme → DialogThemeData (Flutter 3.x API)
   - NavigationDestination.icon needs Widget, not IconData → wrap with Icon()

3. **Missing imports**: Add imports for:
   - LoadingOverlay from ../../shared/widgets/loading_overlay.dart
   - AppScaffold from ../../shared/widgets/app_scaffold.dart
   - Any other referenced but not imported classes

4. **Duplicate files**: If file is duplicate, mark for deletion

Read the file, apply fixes, verify syntax is correct.

Return JSON:
{
  "file": "${file}",
  "success": boolean,
  "changes": ["list of changes made"],
  "remainingIssues": ["issues that couldn't be fixed"],
  "shouldDelete": boolean (if file should be deleted as duplicate)
}
`, {
  label: `fix:${file.split('/').pop()}`,
  phase: 'Fix',
  schema: {
    type: 'object',
    properties: {
      file: { type: 'string' },
      success: { type: 'boolean' },
      changes: { type: 'array', items: { type: 'string' } },
      remainingIssues: { type: 'array', items: { type: 'string' } },
      shouldDelete: { type: 'boolean' },
    },
    required: ['file', 'success'],
  },
})
  )
);

  // Log fix results
  const successful = fixResults.filter(r => r?.success).length;
  log(`Fixed ${successful}/${fixResults.length} files`);

  allFixedFiles.push(...fixResults.filter(r => r?.success).map(r => r.file));

  // Handle duplicate files
  const toDelete = fixResults.filter(r => r?.shouldDelete);
  if (toDelete.length > 0) {
    log(`Marking ${toDelete.length} duplicate files for deletion`);
    // Note: Actual deletion would be done by the fix agents
  }

  // Phase 4: Verify
  phase('Verify');
  log('Verifying fixes...');

  const verifyResult = await agent(`
Run 'flutter analyze' in F:\\projects\\Bkdmm\\bkdmm

Return JSON:
{
  "passed": boolean,
  "errorCount": number,
  "warningCount": number,
  "summary": "brief summary"
}
`, { schema: {
  type: 'object',
  properties: {
    passed: { type: 'boolean' },
    errorCount: { type: 'number' },
    warningCount: { type: 'number' },
    summary: { type: 'string' },
  },
  required: ['passed', 'errorCount'],
}});

  log(`After iteration ${iteration}: ${verifyResult.errorCount} errors, ${verifyResult.warningCount} warnings`);

  // Check if we're making progress
  if (verifyResult.errorCount === 0) {
    hasErrors = false;
    log('All errors fixed!');
  } else if (verifyResult.errorCount >= analysisResult.errorCount) {
    log('Warning: Error count did not decrease. May need manual intervention.');
    // Continue anyway, different errors might be fixable
  }
}

// Phase 5: Final status
phase('Loop');

if (!hasErrors) {
  log('\n✅ SUCCESS: All errors fixed!\n');
  return {
    status: 'success',
    iterations: iteration,
    filesFixed: allFixedFiles,
    message: 'flutter analyze passes with no errors',
  };
} else {
  log(`\n⚠️ PARTIAL: Reached max iterations (${maxIterations}), some errors may remain.\n`);
  return {
    status: 'partial',
    iterations: iteration,
    filesFixed: allFixedFiles,
    message: `Fixed ${allFixedFiles.length} files, but may have remaining errors`,
    needsRetry: true,
  };
}
