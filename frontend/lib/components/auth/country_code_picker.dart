import 'package:flutter/material.dart';

/// 国家区号选择器对话框
class CountryCodePicker extends StatefulWidget {
  final List<Map<String, dynamic>> countryCodes;
  final String currentCode;
  final Function(String) onSelect;
  final bool isLoading;

  const CountryCodePicker({
    Key? key,
    required this.countryCodes,
    required this.currentCode,
    required this.onSelect,
    required this.isLoading,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required List<Map<String, dynamic>> countryCodes,
    required String currentCode,
    required Function(String) onSelect,
    required bool isLoading,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CountryCodePicker(
        countryCodes: countryCodes,
        currentCode: currentCode,
        onSelect: onSelect,
        isLoading: isLoading,
      ),
    );
  }

  @override
  State<CountryCodePicker> createState() => _CountryCodePickerState();
}

class _CountryCodePickerState extends State<CountryCodePicker> {
  String _searchText = '';
  List<Map<String, dynamic>> _filteredCodes = [];
  
  @override
  void initState() {
    super.initState();
    _filteredCodes = widget.countryCodes;
  }
  
  void _filterCodes(String value) {
    setState(() {
      _searchText = value.toLowerCase();
      if (_searchText.isEmpty) {
        _filteredCodes = widget.countryCodes;
      } else {
        _filteredCodes = widget.countryCodes.where((country) {
          return country['name'].toString().toLowerCase().contains(_searchText) ||
                 country['code'].toString().toLowerCase().contains(_searchText);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '选择国家/地区',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '搜索',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: _filterCodes,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchText.isNotEmpty && _filteredCodes.isEmpty
                    ? const Center(child: Text('未找到匹配的国家/区号'))
                    : ListView.builder(
                        itemCount: _filteredCodes.length,
                        itemBuilder: (context, index) {
                          final country = _filteredCodes[index];
                          final isSelected = country['code'] == widget.currentCode;
                          
                          return ListTile(
                            leading: Text(
                              country['flag'] ?? '',
                              style: const TextStyle(fontSize: 24),
                            ),
                            title: Text(country['name']),
                            subtitle: Text(country['code']),
                            trailing: isSelected 
                                ? const Icon(Icons.check, color: Colors.blue) 
                                : null,
                            selected: isSelected,
                            selectedTileColor: Colors.blue.withOpacity(0.1),
                            onTap: () {
                              widget.onSelect(country['code']);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
