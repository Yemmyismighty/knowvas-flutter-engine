import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/platform/reader_dtos.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/reader_provider.dart';

/// Enhanced reader settings panel with beautiful UI and comprehensive options
/// Includes all Readium features: themes, fonts, layout, scrolling, etc.
class EnhancedReaderSettings extends ConsumerStatefulWidget {
  const EnhancedReaderSettings({super.key});

  @override
  ConsumerState<EnhancedReaderSettings> createState() =>
      _EnhancedReaderSettingsState();
}

class _EnhancedReaderSettingsState extends ConsumerState<EnhancedReaderSettings>
    with SingleTickerProviderStateMixin {
  late ReaderPreferences _preferences;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize with current preferences
    final readerState = ref.read(readerProvider);
    _preferences = readerState.preferences;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readerState = ref.watch(readerProvider);
    final contentType = readerState.contentType;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          _buildTabBar(context, contentType),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDisplayTab(contentType),
                _buildLayoutTab(contentType),
                _buildBehaviorTab(contentType),
              ],
            ),
          ),
          _buildApplyButton(context),
        ],
      ),
    );
  } 
 Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.brandPrimary,
            AppTheme.brand600,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: const Icon(
              Icons.tune,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reading Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customize your reading experience',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, String? contentType) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.brandPrimary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.brandPrimary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: AppTheme.fontFamily,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.palette_outlined),
            text: 'Display',
          ),
          Tab(
            icon: Icon(Icons.view_column_outlined),
            text: 'Layout',
          ),
          Tab(
            icon: Icon(Icons.touch_app_outlined),
            text: 'Behavior',
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayTab(String? contentType) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThemeSelector(contentType),
          const SizedBox(height: AppTheme.spacing24),
          
          if (contentType == 'epub') ...[
            _buildFontSettings(),
            const SizedBox(height: AppTheme.spacing24),
            _buildTextSettings(),
            const SizedBox(height: AppTheme.spacing24),
          ],
          
          _buildBrightnessSettings(),
        ],
      ),
    );
  }

  Widget _buildLayoutTab(String? contentType) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLayoutModeSelector(contentType),
          const SizedBox(height: AppTheme.spacing24),
          
          if (contentType == 'epub') ...[
            _buildScrollingModeSelector(),
            const SizedBox(height: AppTheme.spacing24),
            _buildMarginSettings(),
            const SizedBox(height: AppTheme.spacing24),
          ],
          
          _buildOrientationSettings(),
        ],
      ),
    );
  }

  Widget _buildBehaviorTab(String? contentType) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNavigationSettings(),
          const SizedBox(height: AppTheme.spacing24),
          _buildAnimationSettings(),
          const SizedBox(height: AppTheme.spacing24),
          _buildAccessibilitySettings(),
        ],
      ),
    );
  }  
