import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Form for creating a new reading goal
class GoalCreationForm extends StatefulWidget {
  final Function({
    required int year,
    int? targetBooks,
    int? targetPages,
    int? targetReadingTimeMinutes,
  }) onSubmit;

  const GoalCreationForm({
    super.key,
    required this.onSubmit,
  });

  @override
  State<GoalCreationForm> createState() => _GoalCreationFormState();
}

class _GoalCreationFormState extends State<GoalCreationForm> {
  final _formKey = GlobalKey<FormState>();
  final _booksController = TextEditingController();
  final _pagesController = TextEditingController();
  final _timeController = TextEditingController();
  
  late int _selectedYear;
  bool _hasBookGoal = false;
  bool _hasPagesGoal = false;
  bool _hasTimeGoal = false;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  @override
  void dispose() {
    _booksController.dispose();
    _pagesController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (!_hasBookGoal && !_hasPagesGoal && !_hasTimeGoal) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set at least one goal'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      widget.onSubmit(
        year: _selectedYear,
        targetBooks: _hasBookGoal ? int.tryParse(_booksController.text) : null,
        targetPages: _hasPagesGoal ? int.tryParse(_pagesController.text) : null,
        targetReadingTimeMinutes: _hasTimeGoal ? int.tryParse(_timeController.text) : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create Reading Goal',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          
          // Year selector
          DropdownButtonFormField<int>(
            value: _selectedYear,
            decoration: const InputDecoration(
              labelText: 'Year',
              border: OutlineInputBorder(),
            ),
            items: List.generate(5, (index) {
              final year = DateTime.now().year + index;
              return DropdownMenuItem(
                value: year,
                child: Text(year.toString()),
              );
            }),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedYear = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Books goal
          CheckboxListTile(
            title: const Text('Books Goal'),
            value: _hasBookGoal,
            onChanged: (value) {
              setState(() {
                _hasBookGoal = value ?? false;
                if (!_hasBookGoal) {
                  _booksController.clear();
                }
              });
            },
          ),
          if (_hasBookGoal)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: TextFormField(
                controller: _booksController,
                decoration: const InputDecoration(
                  labelText: 'Target Books',
                  hintText: 'e.g., 24',
                  border: OutlineInputBorder(),
                  suffixText: 'books',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (_hasBookGoal && (value == null || value.isEmpty)) {
                    return 'Please enter target books';
                  }
                  if (_hasBookGoal && int.tryParse(value!) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ),

          // Pages goal
          CheckboxListTile(
            title: const Text('Pages Goal'),
            value: _hasPagesGoal,
            onChanged: (value) {
              setState(() {
                _hasPagesGoal = value ?? false;
                if (!_hasPagesGoal) {
                  _pagesController.clear();
                }
              });
            },
          ),
          if (_hasPagesGoal)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: TextFormField(
                controller: _pagesController,
                decoration: const InputDecoration(
                  labelText: 'Target Pages',
                  hintText: 'e.g., 10000',
                  border: OutlineInputBorder(),
                  suffixText: 'pages',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (_hasPagesGoal && (value == null || value.isEmpty)) {
                    return 'Please enter target pages';
                  }
                  if (_hasPagesGoal && int.tryParse(value!) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ),

          // Reading time goal
          CheckboxListTile(
            title: const Text('Reading Time Goal'),
            value: _hasTimeGoal,
            onChanged: (value) {
              setState(() {
                _hasTimeGoal = value ?? false;
                if (!_hasTimeGoal) {
                  _timeController.clear();
                }
              });
            },
          ),
          if (_hasTimeGoal)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Target Reading Time',
                  hintText: 'e.g., 3000',
                  border: OutlineInputBorder(),
                  suffixText: 'minutes',
                  helperText: 'Approximately 50 hours',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (_hasTimeGoal && (value == null || value.isEmpty)) {
                    return 'Please enter target reading time';
                  }
                  if (_hasTimeGoal && int.tryParse(value!) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Create Goal'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
