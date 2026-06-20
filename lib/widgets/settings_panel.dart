import 'package:flutter/material.dart';
import '../models/types.dart';

class SettingsPanel extends StatefulWidget {
  final UserSettings settings;
  final List<ProductReport> reports;
  final Future<void> Function(UserSettings) onSettingsChange;
  final Future<void> Function() onResetDB;
  final Future<void> Function() onClearHistory;
  final VoidCallback? onViewReports;

  const SettingsPanel({
    super.key,
    required this.settings,
    required this.reports,
    required this.onSettingsChange,
    required this.onResetDB,
    required this.onClearHistory,
    this.onViewReports,
  });

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  bool _clearing = false;

  void _triggerToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Text(msg),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
  }

  Future<void> _handleToggle(bool value, String key) async {
    final updated = UserSettings(
      userId: widget.settings.userId,
      strictMode: key == 'strictMode' ? value : widget.settings.strictMode,
      alertLactose: key == 'alertLactose' ? value : widget.settings.alertLactose,
      warnAdditives: key == 'warnAdditives' ? value : widget.settings.warnAdditives,
      autoSaveHistory: widget.settings.autoSaveHistory,
      preferredLanguage: widget.settings.preferredLanguage,
    );
    await widget.onSettingsChange(updated);
    _triggerToast("Preferenze salvate ed applicate!");
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preferences Panel
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
                    Icon(Icons.settings, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Impostazioni Allergeni & Sensibilità",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Personalizza come l'AI analizza gli ingredienti e valuta i prodotti in base alle tue sensibilità personali o allergie associate.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                
                _buildToggleItem(
                  "Filtro Rigido Contaminazioni (Tracce)",
                  "Segnala come 'Incerto' qualsiasi alimento che riporti \"può contenere tracce di frumento/glutine\".",
                  widget.settings.strictMode,
                  (val) => _handleToggle(val, 'strictMode'),
                ),
                const SizedBox(height: 8),
                _buildToggleItem(
                  "Schermata Intolleranza al Lattosio",
                  "Verifica la presenza di lattosio, burro, polvere di latte o siero.",
                  widget.settings.alertLactose,
                  (val) => _handleToggle(val, 'alertLactose'),
                ),
                const SizedBox(height: 8),
                _buildToggleItem(
                  "Avvertimento Additivi e Amidi Sospetti",
                  "Genera un warning se il prodotto contiene \"amido modificato\", aromatizzanti senza origine specificata.",
                  widget.settings.warnAdditives,
                  (val) => _handleToggle(val, 'warnAdditives'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Local Data
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
                Row(
                  children: [
                    Icon(Icons.storage, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text("GESTIONE DATI LOCALI", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                
                InkWell(
                  onTap: _clearing ? null : () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Conferma"),
                        content: const Text("Sei sicuro di voler svuotare tutta la cronologia delle tue scansioni?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annulla")),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Svuota")),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      setState(() => _clearing = true);
                      try {
                        await widget.onClearHistory();
                        _triggerToast("Cronologia svuotata!");
                      } finally {
                        setState(() => _clearing = false);
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Svuota Cronologia", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade900)),
                              const Text("Cancella la lista delle tue ultime scansioni fatte sul dispositivo.", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Icon(Icons.description, color: Colors.green.shade700, size: 16),
                    const SizedBox(width: 8),
                    const Text("SEGNALAZIONI EFFETTUATE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text("Gestisci le segnalazioni inviate su etichette e prodotti.", style: TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 12),
                
                InkWell(
                  onTap: widget.onViewReports,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.description, color: Colors.green),
                            SizedBox(width: 12),
                            Text("Le Mie Segnalazioni", style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                          child: Text("${widget.reports.length}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildToggleItem(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.green,
          )
        ],
      ),
    );
  }
}
