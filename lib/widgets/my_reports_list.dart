import 'package:flutter/material.dart';
import '../models/types.dart';
import '../services/db_service.dart';

class MyReportsList extends StatefulWidget {
  final List<ProductReport> reports;
  final VoidCallback onBack;
  final Function(String)? onSelectReport;
  final Future<void> Function(String) onDeleteReport;

  const MyReportsList({
    super.key,
    required this.reports,
    required this.onBack,
    this.onSelectReport,
    required this.onDeleteReport,
  });

  @override
  State<MyReportsList> createState() => _MyReportsListState();
}

class _MyReportsListState extends State<MyReportsList> {
  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminare segnalazione?"),
        content: const Text("Sei sicuro di voler rimuovere la tua segnalazione?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Annulla")),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onDeleteReport(id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Elimina"),
          ),
        ],
      ),
    );
  }

  void _showSettings(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Impostazioni segnalazione"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Elimina segnalazione", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(id);
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Icon(Icons.description, size: 14, color: Colors.red.shade800),
                    const SizedBox(width: 4),
                    Text("Le mie Segnalazioni", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.reports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text("Nessuna segnalazione", style: TextStyle(fontWeight: FontWeight.bold)),
                      const Text("Non hai ancora inviato alcuna segnalazione.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.reports.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final rep = widget.reports[index];
                    return InkWell(
                      onTap: () {
                        if (widget.onSelectReport != null) {
                          widget.onSelectReport!(rep.barcode);
                        }
                      },
                      onLongPress: () => _showSettings(rep.id),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(rep.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      Row(
                                        children: [
                                          const Icon(Icons.tag, size: 12, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(rep.brand, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                if (DbService.auth.currentUser?.uid == rep.userId)
                                  IconButton(
                                    icon: const Icon(Icons.settings, size: 18),
                                    onPressed: () => _showSettings(rep.id),
                                  )
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade100),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("MOTIVAZIONE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade600)),
                                  const SizedBox(height: 4),
                                  Text(rep.comments, style: TextStyle(fontSize: 12, color: Colors.red.shade900)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(rep.barcode, style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace')),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateTime.parse(rep.submittedAt).toLocal().toString().split(' ')[0], 
                                      style: const TextStyle(fontSize: 10, color: Colors.grey)
                                    ),
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
