export const meta = {
  name: 'bkdmm-flutter-fix',
  description: 'Fix Flutter project errors iteratively until flutter analyze passes with no errors',
  phases: [
    { title: 'Analyze', detail: 'Run flutter analyze to identify all errors' },
    { title: 'Fix', detail: 'Fix identified errors in parallel' },
    { title: 'Verify', detail: 'Re-run flutter analyze to confirm fixes' },
  ],
  whenToUse: 'Use when the Flutter project has compilation or analysis errors that need to be fixed iteratively',
};

// Error fixing strategies
const FIX_STRATEGIES = {
  // Import path errors
  importPath: {
    pattern: /Target of URI doesn't exist|Unable to import/,
    fix: 'Fix import paths to use correct relative paths from the file location',
  },
  // Type errors
  typeError: {
    pattern: /A value of type|Couldn't infer type|The argument type|isn't a valid override|not a subtype of/,
    fix: 'Fix type mismatches, use correct generic types, or cast values appropriately',
  },
  // Missing imports
  missingImport: {
    pattern: /Undefined name|The getter|The method|The setter|isn't defined/,
    fix: 'Add missing import statements or define the missing identifier',
  },
  // Widget errors
  widgetError: {
    pattern: /The getter 'icon' isn't defined|iconData|Widget.*IconData|too many positional arguments/,
    fix: 'Fix widget usage - wrap IconData with Icon(), use correct widget constructors',
  },
  // Deprecated API
  deprecated: {
    pattern: /deprecated|Deprecated|Use.*instead/,
    fix: 'Replace deprecated API with the recommended replacement',
  },
  // Duplicate definitions
  duplicate: {
    pattern: /duplicate|Duplicate|already defined/,
    fix: 'Remove or rename duplicate definitions',
  },
};

// Phase 1: Run flutter analyze and collect all errors
phase('Analyze');
log('Running flutter analyze to identify all errors...');

const analysisResult = await agent(`
Run flutter analyze in the Bkdmm Flutter project at F:\\projects\\Bkdmm\\bkdmm.
Capture ALL error and warning messages. Format the output as a structured list:
- File path
- Line number
- Error code
- Error message

Also run 'flutter pub get' first if needed to ensure dependencies are resolved.
Return a JSON object with:
{
  "success": boolean,
  "errors": [
    {"file": "path/to/file.dart", "line": 42, "code": "ERROR_CODE", "message": "error description", "type": "error|warning"}
  ],
  "summary": "brief summary of issues found"
}
`, { schema: {
  type: 'object',
  properties: {
    success: { type: 'boolean' },
    errors: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          file: { type: 'string' },
          line: { type: 'number' },
          code: { type: 'string' },
          message: { type: 'string' },
          type: { type: 'string' },
        },
        required: ['file', 'message'],
      },
    },
    summary: { type: 'string' },
  },
  required: ['success', 'errors'],
}});

log(`Found ${analysisResult.errors.length} issues to fix`);

if (analysisResult.errors.length === 0) {
  log('No errors found! Project is clean.');
  return { status: 'success', message: 'No errors to fix' };
}

// Phase 2: Fix errors in parallel by category
phase('Fix');

// Group errors by file for efficient fixing
const errorsByFile = {};
for (const error of analysisResult.errors) {
  const file = error.file;
  if (!errorsByFile[file]) {
    errorsByFile[file] = [];
  }
  errorsByFile[file].push(error);
}

log(`Errors grouped into ${Object.keys(errorsByFile).length} files`);

// Create fix agents for each file with errors
const fixResults = await parallel(
  Object.entries(errorsByFile).map(([file, errors]) => () =>
    agent(`
Fix all errors in the file: ${file}

Errors to fix:
${errors.map(e => `- Line ${e.line || '?'}: [${e.code}] ${e.message}`).join('\n')}

Project location: F:\\projects\\Bkdmm\\bkdmm

Read the file first, then apply fixes:
1. Fix import paths - use correct relative paths (e.g., from lib/features/home/views/home_view.dart to lib/shared/ use ../../../shared/)
2. Fix type errors - CardTheme should be CardThemeData, DialogTheme should be DialogThemeData
3. Fix widget errors - NavigationDestination.icon expects Widget, wrap IconData with Icon()
4. Add missing imports for LoadingOverlay and other referenced classes
5. Remove duplicate files or definitions

After fixing, verify the fixes are syntactically correct.

Return JSON:
{
  "file": "${file}",
  "fixed": boolean,
  "changes": ["description of each change made"],
  "remainingIssues": ["any issues that couldn't be fixed"]
}
`, {
  label: `fix:${file.split('/').pop()}`,
  phase: 'Fix',
  schema: {
    type: 'object',
    properties: {
      file: { type: 'string' },
      fixed: { type: 'boolean' },
      changes: { type: 'array', items: { type: 'string' } },
      remainingIssues: { type: 'array', items: { type: 'string' } },
    },
    required: ['file', 'fixed'],
  },
  isolation: 'worktree',
})
);

log(`Fix agents completed: ${fixResults.filter(r => r?.fixed).length}/${fixResults.length} successful`);

// Phase 3: Verify fixes with flutter analyze
phase('Verify');
log('Running flutter analyze again to verify fixes...');

const verifyResult = await agent(`
Run 'flutter analyze' in F:\\projects\\Bkdmm\\bkdmm
Report all remaining errors and warnings.

Return JSON:
{
  "passed": boolean (true if no errors),
  "errorCount": number,
  "warningCount": number,
  "remainingErrors": [
    {"file": "path", "line": number, "message": "description"}
  ]
}
`, { schema: {
  type: 'object',
  properties: {
    passed: { type: 'boolean' },
    errorCount: { type: 'number' },
    warningCount: { type: 'number' },
    remainingErrors: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          file: { type: 'string' },
          line: { type: 'number' },
          message: { type: 'string' },
        },
      },
    },
  },
  required: ['passed', 'errorCount'],
}});

if (verifyResult.passed) {
  log('All errors fixed! flutter analyze passed with no errors.');
  return {
    status: 'success',
    message: 'All errors fixed',
    filesFixed: fixResults.filter(r => r?.fixed).map(r => r.file),
  };
}

log(`Still have ${verifyResult.errorCount} errors remaining`);

// Return the result for potential retry
return {
  status: 'partial',
  message: `${verifyResult.errorCount} errors remain`,
  fixedCount: analysisResult.errors.length - verifyResult.errorCount,
  remainingErrors: verifyResult.remainingErrors,
  needsRetry: verifyResult.errorCount > 0,
};
