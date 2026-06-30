#!/usr/bin/env python3
"""
Bkdmm 导入路径重构工具

功能:
1. 分析当前导入状态
2. 自动替换深层相对路径为 package 路径
3. 验证重构结果
4. 生成重构报告

使用方法:
    python scripts/refactor_imports.py --analyze     # 分析当前状态
    python scripts/refactor_imports.py --dry-run    # 预览变更 (不实际修改)
    python scripts/refactor_imports.py --execute    # 执行重构
    python scripts/refactor_imports.py --verify     # 验证结果
"""

import os
import re
import sys
import argparse
from pathlib import Path
from collections import defaultdict
from typing import List, Tuple, Dict

# 项目配置
PACKAGE_NAME = 'bkdmm'
LIB_DIR = Path('lib')

# 替换规则: (相对路径模式, package路径)
REFACTOR_RULES = [
    # 4层相对路径
    (r"import\s+['\"]\.\.\/\.\.\/\.\.\/\.\.\/shared\/", f"import 'package:{PACKAGE_NAME}/shared/"),
    (r"import\s+['\"]\.\.\/\.\.\/\.\.\/\.\.\/core\/", f"import 'package:{PACKAGE_NAME}/core/"),
    (r"import\s+['\"]\.\.\/\.\.\/\.\.\/\.\.\/utils\/", f"import 'package:{PACKAGE_NAME}/utils/"),
    (r"import\s+['\"]\.\.\/\.\.\/\.\.\/\.\.\/l10n\/", f"import 'package:{PACKAGE_NAME}/l10n/"),

    # 3层相对路径
    (r"import\s+['\"]\.\.\/\.\.\/\.\.\/shared\/", f"import 'package:{PACKAGE_NAME}/shared/"),
    (r"import\s+['\"]\.\.\/\.\.\/\.\.\/core\/", f"import 'package:{PACKAGE_NAME}/core/"),
    (r"import\s+['\"]\.\.\/\.\.\/\.\.\/utils\/", f"import 'package:{PACKAGE_NAME}/utils/"),
    (r"import\s+['\"]\.\.\/\.\.\/\.\.\/l10n\/", f"import 'package:{PACKAGE_NAME}/l10n/"),

    # 2层相对路径 (仅针对跨模块场景)
    (r"import\s+['\"]\.\.\/\.\.\/l10n\/", f"import 'package:{PACKAGE_NAME}/l10n/"),
]


class ImportAnalyzer:
    """导入分析器"""

    def __init__(self):
        self.stats = {
            'total_files': 0,
            'total_imports': 0,
            'relative_imports': 0,
            'package_imports': 0,
            'dart_imports': 0,
            'depth_distribution': defaultdict(int),
            'deep_import_files': [],
            'cross_module_imports': [],
        }

    def analyze_file(self, filepath: Path) -> Dict:
        """分析单个文件的导入"""
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        imports = re.findall(r"^import\s+['\"]([^'\"]+)['\"]", content, re.MULTILINE)

        file_stats = {
            'filepath': str(filepath),
            'imports': imports,
            'deep_imports': [],
            'needs_refactor': False,
        }

        for imp in imports:
            if imp.startswith('dart:'):
                self.stats['dart_imports'] += 1
            elif imp.startswith('package:'):
                self.stats['package_imports'] += 1
            elif imp.startswith('../'):
                self.stats['relative_imports'] += 1
                depth = imp.count('../')
                self.stats['depth_distribution'][depth] += 1

                if depth >= 3:
                    file_stats['deep_imports'].append(imp)
                    file_stats['needs_refactor'] = True

                    # 检测跨模块导入
                    if 'features' in str(filepath) and 'shared' in imp:
                        self.stats['cross_module_imports'].append((str(filepath), imp))

        if file_stats['needs_refactor']:
            self.stats['deep_import_files'].append(str(filepath))

        return file_stats

    def analyze_all(self) -> Dict:
        """分析所有文件"""
        self.stats['total_files'] = 0
        self.stats['total_imports'] = 0

        for dart_file in LIB_DIR.rglob('*.dart'):
            self.stats['total_files'] += 1
            file_stats = self.analyze_file(dart_file)
            self.stats['total_imports'] += len(file_stats['imports'])

        return self.stats

    def print_report(self):
        """打印分析报告"""
        print("=" * 70)
        print("Bkdmm Import Analysis Report")
        print("=" * 70)
        print(f"\nTotal Files: {self.stats['total_files']}")
        print(f"Total Imports: {self.stats['total_imports']}")

        print(f"\nImport Type Distribution:")
        print(f"   * dart: SDK imports:      {self.stats['dart_imports']:4d}")
        print(f"   * package: imports:       {self.stats['package_imports']:4d}")
        print(f"   * Relative path imports:  {self.stats['relative_imports']:4d}")

        print(f"\nRelative Path Depth Distribution:")
        for depth in sorted(self.stats['depth_distribution'].keys()):
            count = self.stats['depth_distribution'][depth]
            pct = count / self.stats['relative_imports'] * 100 if self.stats['relative_imports'] > 0 else 0
            status = "[OK]" if depth <= 2 else "[WARN]" if depth == 3 else "[ERROR]"
            print(f"   {status} {depth} layers: {count:4d} ({pct:5.1f}%)")

        deep_count = len(self.stats['deep_import_files'])
        cross_count = len(self.stats['cross_module_imports'])
        print(f"\nIssues Found:")
        print(f"   * Deep relative paths (>=3):  {deep_count:4d} files")
        print(f"   * Cross-module imports:       {cross_count:4d} files")

        if deep_count > 0:
            print(f"\nFiles Needing Refactor:")
            for filepath in self.stats['deep_import_files'][:10]:  # 只显示前10个
                print(f"   - {filepath}")
            if len(self.stats['deep_import_files']) > 10:
                print(f"   ... and {len(self.stats['deep_import_files']) - 10} more files")


