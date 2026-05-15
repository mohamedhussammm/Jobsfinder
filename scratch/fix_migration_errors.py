import os
import re

lib_dir = r"E:\Intsajob\Jobss\InstaJob\lib"

# Patterns to fix
patterns = [
    # 1. Remove 'const ' before 'AppColors.'
    (r"const\s+AppColors\.", r"AppColors."),
    
    # 2. Fix the error 'The class AppColors doesn't have a constant constructor success'
    # This happens if there was something like 'const AppColors.success()' or similar.
    # But usually it's just 'const AppColors.success' which becomes 'AppColors.success'.
    
    # 3. Handle list types where AppColors is being used as a list element
    # Example: 'colors: [AppColors.successLight, AppColors.success]'
    # If the list itself is const, e.g., 'const [AppColors.successLight, AppColors.success]',
    # that would be an error if AppColors fields aren't literal constants in that context.
    # But they are static const, so 'const [AppColors.primary]' should work.
    # Wait, the error 'The element type AppColors can't be assigned to the list type Color'
    # usually means it's missing the member name, like 'colors: [AppColors, AppColors]'
    # but the error message says 'The element type AppColors...'.
    # Let's check event_details_screen.dart around line 587.
]

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # Fix 'const AppColors.'
    content = re.sub(r"const\s+AppColors\.", "AppColors.", content)
    
    # Fix potential 'AppColors()' or 'AppColors.something()' if they were meant to be static fields
    # Actually, let's just look at the specific errors.
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {filepath}")

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))
