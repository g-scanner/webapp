import 'package:flutter/material.dart';
import '../models/types.dart';

class HistoryList extends StatefulWidget {
  final List<ScanHistoryItem> history;
  final Function(String) onSelectItem;
  final Future<void> Function() onClearHistory;
  final Future<void> Function(String) onDeleteHistoryItem;

  const HistoryList({
    super.key,
    required this.history,
    required this.onSelectItem,
    required this.onClearHistory,
    required this.onDeleteHistoryItem,
  });

  @override
  State<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<HistoryList> {
  String _search = "";
  GlutenSafetyStatus? _filter;

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminare scansione?"),
        content: const Text(
          "Sei sicuro di voler eliminare questa scansione dalla tua cronologia locale?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Annulla"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onDeleteHistoryItem(id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Elimina"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredHistory = widget.history.where((item) {
      final matchesSearch =
          item.productName.toLowerCase().contains(_search.toLowerCase()) ||
          item.brand.toLowerCase().contains(_search.toLowerCase()) ||
          item.barcode.contains(_search);
      final matchesFilter = _filter == null || item.status == _filter;
      return matchesSearch && matchesFilter;
    }).toList();

    int safeCount = widget.history
        .where((h) => h.status == GlutenSafetyStatus.adatto)
        .length;
    int dangerCount = widget.history
        .where((h) => h.status == GlutenSafetyStatus.nonAdatto)
        .length;
    int uncertainCount = widget.history
        .where((h) => h.status == GlutenSafetyStatus.incerto)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      "Cronologia Scansioni",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Esplora la lista dei tuoi prodotti analizzati e memorizzati nel database locale.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),

                if (widget.history.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatBox(
                        safeCount.toString(),
                        "Sicuri",
                        Colors.green.shade50,
                        Colors.green.shade800,
                      ),
                      const SizedBox(width: 8),
                      _buildStatBox(
                        uncertainCount.toString(),
                        "Incerti",
                        Colors.orange.shade50,
                        Colors.orange.shade800,
                      ),
                      const SizedBox(width: 8),
                      _buildStatBox(
                        dangerCount.toString(),
                        "Tossici",
                        Colors.red.shade50,
                        Colors.red.shade800,
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),
                TextField(
                  onChanged: (val) => setState(() => _search = val),
                  decoration: InputDecoration(
                    hintText: "Cerca per nome, marca o barcode...",
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<GlutenSafetyStatus?>(
                  initialValue: _filter,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text(
                        "Filtra Stati: Tutti",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    DropdownMenuItem(
                      value: GlutenSafetyStatus.adatto,
                      child: Text(
                        "🟢 Solo Idonei",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    DropdownMenuItem(
                      value: GlutenSafetyStatus.incerto,
                      child: Text(
                        "🟡 Solo Incerti",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    DropdownMenuItem(
                      value: GlutenSafetyStatus.nonAdatto,
                      child: Text(
                        "🔴 Solo Non Idonei",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    DropdownMenuItem(
                      value: GlutenSafetyStatus.sconosciuto,
                      child: Text(
                        "⚪️ Solo Non Trovati",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _filter = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // List
          if (filteredHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Column(
                children: [
                  Icon(Icons.delete_outline, size: 40, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Nessuna scansione trovata",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredHistory.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = filteredHistory[index];
                return InkWell(
                  onTap: () => widget.onSelectItem(item.barcode),
                  onLongPress: () => _confirmDelete(item.id),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildStatusTag(item.status),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Barcode: ${item.barcode}",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                item.brand,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.green),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    String count,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTag(GlutenSafetyStatus status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case GlutenSafetyStatus.adatto:
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        label = "Idoneo";
        break;
      case GlutenSafetyStatus.nonAdatto:
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        label = "Contiene Glutine";
        break;
      case GlutenSafetyStatus.incerto:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        label = "Incerto";
        break;
      case GlutenSafetyStatus.sconosciuto:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        label = "Sconosciuto";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
