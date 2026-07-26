import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myvitals_healthtracker_app/core/constants/countries.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
import 'package:myvitals_healthtracker_app/core/widgets/secondary_app_bar.dart';
import 'package:myvitals_healthtracker_app/features/profile/presentation/screens/language_selection_screen.dart'
    show WizardValidatable;
import 'package:myvitals_healthtracker_app/features/profile/presentation/widgets/profile_settings_layout.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:provider/provider.dart';

class PersonalInfoScreen extends StatefulWidget {
  /// When set, called instead of Navigator.pop() on confirm.
  /// Used by the onboarding wizard to advance to the next step.
  final VoidCallback? onNext;

  /// Whether to show the SecondaryAppBar. Defaults to true (Profile mode).
  final bool showAppBar;

  const PersonalInfoScreen({super.key, this.onNext, this.showAppBar = true});

  @override
  State<PersonalInfoScreen> createState() => PersonalInfoScreenState();
}

class PersonalInfoScreenState extends State<PersonalInfoScreen>
    with WizardValidatable {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  DateTime? _selectedDate;
  String _selectedGender = '';
  String _selectedActivityLevel = 'sedentary';
  // Prefijo del teléfono Y país del paciente a la vez: elegir '+57' ya nos dice
  // el país (captura implícita, sin campo extra). Default: locale del dispositivo.
  late Country _selectedCountry;

  // Validation error states
  bool _nameError = false;
  bool _dateError = false;
  bool _genderError = false;

  @override
  void initState() {
    super.initState();
    final prefs = Provider.of<UserProfileProvider>(context, listen: false);
    _nameController = TextEditingController(text: prefs.userName);
    _emailController = TextEditingController(text: prefs.userEmail);
    _phoneController = TextEditingController(text: prefs.userPhone);
    _selectedDate = prefs.birthDate;
    _selectedGender = prefs.userGender;
    _selectedActivityLevel = prefs.userActivityLevel;
    _selectedCountry =
        Countries.byIso(prefs.userCountryCode) ?? Countries.deviceDefault();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveCurrentState() {
    final prefs = Provider.of<UserProfileProvider>(context, listen: false);
    prefs.updatePersonalInfo(
      name: _nameController.text,
      dob: _selectedDate,
      email: _emailController.text,
      gender: _selectedGender,
      activityLevel: _selectedActivityLevel,
      phone: _phoneController.text,
      countryCode: _selectedCountry.iso,
    );
  }

  /// Bottom sheet con el catálogo de países (bandera + nombre + prefijo) y
  /// búsqueda por nombre o prefijo.
  Future<void> _pickCountry() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _CountryPickerSheet(
        title: l10n.selectCountry,
        searchHint: l10n.searchCountry,
        selected: _selectedCountry,
      ),
    );
    if (picked != null && picked.iso != _selectedCountry.iso) {
      setState(() => _selectedCountry = picked);
      _saveCurrentState();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final surfaces = Theme.of(context).surfaces;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: surfaces.brand,
              onPrimary: surfaces.onBrand,
              onSurface: surfaces.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateError = false; // Clear error on selection
      });
    }
  }

  /// Returns a list of localized error strings for required fields.
  @override
  List<String> validate(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final errors = <String>[];

    final nameEmpty = _nameController.text.trim().isEmpty;
    final dateEmpty = _selectedDate == null;
    final genderEmpty = _selectedGender.isEmpty;

    if (nameEmpty) errors.add(l10n.validationEnterName);
    if (dateEmpty) errors.add(l10n.validationSelectBirthDate);
    if (genderEmpty) errors.add(l10n.validationSelectGender);

    setState(() {
      _nameError = nameEmpty;
      _dateError = dateEmpty;
      _genderError = genderEmpty;
    });

    return errors;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;
    final prefs = Provider.of<UserProfileProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: surfaces.canvas,
      appBar: widget.showAppBar ? const SecondaryAppBar() : null,
      body: SingleChildScrollView(
        child: ProfileSettingsLayout(
          icon: Icons.badge_outlined,
          title: l10n.personalInfoTitle,
          description: l10n.personalInfoDescription,
          showConfirmButton: widget.showAppBar,
          onConfirm: () {
            if (_formKey.currentState!.validate()) {
              prefs.updatePersonalInfo(
                name: _nameController.text,
                dob: _selectedDate,
                email: _emailController.text,
                gender: _selectedGender,
                activityLevel: _selectedActivityLevel,
                phone: _phoneController.text,
                countryCode: _selectedCountry.iso,
              );
              if (widget.onNext != null) {
                widget.onNext!();
              } else {
                Navigator.pop(context);
              }
            }
          },
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Name field ---
                _buildLabel(l10n.fullName, required: true),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: _nameError
                        ? Border.all(
                            color: theme.clinical.alert.accent,
                            width: 1.5,
                          )
                        : Border.all(color: Colors.transparent),
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    onChanged: (v) {
                      if (_nameError && v.trim().isNotEmpty) {
                        setState(() => _nameError = false);
                      }
                      _saveCurrentState();
                    },
                    decoration: _inputDecoration(
                      l10n.fullName,
                      Icons.person_outline,
                      surfaces.brand,
                      hasError: _nameError,
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? '' : null,
                  ),
                ),
                if (_nameError) _buildInlineError(l10n.validationEnterName),

                const SizedBox(height: 20),

                // --- Birth date field ---
                _buildLabel(l10n.birthDate, required: true),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: _dateError
                        ? Border.all(
                            color: theme.clinical.alert.accent,
                            width: 1.5,
                          )
                        : Border.all(color: Colors.transparent),
                  ),
                  child: InkWell(
                    onTap: () async {
                      await _selectDate(context);
                      _saveCurrentState();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: IgnorePointer(
                      child: TextFormField(
                        decoration: _inputDecoration(
                          _selectedDate == null
                              ? l10n.selectDate
                              : DateFormat(
                                  'dd / MM / yyyy',
                                ).format(_selectedDate!),
                          Icons.calendar_today_outlined,
                          surfaces.brand,
                          hasError: _dateError,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_dateError)
                  _buildInlineError(l10n.validationSelectBirthDate),

                const SizedBox(height: 20),

                // --- Email (optional) ---
                _buildLabel(l10n.emailOptional, required: false),
                TextFormField(
                  controller: _emailController,
                  onChanged: (_) => _saveCurrentState(),
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    'email@ejemplo.com',
                    Icons.email_outlined,
                    surfaces.brand,
                  ),
                ),

                const SizedBox(height: 20),

                // --- Phone with country prefix (optional) ---
                // El picker de prefijo captura además el país del paciente
                // (WhatsApp/marketing) sin pedirlo como campo aparte.
                _buildLabel(l10n.phoneOptional, required: false),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: _pickCountry,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: surfaces.inset,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedCountry.flag,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _selectedCountry.dialCode,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: surfaces.ink,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              color: surfaces.inkSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        onChanged: (_) => _saveCurrentState(),
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          '300 123 4567',
                          Icons.phone_outlined,
                          surfaces.brand,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // --- Gender (required) ---
                _buildLabel(l10n.gender, required: true),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: _genderError
                      ? const EdgeInsets.all(8)
                      : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: _genderError
                        ? Border.all(
                            color: theme.clinical.alert.accent,
                            width: 1.5,
                          )
                        : Border.all(color: Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      _GenderOption(
                        label: l10n.male,
                        icon: Icons.male,
                        isSelected: _selectedGender == 'male',
                        selectedColor: surfaces.brand,
                        onTap: () {
                          setState(() {
                            _selectedGender = 'male';
                            _genderError = false;
                          });
                          _saveCurrentState();
                        },
                      ),
                      const SizedBox(width: 16),
                      _GenderOption(
                        label: l10n.female,
                        icon: Icons.female,
                        isSelected: _selectedGender == 'female',
                        selectedColor: surfaces.brand,
                        onTap: () {
                          setState(() {
                            _selectedGender = 'female';
                            _genderError = false;
                          });
                          _saveCurrentState();
                        },
                      ),
                    ],
                  ),
                ),
                if (_genderError)
                  _buildInlineError(l10n.validationSelectGender),

                const SizedBox(height: 20),

                // --- Activity level (optional) ---
                _buildLabel(l10n.activityLevel, required: false),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ActivityLevelOption(
                        label: l10n.activitySedentary,
                        icon: Icons.chair_outlined,
                        value: 'sedentary',
                        selectedValue: _selectedActivityLevel,
                        selectedColor: surfaces.inkSecondary,
                        onTap: () {
                          setState(() => _selectedActivityLevel = 'sedentary');
                          _saveCurrentState();
                        },
                      ),
                      const SizedBox(width: 12),
                      _ActivityLevelOption(
                        label: l10n.activityLightlyActive,
                        icon: Icons.directions_walk,
                        value: 'lightly_active',
                        selectedValue: _selectedActivityLevel,
                        selectedColor: theme.clinical.optimal.accent,
                        onTap: () {
                          setState(
                            () => _selectedActivityLevel = 'lightly_active',
                          );
                          _saveCurrentState();
                        },
                      ),
                      const SizedBox(width: 12),
                      _ActivityLevelOption(
                        label: l10n.activityModeratelyActive,
                        icon: Icons.directions_bike_outlined,
                        value: 'moderately_active',
                        selectedValue: _selectedActivityLevel,
                        selectedColor: surfaces.brand,
                        onTap: () {
                          setState(
                            () => _selectedActivityLevel = 'moderately_active',
                          );
                          _saveCurrentState();
                        },
                      ),
                      const SizedBox(width: 12),
                      _ActivityLevelOption(
                        label: l10n.activityVeryActive,
                        icon: Icons.directions_run,
                        value: 'very_active',
                        selectedValue: _selectedActivityLevel,
                        selectedColor: surfaces.brand,
                        onTap: () {
                          setState(
                            () => _selectedActivityLevel = 'very_active',
                          );
                          _saveCurrentState();
                        },
                      ),
                      const SizedBox(width: 12),
                      _ActivityLevelOption(
                        label: l10n.activityExtraActive,
                        icon: Icons.fitness_center,
                        value: 'extra_active',
                        selectedValue: _selectedActivityLevel,
                        selectedColor: theme.clinical.alert.accent,
                        onTap: () {
                          setState(
                            () => _selectedActivityLevel = 'extra_active',
                          );
                          _saveCurrentState();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Label with optional red asterisk for required fields.
  Widget _buildLabel(String text, {bool required = false}) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: surfaces.inkSecondary,
            ),
          ),
          if (required) ...[
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.clinical.alert.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Small inline error hint below a field.
  Widget _buildInlineError(String message) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 13,
            color: theme.clinical.alert.accent,
          ),
          const SizedBox(width: 4),
          Text(
            message,
            style: TextStyle(
              fontSize: 11,
              color: theme.clinical.alert.accent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
    Color iconColor, {
    bool hasError = false,
  }) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: hasError ? theme.clinical.alert.accent : iconColor,
        size: 20,
      ),
      filled: true,
      fillColor: hasError ? theme.clinical.alert.surface : surfaces.inset,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: hasError ? theme.clinical.alert.accent : surfaces.brand,
          width: 1.5,
        ),
      ),
      errorStyle: const TextStyle(height: 0),
    );
  }
}