class ImportRefactorer:
    """导入重构器"""

    def __init__(self, dry_run: bool = True):
        self.dry_run = dry_run
        self.changes = []

    def refactor_file(self, filepath: Path) -> Tuple[bool, str]:
        """重构单个文件的导入"""
        with open(filepath, 'r', encoding='utf-8') as f:
            original = f.read()

        modified = original
        file_changes = []

        for pattern, replacement in REFACTOR_RULES:
            matches = re.findall(pattern, modified)
            if matches:
                modified = re.sub(pattern, replacement, modified)
                file_changes.extend(matches)

        if modified != original:
            self.changes.append((str(filepath), file_changes))

            if not self.dry_run:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(modified)

            return True, modified

        return False, original

    def refactor_all(self) -> List[Tuple[str, List]]:
        """重构所有文件"""
        for dart_file in LIB_DIR.rglob('*.dart'):
            self.refactor_file(dart_file)

        return self.changes

    def print_changes(self):
        """打印变更预览"""
        print("\n" + "=" * 70)
        print("Import Refactor Preview" + (" (DRY RUN)" if self.dry_run else ""))
        print("=" * 70)

        if not self.changes:
            print("\nNo changes needed!")
            return

        print(f"\nFiles to Change: {len(self.changes)}")
        for filepath, changes in self.changes:
            print(f"\n{filepath}")
            for change in changes:
                print(f"   - {change}")

        print(f"\n{'='*70}")
        print(f"Total: {len(self.changes)} files, {sum(len(c) for _, c in self.changes)} imports")


def main():
    parser = argparse.ArgumentParser(description='Bkdmm Import Refactoring Tool')
    parser.add_argument('--analyze', action='store_true', help='Analyze current import status')
    parser.add_argument('--dry-run', action='store_true', help='Preview changes without modifying files')
    parser.add_argument('--execute', action='store_true', help='Execute refactoring')
    parser.add_argument('--verify', action='store_true', help='Verify refactoring results')

    args = parser.parse_args()

    if not any([args.analyze, args.dry_run, args.execute, args.verify]):
        parser.print_help()
        return

    if args.analyze:
        analyzer = ImportAnalyzer()
        analyzer.analyze_all()
        analyzer.print_report()

    elif args.dry_run:
        # 先分析
        analyzer = ImportAnalyzer()
        analyzer.analyze_all()
        analyzer.print_report()

        # 预览变更
        refactorer = ImportRefactorer(dry_run=True)
        refactorer.refactor_all()
        refactorer.print_changes()

    elif args.execute:
        print("Executing Import Refactoring...")

        # 执行重构
        refactorer = ImportRefactorer(dry_run=False)
        changes = refactorer.refactor_all()
        refactorer.print_changes()

        print("\nRefactoring completed!")
        print("Run 'flutter analyze' to verify the changes.")

    elif args.verify:
        print("Verifying Refactoring Results...")

        analyzer = ImportAnalyzer()
        analyzer.analyze_all()

        # 检查是否还有深层相对路径
        deep_count = len(analyzer.stats['deep_import_files'])

        if deep_count == 0:
            print("\nAll deep relative paths have been refactored!")
        else:
            print(f"\nStill have {deep_count} files with deep relative paths:")
            for filepath in analyzer.stats['deep_import_files']:
                print(f"   - {filepath}")

        analyzer.print_report()


if __name__ == '__main__':
    main()
