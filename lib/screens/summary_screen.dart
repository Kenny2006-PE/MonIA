import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../database/db_helper.dart';
import 'add_transaction_modal.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await DbHelper.instance.readAllTransactions();
      if (mounted) {
        setState(() {
          _transactions = transactions;
        });
      }
    } catch (e) {
      print('Error al cargar transacciones: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAddTransactionModal() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionModal(),
    );

    if (result != null) {
      await _processTransaction(result);
      await _loadTransactions();
    }
  }

  Future<void> _processTransaction(Map<String, dynamic> tx) async {
    // 1. Guardar la transacción
    await DbHelper.instance.createTransaction(tx);

    // 2. Actualizar el saldo de la tarjeta
    final String cardIdStr = tx['cardId'];
    final cards = await DbHelper.instance.readAllCards();
    try {
      final matchingCards = cards.where((c) => c['id'].toString() == cardIdStr);
      if (matchingCards.isEmpty) return;
      final card = matchingCards.first;
      final isCredit = card['isCredit'] == 1 || card['isCredit'] == true;
      final isExpense = tx['type'] == 'Gasto';
      final double amount = tx['amount'];

      Map<String, dynamic> updatedCard = Map<String, dynamic>.from(card);

      if (isCredit) {
        double currentDebt = card['debt'] ?? 0.0;
        if (isExpense) {
          currentDebt += amount;
        } else {
          currentDebt -= amount;
        }
        updatedCard['debt'] = currentDebt;
      } else {
        double currentBalance = card['balance'] ?? 0.0;
        if (isExpense) {
          currentBalance -= amount;
        } else {
          currentBalance += amount;
        }
        updatedCard['balance'] = currentBalance;
      }

      await DbHelper.instance.updateCard(updatedCard);
    } catch (e) {
      print('Error al actualizar la tarjeta: $e');
    }
  }

  Future<void> _deleteTransaction(String id, String cardId, double amount, String type) async {
    // Revertir el impacto en la tarjeta si aún existe
    final cards = await DbHelper.instance.readAllCards();
    try {
      final matchingCards = cards.where((c) => c['id'].toString() == cardId);
      if (matchingCards.isNotEmpty) {
        final card = matchingCards.first;
        final isCredit = card['isCredit'] == 1 || card['isCredit'] == true;
        final isExpense = type == 'Gasto';

        Map<String, dynamic> updatedCard = Map<String, dynamic>.from(card);

        if (isCredit) {
          double currentDebt = card['debt'] ?? 0.0;
          if (isExpense) {
            currentDebt -= amount;
          } else {
            currentDebt += amount;
          }
          updatedCard['debt'] = currentDebt;
        } else {
          double currentBalance = card['balance'] ?? 0.0;
          if (isExpense) {
            currentBalance += amount;
          } else {
            currentBalance -= amount;
          }
          updatedCard['balance'] = currentBalance;
        }
        
        await DbHelper.instance.updateCard(updatedCard);
      }
    } catch (e) {
      print('Error al revertir saldo: $e');
    }

    await DbHelper.instance.deleteTransaction(id);
    await _loadTransactions();
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen))
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen de Movimientos',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _transactions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long, size: 80, color: Colors.white.withOpacity(0.1)),
                                  const SizedBox(height: 16),
                                  Text('Aún no tienes movimientos', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _transactions.length,
                              itemBuilder: (context, index) {
                                final tx = _transactions[index];
                                final isExpense = tx['type'] == 'Gasto';
                                final amount = tx['amount'] as double;
                                final dateStr = _formatDate(tx['date']);
                                final hasWallet = tx['walletUsed'] != 'Ninguna';

                                return Dismissible(
                                  key: Key(tx['id'].toString()),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 24),
                                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
                                  ),
                                  onDismissed: (dir) => _deleteTransaction(tx['id'], tx['cardId'], amount, tx['type']),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardDark,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: (isExpense ? Colors.redAccent : AppTheme.accentGreen).withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                                            color: isExpense ? Colors.redAccent : AppTheme.accentGreen,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tx['description'] ?? 'Sin descripción',
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Text(dateStr, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                                  if (hasWallet) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: tx['walletUsed'] == 'Yape' ? const Color(0xFF742284).withOpacity(0.3) : const Color(0xFF00E2FF).withOpacity(0.3),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        tx['walletUsed'],
                                                        style: TextStyle(
                                                          color: tx['walletUsed'] == 'Yape' ? const Color(0xFFD3A2DD) : const Color(0xFF00E2FF),
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${isExpense ? '-' : '+'}S/ ${amount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: isExpense ? Colors.redAccent : AppTheme.accentGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ).animate().fade(duration: 400.ms).slideX(begin: 0.1, delay: (index * 50).ms),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionModal,
        backgroundColor: AppTheme.accentGreen,
        child: const Icon(Icons.add, color: AppTheme.primaryDark),
      ),
    );
  }
}
