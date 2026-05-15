import re

path = r'E:\Intsajob\Jobss\InstaJob\lib\views\home\event_details_screen.dart'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    (r"import '../../core/theme/dark_colors\.dart';", r"import '../../core/theme/colors.dart';"),
    (r"DarkColors\.surface", r"AppColors.backgroundTertiary"),
    (r"DarkColors\.error", r"AppColors.error"),
    (r"DarkColors\.textSecondary", r"AppColors.textSecondary"),
    (r"DarkColors\.textTertiary", r"AppColors.textHint"),
    (r"DarkColors\.accent", r"AppColors.primary"),
    (r"DarkColors\.primary", r"AppColors.primary"),
    
    (r"Colors\.white\.withValues\(alpha:\s*0\.07\)", r"AppColors.border"),
    (r"Colors\.white\.withValues\(alpha:\s*0\.08\)", r"AppColors.borderStrong"),
    (r"Colors\.white\.withValues\(alpha:\s*0\.15\)", r"AppColors.glassBorder"),
    (r"Colors\.white\.withValues\(alpha:\s*0\.18\)", r"AppColors.glassBorder"),
    (r"Colors\.white\.withValues\(alpha:\s*0\.3\)", r"AppColors.textHint"),
    (r"Colors\.white\.withValues\(alpha:\s*0\.45\)", r"AppColors.textSecondary"),
    (r"Colors\.white\.withValues\(alpha:\s*0\.55\)", r"AppColors.textSecondary"),
    (r"Colors\.white\.withValues\(alpha:\s*0\.72\)", r"AppColors.textSecondary"),
    (r"Colors\.white\.withValues\(alpha:\s*0\.5\)", r"AppColors.textSecondary"),
    (r"Colors\.white\.withValues\(alpha:\s*0\.04\)", r"AppColors.border"),
    
    (r"Color\(0xFF1E4D6B\)", r"AppColors.primaryDark"),
    (r"Color\(0xFF0D1117\)", r"AppColors.backgroundPrimary"),
    (r"Color\(0xFF60A5FA\)", r"AppColors.primary"),
    (r"Color\(0xFFF87171\)", r"AppColors.error"),
    (r"Color\(0xFF4ADE80\)", r"AppColors.success"),
    (r"Color\(0xFFFBBF24\)", r"AppColors.warning"),
    (r"Colors\.white70", r"AppColors.textSecondary"),
    
    # Hero gradient colors
    (r"Color\(0xFF0F4C35\)", r"AppColors.successLight"),
    (r"Color\(0xFF1A6B4A\)", r"AppColors.success"),
    (r"Color\(0xFF4C3A0F\)", r"AppColors.warningLight"),
    (r"Color\(0xFF6B541A\)", r"AppColors.warning"),
    (r"Color\(0xFF0F2A4C\)", r"AppColors.infoLight"),
    (r"Color\(0xFF1A3F6B\)", r"AppColors.info"),
    (r"Color\(0xFF1A1A2E\)", r"AppColors.backgroundSecondary"),
    (r"Color\(0xFF16213E\)", r"AppColors.backgroundPrimary"),
    
    # Tags
    (r"Color\(0xFF3A1A1A\)", r"AppColors.errorLight"),
    (r"Color\(0xFF1A3A2A\)", r"AppColors.accentLight"),
    (r"Color\(0xFF1A2A3A\)", r"AppColors.infoLight"),
    (r"Color\(0xFF2A1A3A\)", r"AppColors.primaryLight"),
    (r"Color\(0xFFA78BFA\)", r"AppColors.primaryDark"),
    (r"Color\(0xFF1A2A2A\)", r"AppColors.backgroundSecondary"),
    (r"Color\(0xFF67E8F9\)", r"AppColors.primary"),
    (r"Color\(0xFF34D399\)", r"AppColors.success"),
    
    (r"Colors\.white38", r"AppColors.textHint"),
]

for old, new in replacements:
    content = re.sub(old, new, content)

# Specific white text color replacements, carefully not to break other stuff
content = content.replace("color: Colors.white,", "color: AppColors.textPrimary,")
content = content.replace("color: Colors.white)", "color: AppColors.textPrimary)")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Replaced colors in event_details_screen.dart")
