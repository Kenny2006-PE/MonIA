import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import 'add_card_modal.dart';
import '../database/db_helper.dart';
import '../services/notification_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _monthlyIncome = 0.0;
  bool _obscureIncome = false;
  bool _isEditingIncome = false;
  final TextEditingController _incomeController = TextEditingController();

  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;

  final Set<String> _obscuredAccounts = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final income = await DbHelper.instance.getMonthlyIncome();
      final cards = await DbHelper.instance.readAllCards();
      
      if (mounted) {
        setState(() {
          _monthlyIncome = income;
          _accounts = List<Map<String, dynamic>>.from(cards);
          _incomeController.text = _monthlyIncome.toStringAsFixed(2);
        });
      }
    } catch (e) {
      print('Error al cargar datos en WalletScreen: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    try {
      await NotificationService().showPersistentNotification();
    } catch (e) {
      print('Error al mostrar notificación: $e');
    }
  }

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  Future<void> _saveIncome() async {
    final newIncome = double.tryParse(_incomeController.text) ?? _monthlyIncome;
    await DbHelper.instance.updateMonthlyIncome(newIncome);
    setState(() {
      _monthlyIncome = newIncome;
      _isEditingIncome = false;
    });
  }

  void _toggleObscureIncome() {
    setState(() {
      _obscureIncome = !_obscureIncome;
    });
  }
  
  void _toggleObscureAccount(String accountId) {
    setState(() {
      if (_obscuredAccounts.contains(accountId)) {
        _obscuredAccounts.remove(accountId);
      } else {
        _obscuredAccounts.add(accountId);
      }
    });
  }

  Future<void> _addCard(Map<String, dynamic> newCard) async {
    await DbHelper.instance.createCard({
      'isCredit': newCard['isCredit'] ? 1 : 0,
      'name': newCard['name'],
      'nickname': newCard['nickname'],
      'balance': newCard['balance'],
      'creditLimit': newCard['creditLimit'],
      'tea': newCard['tea'],
      'trea': newCard['trea'],
      'maintenance': newCard['maintenance'],
      'billingDate': newCard['billingDate'],
      'debt': newCard['debt'],
      'linkedWallets': newCard['linkedWallets'],
    });
    await _loadData();
  }

  Future<void> _editCard(Map<String, dynamic> editedCard) async {
    final dynamic rawId = editedCard['id'];
    final int? idInt = rawId is int ? rawId : int.tryParse(rawId.toString());
    
    await DbHelper.instance.updateCard({
      'id': idInt ?? rawId,
      'isCredit': editedCard['isCredit'] ? 1 : 0,
      'name': editedCard['name'],
      'nickname': editedCard['nickname'],
      'balance': editedCard['balance'],
      'creditLimit': editedCard['creditLimit'],
      'tea': editedCard['tea'],
      'trea': editedCard['trea'],
      'maintenance': editedCard['maintenance'],
      'billingDate': editedCard['billingDate'],
      'debt': editedCard['debt'],
      'linkedWallets': editedCard['linkedWallets'],
    });
    await _loadData();
  }

  Future<void> _deleteCard(String idStr) async {
    final id = int.tryParse(idStr) ?? -1;
    if (id != -1) {
      await DbHelper.instance.deleteCard(id);
      await _loadData();
    }
  }

  void _showAddCardModal([Map<String, dynamic>? initialData]) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCardModal(
        isEditing: initialData != null,
        initialData: initialData,
      ),
    );

    if (result != null) {
      if (initialData != null) {
        await _editCard(result);
      } else {
        await _addCard(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Mi Billetera',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Gestiona tus tarjetas e ingresos',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              
              // Income Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'INGRESO MENSUAL NETO',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _toggleObscureIncome,
                              child: Icon(
                                _obscureIncome ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _isEditingIncome
                              ? Row(
                                  key: const ValueKey('editing'),
                                  children: [
                                    const Text('S/ ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accentGreen)),
                                    Container(
                                      width: 120,
                                      height: 40,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryDark,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppTheme.accentGreen.withOpacity(0.5)),
                                      ),
                                      child: TextField(
                                        controller: _incomeController,
                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        ),
                                        autofocus: true,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _saveIncome,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentGreen,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text('Guardar', style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isEditingIncome = false;
                                          _incomeController.text = _monthlyIncome.toStringAsFixed(2);
                                        });
                                      },
                                      child: const Icon(Icons.close, color: Colors.white54, size: 24),
                                    ),
                                  ],
                                )
                              : Row(
                                  key: const ValueKey('display'),
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    const Text(
                                      'S/ ',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentGreen,
                                      ),
                                    ),
                                    Text(
                                      _obscureIncome ? '***.**' : _monthlyIncome.toStringAsFixed(2),
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.accentGreen,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                    if (!_isEditingIncome) Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary, size: 20),
                        onPressed: () {
                          setState(() {
                            _isEditingIncome = true;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 36),
              
              // Cards Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tus Tarjetas',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAddCardModal(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: AppTheme.accentGreen, size: 20),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Cards List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _accounts.length,
                itemBuilder: (context, index) {
                  final acc = _accounts[index];
                  final accId = acc['id'].toString();
                  final isObscured = _obscuredAccounts.contains(accId);
                  final isCredit = acc['isCredit'] == 1 || acc['isCredit'] == true;
                  
                  return Dismissible(
                    key: Key(accId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
                    ),
                    onDismissed: (direction) => _deleteCard(accId),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bank Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    acc['name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isCredit ? 'CRÉDITO' : 'DÉBITO',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white, // Web design has it brighter
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Golden Chip
                                  Container(
                                    width: 32,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4AF37).withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(top: 11, left: 0, right: 0, child: Container(height: 1, color: Colors.black26)),
                                        Positioned(left: 10, top: 0, bottom: 0, child: Container(width: 1, color: Colors.black26)),
                                        Positioned(right: 10, top: 0, bottom: 0, child: Container(width: 1, color: Colors.black26)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary, size: 20),
                                  onPressed: () => _showAddCardModal(acc),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Balance Section
                          Row(
                            children: [
                              Text(
                                isCredit ? 'LÍMITE DISPONIBLE' : 'SALDO ACTUAL',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _toggleObscureAccount(accId),
                                child: Icon(
                                  isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Text(
                                'S/ ',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                isObscured 
                                  ? '***.**' 
                                  : (isCredit ? acc['creditLimit']?.toStringAsFixed(2) : acc['balance']?.toStringAsFixed(2)),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            (acc['nickname'] != null && acc['nickname'].toString().isNotEmpty)
                                ? acc['nickname'].toString().toUpperCase()
                                : (acc['name']).toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Web design makes subtitle stand out a bit more
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(duration: 500.ms).slideY(begin: 0.2, delay: (index * 100).ms);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
