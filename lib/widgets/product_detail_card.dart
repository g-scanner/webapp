import 'package:flutter/material.dart';
import '../models/types.dart';

class ProductDetailCard extends StatefulWidget {
  final Product product;
  final VoidCallback onBack;
  final Future<void> Function(String barcode, Map<String, dynamic> reportData) onReportSubmit;
  final Future<void> Function(Product updatedProduct) onProductUpdate;
  final UserSettings userSettings;
  final Future<void> Function(String barcode)? onDeleteHistoryByBarcode;
  final bool hasReportedThisSession;
  final String? userReportId;
  final Future<void> Function(String reportId)? onDeleteReport;

  const ProductDetailCard({
    super.key,
    required this.product,
    required this.onBack,
    required this.onReportSubmit,
    required this.onProductUpdate,
    required this.userSettings,
    this.onDeleteHistoryByBarcode,
    this.hasReportedThisSession = false,
    this.userReportId,
    this.onDeleteReport,
  });

  @override
  State<ProductDetailCard> createState() => _ProductDetailCardState();
}

class _ProductDetailCardState extends State<ProductDetailCard> {
  bool _isReporting = false;
  String _reportType = "label_unclear";
  final TextEditingController _reportCommentsController = TextEditingController();
  bool _reportSubmitted = false;
  bool _submittingReport = false;

  @override
  void dispose() {
    _reportCommentsController.dispose();
    super.dispose();
  }

