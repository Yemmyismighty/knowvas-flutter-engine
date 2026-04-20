import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../data/repositories/auth_repository_provider.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String _gender = '';
  String _city = '';
  bool _agreedToTerms = false;
  bool _isLoading = false;
  bool _citiesLoading = false;
  String? _error;
  List<String> _cities = [];

  @override
  void initState() {
    super.initState();
    // Fetch cities once user country is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchCities());
  }

  Future<void> _fetchCities() async {
    final user = ref.read(authProvider).user;
    final country = user?.country ?? 'NG';
    setState(() { _citiesLoading = true; });
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get<Map<String, dynamic>>(
        '${ApiConstants.cities}/$country',
        queryParameters: {'limit': 100},
      );
      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data!['cities'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? [];
        setState(() { _cities = list; });
      }
    } catch (_) {}
    setState(() { _citiesLoading = false; });
  }

  bool _validateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) age--;
    return age >= 13;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 13),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.brandPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() { _selectedDate = picked; _error = null; });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) { setState(() => _error = 'Date of birth is required'); return; }
    if (!_validateAge(_selectedDate!)) { setState(() => _error = 'You must be at least 13 years old'); return; }
    if (_gender.isEmpty) { setState(() => _error = 'Gender is required'); return; }
    if (_city.isEmpty) { setState(() => _error = 'City is required'); return; }
    if (!_agreedToTerms) { setState(() => _error = 'Please agree to the terms and conditions'); return; }

    setState(() { _isLoading = true; _error = null; });
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.completeProfile(
        dateOfBirth: '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
        gender: _gender,
        city: _city,
      );
      await ref.read(authProvider.notifier).fetchUserProfile();
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;
    final hPad = isSmall ? 16.0 : 20.0;
    final cardPad = isSmall ? 18.0 : 24.0;

    return Scaffold(
      backgroundColor: AppTheme.brand50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                    color: Colors.grey[700],
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 8),

                // Card
                Card(
                  elevation: 12,
                  shadowColor: AppTheme.brandPrimary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: EdgeInsets.all(cardPad),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12)],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/logo.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.menu_book_rounded, color: AppTheme.brandPrimary, size: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ShaderMask(
                                shaderCallback: (b) => const LinearGradient(
                                  colors: [AppTheme.brand600, AppTheme.brand800],
                                ).createShader(b),
                                child: Text('Knowvas',
                                    style: TextStyle(
                                        fontSize: isSmall ? 20 : 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white)),
                              ),
                            ],
                          ),
                          SizedBox(height: isSmall ? 16 : 20),

                          // Header
                          Text('Almost there! 🎉',
                              style: TextStyle(fontSize: isSmall ? 20 : 24, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 6),
                          Text(
                            'Your birthday, gender and city helps us tailor recommendations just for you.',
                            style: TextStyle(color: Colors.grey[600], fontSize: isSmall ? 12 : 13),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmall ? 16 : 20),

                          // Error
                          if (_error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Row(children: [
                                Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13))),
                              ]),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Date of Birth
                          _label('Date of Birth', isSmall),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _isLoading ? null : _pickDate,
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(children: [
                                Icon(Icons.calendar_today, color: Colors.grey[400], size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  _selectedDate == null
                                      ? 'Select date of birth'
                                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                  style: TextStyle(
                                    color: _selectedDate == null ? Colors.grey[400] : Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Gender
                          _label('Gender', isSmall),
                          const SizedBox(height: 6),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(children: [
                              Icon(Icons.people_outline, color: Colors.grey[400], size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _gender.isEmpty ? null : _gender,
                                    hint: Text('Select gender', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                                    isExpanded: true,
                                    style: const TextStyle(color: Colors.black87, fontSize: 15),
                                    items: const [
                                      DropdownMenuItem(value: 'male', child: Text('Male')),
                                      DropdownMenuItem(value: 'female', child: Text('Female')),
                                      DropdownMenuItem(value: 'other', child: Text('Other')),
                                      DropdownMenuItem(value: 'prefer-not-to-say', child: Text('Prefer not to say')),
                                    ],
                                    onChanged: _isLoading ? null : (v) => setState(() { _gender = v ?? ''; _error = null; }),
                                  ),
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 14),

                          // City
                          _label('City', isSmall),
                          const SizedBox(height: 6),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(children: [
                              Icon(Icons.location_on_outlined, color: Colors.grey[400], size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _citiesLoading
                                    ? Text('Loading cities...', style: TextStyle(color: Colors.grey[400], fontSize: 15))
                                    : _cities.isEmpty
                                        ? TextFormField(
                                            decoration: const InputDecoration(
                                              hintText: 'Enter your city',
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            style: const TextStyle(fontSize: 15),
                                            onChanged: (v) => setState(() { _city = v; _error = null; }),
                                            validator: (v) => (v == null || v.trim().isEmpty) ? 'City is required' : null,
                                          )
                                        : DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _city.isEmpty ? null : (_cities.contains(_city) ? _city : null),
                                              hint: Text('Select your city', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                                              isExpanded: true,
                                              style: const TextStyle(color: Colors.black87, fontSize: 15),
                                              items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                              onChanged: _isLoading ? null : (v) => setState(() { _city = v ?? ''; _error = null; }),
                                            ),
                                          ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 14),

                          // Terms
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 20, width: 20,
                                child: Checkbox(
                                  value: _agreedToTerms,
                                  onChanged: _isLoading ? null : (v) => setState(() => _agreedToTerms = v ?? false),
                                  activeColor: AppTheme.brandPrimary,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: 'I agree to the ',
                                    style: TextStyle(fontSize: isSmall ? 12 : 13, color: Colors.grey[600]),
                                    children: const [
                                      TextSpan(text: 'Terms of Service', style: TextStyle(color: AppTheme.brandPrimary)),
                                      TextSpan(text: ' and '),
                                      TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppTheme.brandPrimary)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isSmall ? 18 : 22),

                          // Submit
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                                shadowColor: AppTheme.brandPrimary.withOpacity(0.3),
                                disabledBackgroundColor: Colors.grey[300],
                              ),
                              child: _isLoading
                                  ? const SizedBox(height: 20, width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                                  : Text('Continue to Knowvas',
                                      style: TextStyle(fontSize: isSmall ? 14 : 15, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, bool isSmall) {
    return Text(text,
        style: TextStyle(fontSize: isSmall ? 12 : 13, fontWeight: FontWeight.w600, color: Colors.grey[700]));
  }
}
