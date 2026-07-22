import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../database/db_helper.dart';

class AddTransactionModal extends StatefulWidget {
  @override
  _AddTransactionModalState createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  bool _isExpense = true;
  List<Map<String, dynamic>> _cards = [];
  String? _selectedCardId;
  String _selectedWallet = 'Ninguna';
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await DbHelper.instance.readAllCards();
    setState(() {
      _cards = cards;
      if (cards.isNotEmpty) {
        _selectedCardId = cards.first['id'].toString();
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    if (_amountController.text.isEmpty || _selectedCardId == null) return;
    
    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    final result = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
      'type': _isExpense ? 'Gasto' : 'Ingreso',
      'cardId': _selectedCardId,
      'walletUsed': _selectedWallet,
      'description': _descController.text.isEmpty ? 'Sin descripción' : _descController.text,
    };
    
    Navigator.pop(context, result);
  }

  List<String> _getAvailableWallets() {
    if (_selectedCardId == null || _cards.isEmpty) return ['Ninguna'];
    
    final matchingCards = _cards.where((c) => c['id'].toString() == _selectedCardId);
    if (matchingCards.isEmpty) return ['Ninguna'];
    final card = matchingCards.first;
    
    List<String> wallets = ['Ninguna'];
    
    final linkedStr = card['linkedWallets'] ?? '';
    if (linkedStr.toString().isNotEmpty) {
      wallets.addAll(linkedStr.toString().split(','));
    }
    
    if (!wallets.contains(_selectedWallet)) {
      _selectedWallet = 'Ninguna';
    }
    
    return wallets;
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF23262F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            keyboardType: label.contains('S/') ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 300,
        decoration: const BoxDecoration(
          color: AppTheme.primaryDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen)),
      );
    }

    final wallets = _getAvailableWallets();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.primaryDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nueva Transacción',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white54, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isExpense = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isExpense ? Colors.redAccent.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _isExpense ? Colors.redAccent : AppTheme.borderLight),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Gasto',
                          style: TextStyle(
                            color: _isExpense ? Colors.redAccent : AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isExpense = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isExpense ? AppTheme.accentGreen.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: !_isExpense ? AppTheme.accentGreen : AppTheme.borderLight),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Ingreso',
                          style: TextStyle(
                            color: !_isExpense ? AppTheme.accentGreen : AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fade().slideY(begin: 0.1),
              const SizedBox(height: 24),
              
              _buildTextField('Monto (S/)', '0.00', _amountController).animate().fade().slideY(begin: 0.1, delay: 50.ms),
              const SizedBox(height: 16),
              _buildTextField('Descripción', 'Ej: Almuerzo', _descController).animate().fade().slideY(begin: 0.1, delay: 100.ms),
              const SizedBox(height: 16),
              
              const Text(
                'Cuenta Origen/Destino',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
              ).animate().fade().slideY(begin: 0.1, delay: 150.ms),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF23262F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCardId,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF23262F),
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCardId = newValue;
                      });
                    },
                    items: _cards.map<DropdownMenuItem<String>>((Map<String, dynamic> card) {
                      return DropdownMenuItem<String>(
                        value: card['id'].toString(),
                        child: Text(card['name'] + (card['nickname'] != null && card['nickname'].toString().isNotEmpty ? ' (${card['nickname']})' : '')),
                      );
                    }).toList(),
                  ),
                ),
              ).animate().fade().slideY(begin: 0.1, delay: 150.ms),
              const SizedBox(height: 16),
              
              const Text(
                '¿Usaste alguna Billetera Virtual?',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
              ).animate().fade().slideY(begin: 0.1, delay: 200.ms),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF23262F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedWallet,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF23262F),
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedWallet = newValue!;
                      });
                    },
                    items: wallets.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ).animate().fade().slideY(begin: 0.1, delay: 200.ms),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: AppTheme.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Registrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ).animate().fade().slideY(begin: 0.1, delay: 250.ms),
            ],
          ),
        ),
      ),
    );
  }
}
