import os
import re

lib_dir = r"E:\Intsajob\Jobss\InstaJob\lib"

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    new_lines = []
    seen_imports = set()
    changed = False
    
    for line in lines:
        # 1. Remove duplicate imports
        if line.strip().startswith('import '):
            import_path = line.strip()
            if import_path in seen_imports:
                changed = True
                continue
            seen_imports.add(import_path)
        
        # 2. Replace withOpacity with withValues
        if '.withOpacity(' in line:
            # Replace .withOpacity(0.5) with .withValues(alpha: 0.5)
            line = re.sub(r"\.withOpacity\((.*?)\)", r".withValues(alpha: \1)", line)
            changed = True
            
        new_lines.append(line)
    
    if changed:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        print(f"Fixed {filepath}")

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))
