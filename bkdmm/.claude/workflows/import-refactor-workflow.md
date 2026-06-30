# Import Refactor Workflow

Refactor import paths following Flutter official style guide.

## Overview

- **Goal**: Eliminate deep relative paths (≥3 layers) and standardize import style
- **Reference**: [Flutter Style Guide](https://github.com/flutter/flutter/blob/master/docs/contributing/Style-guide-for-Flutter-repo.md)
- **Estimated Time**: 3-4 hours
- **Files Affected**: ~56 files

## Rules

```
Under lib/src, for in-folder import, use relative import.
For cross-folder import, import the entire package with absolute import.
```

| Scenario | Rule | Example |
|----------|------|---------|
| Same folder | Relative (≤1 layer) | `import 'models.dart';` |
| Parent folder | Relative (≤2 layers) | `import '../models/models.dart';` |
| Cross-module | Package absolute | `import 'package:bkdmm/shared/models/models.dart';` |

## Phases

### Phase 1: Preparation (15 min)
- [ ] Create backup branch
- [ ] Run analysis to get baseline
- [ ] Verify project is clean (no errors)

### Phase 2: Barrel Files (30 min)
- [ ] Create missing barrel files
- [ ] Update existing barrel files
- [ ] Verify exports completeness

### Phase 3: P0 Refactor - 4-layer paths (1 h)
- [ ] Refactor 19 files with 4-layer relative paths
- [ ] Run flutter analyze after each batch
- [ ] Fix any issues

### Phase 4: P1 Refactor - 3-layer paths (1.5 h)
- [ ] Refactor 38 files with 3-layer relative paths
- [ ] Run flutter analyze after each batch
- [ ] Fix any issues

### Phase 5: Verification (30 min)
- [ ] Run full flutter analyze
- [ ] Run all tests
- [ ] Verify no deep relative paths remain
- [ ] Generate final report

## Commands

```bash
# Analysis
python scripts/refactor_imports.py --analyze

# Preview changes
python scripts/refactor_imports.py --dry-run

# Execute refactor
python scripts/refactor_imports.py --execute

# Verify results
python scripts/refactor_imports.py --verify

# Flutter checks
flutter analyze
flutter test
```

## Success Criteria

- [ ] Zero files with ≥3 layer relative paths
- [ ] Zero cross-module relative imports
- [ ] `flutter analyze` passes with no errors
- [ ] All tests pass
- [ ] Import order follows convention

## Rollback

If issues arise:
```bash
git checkout backup/import-refactor
```
