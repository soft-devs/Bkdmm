#!/usr/bin/env python3
"""
Flatten diagram_editor src directory

Remove the 'src' layer and move all files to parent directory.
"""

import os
import re
import shutil
from pathlib import Path

# 项目路径
LIB_DIR = Path('lib')
DIAGRAM_EDITOR_DIR = LIB_DIR / 'shared' / 'diagram_editor'
SRC_DIR = DIAGRAM_EDITOR_DIR / 'src'

def flatten_directory():
    """扁平化 src 目录"""
    print("=" * 70)
    print("Flattening diagram_editor/src directory")
    print("=" * 70)

    # 1. 移动所有子目录到上层
    subdirs = [d for d in SRC_DIR.iterdir() if d.is_dir()]

    for subdir in subdirs:
        target_dir = DIAGRAM_EDITOR_DIR / subdir.name
        print(f"\nMoving: {subdir} -> {target_dir}")

        # 如果目标目录已存在，合并
        if target_dir.exists():
            for file in subdir.rglob('*'):
                if file.is_file():
                    rel_path = file.relative_to(subdir)
                    target_file = target_dir / rel_path
                    target_file.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(file, target_file)
        else:
            shutil.move(str(subdir), str(target_dir))

    # 2. 移动 src 根目录下的 .dart 文件
    for file in SRC_DIR.glob('*.dart'):
        target_file = DIAGRAM_EDITOR_DIR / file.name
        print(f"Moving: {file} -> {target_file}")
        shutil.move(str(file), str(target_file))

    # 3. 删除空的 src 目录
    if SRC_DIR.exists():
        remaining = list(SRC_DIR.rglob('*'))
        if not remaining:
            SRC_DIR.rmdir()
            print(f"\nRemoved empty directory: {SRC_DIR}")
        else:
            print(f"\nWarning: {SRC_DIR} still has files:")
            for f in remaining:
                print(f"  - {f}")

    print("\n" + "=" * 70)
    print("Directory flatten completed!")
    print("=" * 70)

def update_imports():
    """更新所有导入路径"""
    print("\n" + "=" * 70)
    print("Updating import paths")
    print("=" * 70)

    # 替换规则
    rules = [
        # barrel file 的导入
        (r"export\s+['\"]src/", "export '"),
        (r"import\s+['\"]src/", "import '"),

        # src 内部文件的相对导入需要调整
        # 从 src/core/diagram_node.dart 到 core/diagram_node.dart
        # 原来是 '../core/' 现在还是 '../core/' (目录结构不变，只是少了一层 src)
    ]

    # 更新 barrel file
    barrel_file = DIAGRAM_EDITOR_DIR / 'diagram_editor.dart'
    if barrel_file.exists():
        with open(barrel_file, 'r', encoding='utf-8') as f:
            content = f.read()

        for pattern, replacement in rules:
            content = re.sub(pattern, replacement, content)

        with open(barrel_file, 'w', encoding='utf-8') as f:
            f.write(content)

        print(f"Updated: {barrel_file}")

    # 更新所有其他文件 (导入路径中包含 src/)
    for dart_file in DIAGRAM_EDITOR_DIR.rglob('*.dart'):
        if dart_file == barrel_file:
            continue

        with open(dart_file, 'r', encoding='utf-8') as f:
            content = f.read()

        original = content

        # 替换 package 导入中的 src/
        content = re.sub(
            r"package:bkdmm/shared/diagram_editor/src/",
            "package:bkdmm/shared/diagram_editor/",
            content
        )

        if content != original:
            with open(dart_file, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Updated: {dart_file}")

    print("\n" + "=" * 70)
    print("Import paths updated!")
    print("=" * 70)

def main():
    print("\n🚀 Starting diagram_editor directory flatten...")
    print(f"Source directory: {SRC_DIR}")
    print(f"Target directory: {DIAGRAM_EDITOR_DIR}")

    # 确认执行
    print("\n⚠️  This will:")
    print("  1. Move all subdirectories from src/ to parent")
    print("  2. Move all .dart files from src/ to parent")
    print("  3. Update all import paths")
    print("  4. Remove empty src/ directory")

    response = input("\nProceed? (y/n): ")
    if response.lower() != 'y':
        print("Aborted.")
        return

    # 执行
    flatten_directory()
    update_imports()

    print("\n✅ Done! Run 'flutter analyze' to verify.")

if __name__ == '__main__':
    main()