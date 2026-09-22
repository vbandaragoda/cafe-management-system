import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/table_provider.dart';
import '../../services/api_exception.dart';
import '../../services/table_service.dart';

/// Customer-facing device camera feature, and the primary entry point
/// into dine-in ordering: scans a table's QR code
/// (`cafe://table/{tableNumber}`), looks it up against the backend,
/// stashes the result in [TableProvider], then drops the customer
/// straight into the Menu with "Ordering for Table {n}" visible.
///
/// Replaces the old admin-only order-pickup-QR scanner — the camera is
/// still a real device-sensor feature, it now runs at the *start* of
/// an order instead of at handoff, and any signed-in-or-not customer
/// can use it (the lookup endpoint is public).
class TableScanScreen extends StatefulWidget {
  const TableScanScreen({super.key});

  @override
  State<TableScanScreen> createState() => _TableScanScreenState();
}

class _TableScanScreenState extends State<TableScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final TableService _tableService = TableService();
  final TextEditingController _manualCtrl = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (raw == null || !raw.startsWith('cafe://table/')) return;
    await _lookup(raw);
  }

  Future<void> _lookupManual() async {
    final typed = _manualCtrl.text.trim();
    if (typed.isEmpty) return;
    // Same payload shape a real table QR encodes, so both paths hit
    // the exact same backend contract (`TableService.lookupByCode`).
    await _lookup('cafe://table/$typed');
  }

  Future<void> _lookup(String code) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final table = await _tableService.lookupByCode(code);
      if (!mounted) return;
      context.read<TableProvider>().setTable(table);
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.menu, (route) => false);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } on NetworkUnavailableException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not look up that table right now.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Your Table')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.78),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Point the camera at the QR code on your table',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Enter table number instead',
                            hintStyle: TextStyle(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                          ),
                          onSubmitted: (_) => _lookupManual(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : TextButton(
                              onPressed: _lookupManual,
                              child: const Text('Go', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.menu, (route) => false),
                    child: const Text('Skip — browse for pickup instead', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
