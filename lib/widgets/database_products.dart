import 'package:flutter/material.dart';
import '../models/types.dart';

class DatabaseProducts extends StatefulWidget {
  final List<Product> products;
  final Function(String) onSelectItem;

  const DatabaseProducts({
    super.key,
    required this.products,
    required this.onSelectItem,
  });

  @override
  State<DatabaseProducts> createState() => _DatabaseProductsState();
}

class _DatabaseProductsState extends State<DatabaseProducts> {
  String _searchTerm = "";
  GlutenSafetyStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final reportedProducts = widget.products.where((p) => (p.reportCount ?? 0) > 0).toList();

    final filtered = reportedProducts.where((p) {
      final queryMatches = p.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p.brand.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p.barcode.contains(_searchTerm);
      final filterMatches = _statusFilter == null || p.status == _statusFilter;
      return queryMatches && filterMatches;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // DB Overview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      "Segnalazioni / Conferme",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Elenco dei prodotti per cui sono state inviate segnalazioni.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sync, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Totale Prodotti: ${reportedProducts.length} salvati",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800, fontSize: 12),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: Colors.white54,
                        child: Text("REVISIONE IN CORSO", style: TextStyle(fontSize: 8, color: Colors.orange.shade900)),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                TextField(
                  onChanged: (val) => setState(() => _searchTerm = val),
                  decoration: InputDecoration(
                    hintText: "Cerca record...",
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<GlutenSafetyStatus?>(
                  initialValue: _statusFilter,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text("Tutti gli stati", style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: GlutenSafetyStatus.adatto, child: Text("🟢 Solo Idonei", style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: GlutenSafetyStatus.sconosciuto, child: Text("⚪️ Solo Sconosciuti", style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: GlutenSafetyStatus.incerto, child: Text("🟡 Solo Incerti", style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: GlutenSafetyStatus.non_adatto, child: Text("🔴 Solo Non Idonei", style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (val) => setState(() => _statusFilter = val),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Column(
                children: [
                  Text("Nessun prodotto corrisponde", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final prod = filtered[index];
                return InkWell(
                  onTap: () => widget.onSelectItem(prod.barcode),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildStatusBadge(prod.status),
                            const SizedBox(width: 8),
                            Text("Barcode: ${prod.barcode}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text("Marca: ${prod.brand}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            prod.reason.isEmpty ? "Nessun commento aggiuntivo." : prod.reason,
                            style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
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

  Widget _buildStatusBadge(GlutenSafetyStatus status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case GlutenSafetyStatus.adatto:
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        label = "🟢 IDONEO";
        break;
      case GlutenSafetyStatus.non_adatto:
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        label = "🔴 NOCIVO";
        break;
      case GlutenSafetyStatus.incerto:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        label = "🟡 INCERTO";
        break;
      case GlutenSafetyStatus.sconosciuto:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        label = "⚪ SCONOSCIUTO";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor)),
    );
  }
}
