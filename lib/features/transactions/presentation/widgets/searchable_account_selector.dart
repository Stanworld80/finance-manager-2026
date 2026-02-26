import 'package:flutter/material.dart';
import '../add_transaction_page.dart';

class SearchableAccountSelector extends StatefulWidget {
  final String label;
  final SelectableAccount? selectedAccount;
  final List<SelectableAccount> items;
  final ValueChanged<SelectableAccount?> onChanged;
  final String? Function(SelectableAccount?)? validator;

  const SearchableAccountSelector({
    super.key,
    required this.label,
    required this.selectedAccount,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  State<SearchableAccountSelector> createState() =>
      _SearchableAccountSelectorState();
}

class _SearchableAccountSelectorState extends State<SearchableAccountSelector> {
  final TextEditingController _searchController = TextEditingController();
  List<SelectableAccount> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void didUpdateWidget(SearchableAccountSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filteredItems = widget.items;
    }
  }

  void _showSearchSheet() {
    _searchController.clear();
    _filteredItems = widget.items;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: "Rechercher...",
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setSheetState(() {
                                _filteredItems = widget.items;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            if (value.isEmpty) {
                              _filteredItems = widget.items;
                            } else {
                              _filteredItems = widget.items.where((item) {
                                final queryLower = value.toLowerCase();
                                final nameMatch = item.name
                                    .toLowerCase()
                                    .contains(queryLower);
                                final realAccMatch =
                                    item.realAccountName
                                        ?.toLowerCase()
                                        .contains(queryLower) ??
                                    false;
                                return nameMatch || realAccMatch;
                              }).toList();
                            }
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final isSelected =
                              item.id == widget.selectedAccount?.id;

                          return ListTile(
                            title: Text(item.name),
                            subtitle: item.realAccountName != null
                                ? Text(item.realAccountName!)
                                : null,
                            trailing: isSelected
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            selected: isSelected,
                            onTap: () {
                              widget.onChanged(item);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<SelectableAccount>(
      initialValue: widget.selectedAccount,
      validator: widget.validator,
      builder: (FormFieldState<SelectableAccount> state) {
        return InkWell(
          onTap: _showSearchSheet,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
              errorText: state.errorText,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.selectedAccount?.displayName ?? "Sélectionnez...",
                    style: widget.selectedAccount == null
                        ? const TextStyle(color: Colors.grey)
                        : null,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        );
      },
    );
  }
}