class _ActivityLevelOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String selectedValue;
  final Color selectedColor;
  final VoidCallback onTap;

  const _ActivityLevelOption({
    required this.label,
    required this.icon,
    required this.value,
    required this.selectedValue,
    required this.selectedColor,
    required this.onTap,
  });

  bool get isSelected => value == selectedValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : surfaces.inset,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : surfaces.divider,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.20)
                    : selectedColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : selectedColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : surfaces.inkSecondary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selector de país (bandera + nombre + prefijo) con búsqueda. Devuelve el
/// [Country] elegido vía Navigator.pop.
class _CountryPickerSheet extends StatefulWidget {
  final String title;
  final String searchHint;
  final Country selected;

  const _CountryPickerSheet({
    required this.title,
    required this.searchHint,
    required this.selected,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final query = _query.trim().toLowerCase();
    final results = query.isEmpty
        ? Countries.all
        : Countries.all
              .where(
                (c) =>
                    c.name.toLowerCase().contains(query) ||
                    c.dialCode.contains(query),
              )
              .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: surfaces.inkMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: surfaces.ink,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  autofocus: false,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: surfaces.inkSecondary,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: surfaces.inset,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final country = results[i];
                    final isSelected = country.iso == widget.selected.iso;
                    return ListTile(
                      onTap: () => Navigator.pop(context, country),
                      leading: Text(
                        country.flag,
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: Text(
                        country.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: surfaces.ink,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            country.dialCode,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: surfaces.inkSecondary,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle_rounded,
                              color: theme.clinical.optimal.accent,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Expanded(
      child: Center(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 120,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? selectedColor : surfaces.inset,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? selectedColor : surfaces.divider,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : surfaces.inkSecondary,
                  size: 26,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : surfaces.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