Widget _buildThemeSelector(String? contentType) {
    final theme = _preferences.theme ?? 'light';
    
    return _buildSettingsSection(
      title: 'Reading Theme',
      subtitle: 'Choose your preferred reading environment',
      child: Wrap(
        spacing: AppTheme.spacing12,
        runSpacing: AppTheme.spacing8,
        children: [
          _buildThemeOption(
            label: 'Light',
            value: 'light',
            currentValue: theme,
            backgroundColor: Colors.white,
            textColor: Colors.black,
            borderColor: Colors.grey[300]!,
          ),
          if (contentType == 'epub')
            _buildThemeOption(
              label: 'Sepia',
              value: 'sepia',
              currentValue: theme,
              backgroundColor: AppTheme.sepiaBackground,
              textColor: AppTheme.sepiaText,
              borderColor: AppTheme.sepiaTextSecondary.withOpacity(0.3),
            ),
          _buildThemeOption(
            label: 'Dark',
            value: 'dark',
            currentValue: theme,
            backgroundColor: const Color(0xFF1E1E1E),
            textColor: Colors.white,
            borderColor: Colors.grey[600]!,
          ),
          _buildThemeOption(
            label: 'Black',
            value: 'black',
            currentValue: theme,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            borderColor: Colors.grey[700]!,
          ),
        ],
      ),
    );
  }

  Widget _buildFontSettings() {
    return Column(
      children: [
        _buildFontFamilySelector(),
        const SizedBox(height: AppTheme.spacing20),
        _buildFontSizeSlider(),
      ],
    );
  }

  Widget _buildTextSettings() {
    return Column(
      children: [
        _buildLineHeightSlider(),
        const SizedBox(height: AppTheme.spacing20),
        _buildLetterSpacingSlider(),
        const SizedBox(height: AppTheme.spacing20),
        _buildWordSpacingSlider(),
      ],
    );
  }

  Widget _buildFontFamilySelector() {
    final fontFamily = _preferences.fontFamily ?? 'serif';
    
    return _buildSettingsSection(
      title: 'Font Family',
      subtitle: 'Select your preferred typeface',
      child: Wrap(
        spacing: AppTheme.spacing8,
        runSpacing: AppTheme.spacing8,
        children: [
          _buildChoiceChip(
            label: 'Serif',
            value: 'serif',
            groupValue: fontFamily,
            onSelected: (value) {
              setState(() {
                _preferences = _preferences.copyWith(fontFamily: value);
              });
            },
          ),
          _buildChoiceChip(
            label: 'Sans Serif',
            value: 'sans-serif',
            groupValue: fontFamily,
            onSelected: (value) {
              setState(() {
                _preferences = _preferences.copyWith(fontFamily: value);
              });
            },
          ),
          _buildChoiceChip(
            label: 'Monospace',
            value: 'monospace',
            groupValue: fontFamily,
            onSelected: (value) {
              setState(() {
                _preferences = _preferences.copyWith(fontFamily: value);
              });
            },
          ),
          _buildChoiceChip(
            label: 'Dyslexic',
            value: 'dyslexic',
            groupValue: fontFamily,
            onSelected: (value) {
              setState(() {
                _preferences = _preferences.copyWith(fontFamily: value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeSlider() {
    final fontSize = _preferences.fontSize ?? 16;
    
    return _buildSettingsSection(
      title: 'Font Size',
      subtitle: '${fontSize}px',
      child: _buildSlider(
        value: fontSize.toDouble(),
        min: 12,
        max: 32,
        divisions: 20,
        onChanged: (value) {
          setState(() {
            _preferences = _preferences.copyWith(fontSize: value.round());
          });
        },
        leftLabel: 'A',
        rightLabel: 'A',
        leftLabelSize: 12,
        rightLabelSize: 24,
      ),
    );
  }

  Widget _buildLineHeightSlider() {
    final lineHeight = _preferences.lineHeight ?? 1.5;
    
    return _buildSettingsSection(
      title: 'Line Height',
      subtitle: '${lineHeight.toStringAsFixed(1)}x',
      child: _buildSlider(
        value: lineHeight,
        min: 1.0,
        max: 2.5,
        divisions: 15,
        onChanged: (value) {
          setState(() {
            _preferences = _preferences.copyWith(lineHeight: value);
          });
        },
      ),
    );
  }

  Widget _buildLetterSpacingSlider() {
    final letterSpacing = _preferences.letterSpacing ?? 0.0;
    
    return _buildSettingsSection(
      title: 'Letter Spacing',
      subtitle: '${letterSpacing.toStringAsFixed(1)}px',
      child: _buildSlider(
        value: letterSpacing,
        min: -1.0,
        max: 3.0,
        divisions: 40,
        onChanged: (value) {
          setState(() {
            _preferences = _preferences.copyWith(letterSpacing: value);
          });
        },
      ),
    );
  }

  Widget _buildWordSpacingSlider() {
    final wordSpacing = _preferences.wordSpacing ?? 0.0;
    
    return _buildSettingsSection(
      title: 'Word Spacing',
      subtitle: '${wordSpacing.toStringAsFixed(1)}px',
      child: _buildSlider(
        value: wordSpacing,
        min: -2.0,
        max: 5.0,
        divisions: 35,
        onChanged: (value) {
          setState(() {
            _preferences = _preferences.copyWith(wordSpacing: value);
          });
        },
      ),
    );
  }

  Widget _buildBrightnessSettings() {
    final brightness = _preferences.brightness ?? 1.0;
    
    return _buildSettingsSection(
      title: 'Screen Brightness',
      subtitle: '${(brightness * 100).round()}%',
      child: _buildSlider(
        value: brightness,
        min: 0.3,
        max: 1.0,
        divisions: 14,
        onChanged: (value) {
          setState(() {
            _preferences = _preferences.copyWith(brightness: value);
          });
        },
        leftIcon: Icons.brightness_low,
        rightIcon: Icons.brightness_high,
      ),
    );
  }

  Widget _buildLayoutModeSelector(String? contentType) {
    final layout = _preferences.layout ?? 'single';
    
    return _buildSettingsSection(
      title: 'Page Layout',
      subtitle: 'Choose how pages are displayed',
      child: Column(
        children: [
          _buildLayoutOption(
            title: 'Single Page',
            subtitle: 'One page at a time',
            value: 'single',
            currentValue: layout,
            icon: Icons.crop_portrait,
          ),
          const SizedBox(height: AppTheme.spacing8),
          _buildLayoutOption(
            title: 'Double Page',
            subtitle: 'Two pages side by side',
            value: 'double',
            currentValue: layout,
            icon: Icons.chrome_reader_mode,
          ),
          if (contentType == 'epub') ...[
            const SizedBox(height: AppTheme.spacing8),
            _buildLayoutOption(
              title: 'Continuous Scroll',
              subtitle: 'Scroll through content',
              value: 'scroll',
              currentValue: layout,
              icon: Icons.view_stream,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScrollingModeSelector() {
    final scrollMode = _preferences.scrollMode ?? 'vertical';
    
    return _buildSettingsSection(
      title: 'Scrolling Direction',
      subtitle: 'Choose scroll direction for continuous mode',
      child: Wrap(
        spacing: AppTheme.spacing8,
        children: [
          _buildChoiceChip(
            label: 'Vertical',
            value: 'vertical',
            groupValue: scrollMode,
            onSelected: (value) {
              setState(() {
                _preferences = _preferences.copyWith(scrollMode: value);
              });
            },
          ),
          _buildChoiceChip(
            label: 'Horizontal',
            value: 'horizontal',
            groupValue: scrollMode,
            onSelected: (value) {
              setState(() {
                _preferences = _preferences.copyWith(scrollMode: value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMarginSettings() {
    final margin = _preferences.margin ?? 1.0;
    
    return _buildSettingsSection(
      title: 'Page Margins',
      subtitle: 'Adjust reading area width',
      child: _buildSlider(
        value: margin,
        min: 0.5,
        max: 2.0,
        divisions: 15,
        onChanged: (value) {
          setState(() {
            _preferences = _preferences.copyWith(margin: value);
          });
        },
        leftIcon: Icons.format_indent_decrease,
        rightIcon: Icons.format_indent_increase,
      ),
    );
  }

  Widget _buildOrientationSettings() {
    final orientation = _preferences.orientation ?? 'auto';
    
    return _buildSettingsSection(
      title: 'Screen Orientation',
      subtitle: 'Lock orientation or allow rotation',
      child: Wrap(
        spacing: AppTheme.spacing8,
        children: [
          _buildChoiceChip(
            label: 'Auto',
            value: 'auto',
            groupValue: orientation,
            onSelected: (value) {
              setState(() {
                _preferences = _preferences.copyWith(orientation: value);
              });
            },
          ),
          _buildChoiceChip(
            label: 'Portrait',
            value: 'portrait',
            groupValue: orientation,
            onSelected: (value) {
              setState(() {
                _preferences = _preferences.copyWith(orientation: value);
              });
            },
          ),
          _buildChoiceChip(
            label: 'Landscape',
            value: 'landscape',
            groupValue: orientation,
            onSelected: (value) {
              setState(() {
                _preferences = _preferences.copyWith(orientation: value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSettings() {
    final tapToTurn = _preferences.tapToTurn ?? true;
    final volumeKeys = _preferences.volumeKeyNavigation ?? false;
    
    return _buildSettingsSection(
      title: 'Navigation',
      subtitle: 'Configure how you navigate through pages',
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Tap to Turn Pages',
            subtitle: 'Tap screen edges to navigate',
            value: tapToTurn,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(tapToTurn: value);
              });
            },
          ),
          _buildSwitchTile(
            title: 'Volume Key Navigation',
            subtitle: 'Use volume buttons to turn pages',
            value: volumeKeys,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(volumeKeyNavigation: value);
              });
            },
          ),
        ],
      ),
    );
  }  Widget
 _buildAnimationSettings() {
    final animations = _preferences.pageTransitionAnimation ?? true;
    final animationSpeed = _preferences.animationSpeed ?? 1.0;
    
    return _buildSettingsSection(
      title: 'Animations',
      subtitle: 'Configure page transition effects',
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Page Animations',
            subtitle: 'Enable smooth page transitions',
            value: animations,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(pageTransitionAnimation: value);
              });
            },
          ),
          if (animations) ...[
            const SizedBox(height: AppTheme.spacing16),
            _buildSlider(
              value: animationSpeed,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences.copyWith(animationSpeed: value);
                });
              },
              label: 'Animation Speed: ${animationSpeed.toStringAsFixed(1)}x',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccessibilitySettings() {
    final highContrast = _preferences.highContrast ?? false;
    final reduceMotion = _preferences.reduceMotion ?? false;
    
    return _buildSettingsSection(
      title: 'Accessibility',
      subtitle: 'Options for better readability',
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'High Contrast',
            subtitle: 'Increase text contrast for better visibility',
            value: highContrast,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(highContrast: value);
              });
            },
          ),
          _buildSwitchTile(
            title: 'Reduce Motion',
            subtitle: 'Minimize animations and transitions',
            value: reduceMotion,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(reduceMotion: value);
              });
            },
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildSettingsSection({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ],
        const SizedBox(height: AppTheme.spacing12),
        child,
      ],
    );
  }

  Widget _buildThemeOption({
    required String label,
    required String value,
    required String currentValue,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
  }) {
    final isSelected = value == currentValue;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _preferences = _preferences.copyWith(theme: value);
        });
      },
      child: Container(
        width: 80,
        height: 60,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: isSelected ? AppTheme.brandPrimary : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Aa',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutOption({
    required String title,
    required String subtitle,
    required String value,
    required String currentValue,
    required IconData icon,
  }) {
    final isSelected = value == currentValue;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _preferences = _preferences.copyWith(layout: value);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.brandPrimary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected 
                ? AppTheme.brandPrimary 
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.brandPrimary 
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.brandPrimary : null,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.brandPrimary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required String value,
    required String groupValue,
    required ValueChanged<String> onSelected,
  }) {
    final isSelected = value == groupValue;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onSelected(value);
        }
      },
      backgroundColor: Colors.grey[100],
      selectedColor: AppTheme.brandPrimary.withOpacity(0.2),
      checkmarkColor: AppTheme.brandPrimary,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.brandPrimary : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontFamily: AppTheme.fontFamily,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.brandPrimary : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _buildSlider({
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
    String? leftLabel,
    String? rightLabel,
    double? leftLabelSize,
    double? rightLabelSize,
    IconData? leftIcon,
    IconData? rightIcon,
    String? label,
  }) {
    return Column(
      children: [
        if (label != null) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
        ],
        Row(
          children: [
            if (leftLabel != null)
              Text(
                leftLabel,
                style: TextStyle(
                  fontSize: leftLabelSize ?? 14,
                  color: Colors.grey[600],
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            if (leftIcon != null)
              Icon(
                leftIcon,
                size: 20,
                color: Colors.grey[600],
              ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.brandPrimary,
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: AppTheme.brandPrimary,
                  overlayColor: AppTheme.brandPrimary.withOpacity(0.2),
                  trackHeight: 4.0,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8.0,
                  ),
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: onChanged,
                ),
              ),
            ),
            if (rightLabel != null)
              Text(
                rightLabel,
                style: TextStyle(
                  fontSize: rightLabelSize ?? 14,
                  color: Colors.grey[600],
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            if (rightIcon != null)
              Icon(
                rightIcon,
                size: 20,
                color: Colors.grey[600],
              ),
          ],
        ),
      ],
    );
  }  Widget
 _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.brandPrimary,
            activeTrackColor: AppTheme.brandPrimary.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                // Reset to defaults
                setState(() {
                  _preferences = ReaderPreferences();
                });
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[400]!),
              ),
              child: const Text(
                'Reset to Defaults',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () async {
                // Apply preferences through the reader provider
                await ref.read(readerProvider.notifier).updatePreferences(_preferences);

                if (context.mounted) {
                  // Show success feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Settings applied successfully',
                            style: TextStyle(fontFamily: AppTheme.fontFamily),
                          ),
                        ],
                      ),
                      backgroundColor: AppTheme.success,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                    ),
                  );

                  // Close the settings panel
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: const Text(
                'Apply Settings',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}