  Future<void> _handleReport() async {
    setState(() => _submittingReport = true);
    try {
      await widget.onReportSubmit(widget.product.barcode, {
        "type": _reportType,
        "comments": _reportCommentsController.text,
      });
      setState(() {
        _reportSubmitted = true;
      });
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          setState(() {
            _isReporting = false;
            _reportSubmitted = false;
            _reportCommentsController.clear();
          });
        }
      });
    } catch (err) {
      print(err);
    } finally {
      if (mounted) setState(() => _submittingReport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool containsLactose = widget.product.ingredients.toLowerCase().contains("latte") ||
        widget.product.ingredients.toLowerCase().contains("lattosio") ||
        widget.product.ingredients.toLowerCase().contains("burro") ||
        widget.product.ingredients.toLowerCase().contains("panna");

    final bool showLactoseWarning = widget.userSettings.alertLactose && containsLactose;

    Color bg;
    Color iconColor;
    Color pillBg;
    Color pillText;
    String badgeText;
    IconData icon;

    switch (widget.product.status) {
      case GlutenSafetyStatus.adatto:
        bg = Colors.green.shade50;
        iconColor = Colors.green.shade600;
        pillBg = Colors.green.shade100;
        pillText = Colors.green.shade800;
        badgeText = "SENZA GLUTINE - IDONEO";
        icon = Icons.verified_user;
        break;
      case GlutenSafetyStatus.non_adatto:
        bg = Colors.red.shade50;
        iconColor = Colors.red.shade600;
        pillBg = Colors.red.shade100;
        pillText = Colors.red.shade800;
        badgeText = "CONTIENE GLUTINE - VIETATO";
        icon = Icons.warning;
        break;
      case GlutenSafetyStatus.incerto:
        bg = Colors.orange.shade50;
        iconColor = Colors.orange.shade600;
        pillBg = Colors.orange.shade100;
        pillText = Colors.orange.shade800;
        badgeText = "STATO INCERTO / DA VERIFICARE";
        icon = Icons.help_outline;
        break;
      case GlutenSafetyStatus.sconosciuto:
        bg = Colors.grey.shade50;
        iconColor = Colors.grey.shade600;
        pillBg = Colors.grey.shade100;
        pillText = Colors.grey.shade800;
        badgeText = "SCONOSCIUTO / DATI ASSENTI";
        icon = Icons.error_outline;
        break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, color: Colors.grey),
                label: const Text("Torna alla scansione", style: TextStyle(color: Colors.grey)),
              ),
              const Spacer(),
              if (widget.onDeleteHistoryByBarcode != null || widget.userReportId != null)
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Impostazioni"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.onDeleteHistoryByBarcode != null)
                              ListTile(
                                leading: const Icon(Icons.delete, color: Colors.red),
                                title: const Text("Elimina dalla cronologia", style: TextStyle(color: Colors.red)),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  widget.onDeleteHistoryByBarcode!(widget.product.barcode);
                                  widget.onBack();
                                },
                              ),
                            if (widget.userReportId != null && widget.onDeleteReport != null)
                              ListTile(
                                leading: const Icon(Icons.warning, color: Colors.red),
                                title: const Text("Elimina segnalazione", style: TextStyle(color: Colors.red)),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  widget.onDeleteReport!(widget.userReportId!);
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                )
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Icon(icon, color: iconColor, size: 48),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(16)),
                              child: Text(badgeText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: pillText)),
                            ),
                            const SizedBox(height: 8),
                            Text(widget.product.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("${widget.product.brand} • Codice: ${widget.product.barcode}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showLactoseWarning)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.warning, color: Colors.orange.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Avviso Lattosio", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                                    const SizedBox(height: 4),
                                    Text("Questo prodotto contiene ingredienti derivati dal latte.", style: TextStyle(fontSize: 12, color: Colors.orange.shade900)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        
                      const Text("VALUTAZIONE GLUTINE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                        child: Text(widget.product.reason, style: const TextStyle(fontSize: 14)),
                      ),
                      
                      const SizedBox(height: 24),
                      const Text("ALLERGENI DICHIARATI", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.product.allergens.isNotEmpty
                            ? widget.product.allergens.map((alg) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                                child: Text(alg, style: TextStyle(color: Colors.red.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                              )).toList()
                            : [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
                                  child: Text("Nessun allergene critico rilevato", style: TextStyle(color: Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                                )
                              ],
                      ),
                      
                      const SizedBox(height: 24),
                      const Text("INGREDIENTI ANALIZZATI", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Ingredienti completi: ${widget.product.ingredients}", style: const TextStyle(fontSize: 12)),
                            if (widget.product.ingredientsAnalyzed != null && widget.product.ingredientsAnalyzed!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 12),
                              const Text("Analisi componenti sensibili:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 8),
                              ...widget.product.ingredientsAnalyzed!.map((item) {
                                Color itemColor = item.dangerLevel == "danger" ? Colors.red : item.dangerLevel == "warning" ? Colors.orange : Colors.green;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(color: itemColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                        child: Text(item.dangerLevel.toUpperCase(), style: TextStyle(fontSize: 10, color: itemColor, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(item.ingredient, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                      Expanded(child: Text(item.reason, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.right)),
                                    ],
                                  ),
                                );
                              })
                            ]
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                
                // Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: widget.hasReportedThisSession || (widget.product.reportCount ?? 0) > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.red.shade600, size: 20),
                              const SizedBox(width: 8),
                              Text("Prodotto già segnalato", style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => setState(() => _isReporting = !_isReporting),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.grey.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          icon: const Icon(Icons.report_problem, color: Colors.red),
                          label: const Text("Segnala Etichetta Poco Chiara o Sbagliata"),
                        ),
                )
              ],
            ),
          ),
          
          if (_isReporting) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.red.shade100),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: _reportSubmitted
                  ? Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600, size: 48),
                        const SizedBox(height: 16),
                        Text("Segnalazione Registrata!", style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text("Grazie per aver reso sicuro il database per tutti.", style: TextStyle(fontSize: 12)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red.shade600),
                            const SizedBox(width: 8),
                            const Text("Segnalazione Rapida Etichetta", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text("La tua segnalazione avviserà gli altri utenti in tempo reale.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 16),
                        
                        const Text("Tipo di segnalazione", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          initialValue: _reportType,
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          ),
                          items: const [
                            DropdownMenuItem(value: "label_unclear", child: Text("Etichetta poco chiara o ambigua", style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: "outdated", child: Text("Informazione obsoleta", style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: "incorrect_status", child: Text("Stato glutine errato", style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: "other", child: Text("Altro", style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (val) => setState(() => _reportType = val!),
                        ),
                        
                        const SizedBox(height: 16),
                        const Text("Commenti o modifiche rilevate", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _reportCommentsController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "Es: 'Sulla confezione dice può contenere tracce...'",
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => setState(() => _isReporting = false),
                              child: const Text("Annulla"),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _submittingReport ? null : _handleReport,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _submittingReport ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Invia Segnalazione"),
                            )
                          ],
                        )
                      ],
                    ),
            )
          ]
        ],
      ),
    );
  }
}
