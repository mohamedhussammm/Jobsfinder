import os
import re

lib_dir = r"E:\Intsajob\Jobss\InstaJob\lib\views"

# Mapping for DarkColors
dark_color_map = {
    r"DarkColors\.background": r"AppColors.backgroundPrimary",
    r"DarkColors\.surface": r"AppColors.backgroundTertiary",  # Usually cards are tertiary
    r"DarkColors\.primary": r"AppColors.primary",
    r"DarkColors\.accent": r"AppColors.primary",
    r"DarkColors\.textPrimary": r"AppColors.textPrimary",
    r"DarkColors\.textSecondary": r"AppColors.textSecondary",
    r"DarkColors\.textTertiary": r"AppColors.textHint",
    r"DarkColors\.error": r"AppColors.error",
    r"DarkColors\.success": r"AppColors.success",
    r"DarkColors\.warning": r"AppColors.warning",
    r"DarkColors\.info": r"AppColors.info",
    r"DarkColors\.gray100": r"AppColors.backgroundSecondary",
    r"DarkColors\.gray200": r"AppColors.border",
    r"DarkColors\.borderColor": r"AppColors.border",
    r"import '../../core/theme/dark_colors\.dart';": r"import '../../core/theme/colors.dart';",
    r"import '../../../core/theme/dark_colors\.dart';": r"import '../../../core/theme/colors.dart';",
}

hardcoded_color_map = {
    r"Color\(0xFF0A0E1A\)": r"AppColors.backgroundPrimary",
    r"Color\(0xFF1C2333\)": r"AppColors.backgroundSecondary",
    r"Color\(0xFF131B2E\)": r"AppColors.backgroundSecondary",
    r"Color\(0xFF111117\)": r"AppColors.backgroundPrimary",
    r"Color\(0xFF1A1A23\)": r"AppColors.backgroundTertiary",
    r"Color\(0xFF0D1117\)": r"AppColors.backgroundPrimary",
    r"Color\(0xFF1E1E2A\)": r"AppColors.backgroundSecondary",
    r"Colors\.white\.withValues\(alpha:\s*0\.05\)": r"AppColors.border",
    r"Colors\.white\.withValues\(alpha:\s*0\.1\)": r"AppColors.borderStrong",
    r"Colors\.white\.withValues\(alpha:\s*0\.2\)": r"AppColors.glassBorder",
    r"Colors\.white\.withValues\(alpha:\s*0\.3\)": r"AppColors.textHint",
    r"Colors\.white\.withValues\(alpha:\s*0\.5\)": r"AppColors.textSecondary",
    r"Colors\.white\.withValues\(alpha:\s*0\.6\)": r"AppColors.textSecondary",
    r"Colors\.white\.withValues\(alpha:\s*0\.7\)": r"AppColors.textSecondary",
    r"Colors\.white\.withValues\(alpha:\s*0\.9\)": r"AppColors.textPrimary",
    r"Colors\.white24": r"AppColors.textHint",
    r"Colors\.white38": r"AppColors.textHint",
    r"Colors\.white54": r"AppColors.textSecondary",
    r"Colors\.white60": r"AppColors.textSecondary",
    r"Colors\.white70": r"AppColors.textSecondary",
}

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()

            original_content = content
            for old, new in dark_color_map.items():
                content = re.sub(old, new, content)

            for old, new in hardcoded_color_map.items():
                content = re.sub(old, new, content)

            # Specific text colors:
            content = content.replace("color: Colors.white,", "color: AppColors.textPrimary,")
            content = content.replace("color: Colors.white)", "color: AppColors.textPrimary)")
            
            # Theme.of(context).cardColor usually should just be AppColors.backgroundTertiary in this migration
            content = content.replace("Theme.of(context).cardColor", "AppColors.backgroundTertiary")

            if content != original_content:
                # Add import if missing
                if 'AppColors' in content and 'core/theme/colors.dart' not in content:
                    depth = filepath.replace(lib_dir, '').count(os.sep)
                    dots = '../' * (depth + 1)
                    import_statement = f"import '{dots}core/theme/colors.dart';\n"
                    # Add after material.dart
                    content = content.replace("import 'package:flutter/material.dart';", f"import 'package:flutter/material.dart';\n{import_statement}")
                
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Updated {filepath}")
