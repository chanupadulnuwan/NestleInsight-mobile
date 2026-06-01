import 'package:flutter/material.dart';
import 'package:mobile/core/services/localization_service.dart';
import 'package:mobile/core/theme/app_theme.dart';

class LanguageSelectionSheet extends StatefulWidget {
  const LanguageSelectionSheet({super.key});

  @override
  State<LanguageSelectionSheet> createState() => _LanguageSelectionSheetState();
}

class _LanguageSelectionSheetState extends State<LanguageSelectionSheet> {
  late String _selectedLocale;

  @override
  void initState() {
    super.initState();
    _selectedLocale = LocalizationService.instance.currentLocale;
  }

  Future<void> _submit() async {
    await LocalizationService.instance.changeLanguage(_selectedLocale);
    if (!mounted) return;
    
    // Return the translated change language confirmation message
    final msg = LocalizationService.instance.translate('language_changed_msg');
    Navigator.of(context).pop(msg);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final languages = <({String code, String name, String subtitle})>[
      (code: 'en', name: context.translate('english'), subtitle: 'English language'),
      (code: 'si', name: context.translate('sinhala'), subtitle: 'සිංහල භාෂාව'),
      (code: 'ta', name: context.translate('tamil'), subtitle: 'தமிழ் மொழி'),
    ];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          top: 12,
          right: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 56,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.outlineWarm,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  context.translate('language_settings'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.translate('language_settings_desc'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSoft,
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  children: languages.map((lang) {
                    final isSelected = _selectedLocale == lang.code;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedLocale = lang.code;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryBrown.withAlpha(12)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryBrown
                                  : AppTheme.outlineWarm.withAlpha(95),
                              width: isSelected ? 1.8 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryBrown.withAlpha(20)
                                      : const Color(0xFFF6F3EE),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.language_rounded,
                                  color: isSelected
                                      ? AppTheme.primaryBrown
                                      : AppTheme.textSoft,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      lang.name,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: AppTheme.textDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      lang.subtitle,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSoft,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryBrown,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(context.translate('cancel')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryBrown,
                        ),
                        child: Text(context.translate('save')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
