import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';

class AddCardModal extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? initialData;

  const AddCardModal({
    super.key,
    this.isEditing = false,
    this.initialData,
  });

  @override
  State<AddCardModal> createState() => _AddCardModalState();
}

class _AddCardModalState extends State<AddCardModal> {
  bool _isCredit = true;
  late TextEditingController _nameController;
  late TextEditingController _nicknameController;
  late TextEditingController _balanceOrLimitController;
  late TextEditingController _debtController;
  late TextEditingController _teaController;
  late TextEditingController _treaController;
  late TextEditingController _maintenanceController;
  late TextEditingController _billingDateController;

  bool _linkedYape = false;
  bool _linkedPlin = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nicknameController = TextEditingController();
    _balanceOrLimitController = TextEditingController();
    _debtController = TextEditingController();
    _teaController = TextEditingController();
    _treaController = TextEditingController();
    _maintenanceController = TextEditingController();
    _billingDateController = TextEditingController();

    if (widget.initialData != null) {
      _isCredit = widget.initialData!['isCredit'] == 1 || widget.initialData!['isCredit'] == true;
      _nameController.text = widget.initialData!['name'] ?? '';
      _nicknameController.text = widget.initialData!['nickname'] ?? '';
      _teaController.text = (widget.initialData!['tea'] ?? 0.0).toString();
      _treaController.text = (widget.initialData!['trea'] ?? 0.0).toString();
      _maintenanceController.text = (widget.initialData!['maintenance'] ?? 0.0).toString();
      _billingDateController.text = (widget.initialData!['billingDate'] ?? '').toString();
      _debtController.text = (widget.initialData!['debt'] ?? 0.0).toString();
      
      final linkedStr = widget.initialData!['linkedWallets'] ?? '';
      _linkedYape = linkedStr.contains('Yape');
      _linkedPlin = linkedStr.contains('Plin');
      
      if (_isCredit) {
        _balanceOrLimitController.text = (widget.initialData!['creditLimit'] ?? 0.0).toString();
      } else {
        _balanceOrLimitController.text = (widget.initialData!['balance'] ?? 0.0).toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _balanceOrLimitController.dispose();
    _debtController.dispose();
    _teaController.dispose();
    _treaController.dispose();
    _maintenanceController.dispose();
    _billingDateController.dispose();
    super.dispose();
  }

  void _saveCard() {
    final double balanceVal = double.tryParse(_balanceOrLimitController.text) ?? 0.0;
    
    List<String> wallets = [];
    if (!_isCredit) {
      if (_linkedYape) wallets.add('Yape');
      if (_linkedPlin) wallets.add('Plin');
    }
    
    final Map<String, dynamic> result = {
      'id': widget.isEditing ? widget.initialData!['id'] : DateTime.now().millisecondsSinceEpoch.toString(),
      'isCredit': _isCredit,
      'name': _nameController.text.isEmpty ? 'Nueva Tarjeta' : _nameController.text,
      'nickname': _nicknameController.text,
      'balance': _isCredit ? 0.0 : balanceVal,
      'creditLimit': _isCredit ? balanceVal : null,
      'tea': double.tryParse(_teaController.text) ?? 0.0,
      'trea': double.tryParse(_treaController.text) ?? 0.0,
      'maintenance': double.tryParse(_maintenanceController.text) ?? 0.0,
      'billingDate': int.tryParse(_billingDateController.text) ?? 1,
      'debt': double.tryParse(_debtController.text) ?? 0.0,
      'linkedWallets': wallets.join(','),
    };
    Navigator.pop(context, result);
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool flex = false}) {
    final field = Column(
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
            color: const Color(0xFF23262F), // Darker input background
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
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

    return flex ? Expanded(child: field) : field;
  }

  @override
  Widget build(BuildContext context) {
    // Para que el modal pueda desplazarse si el teclado se abre
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isEditing ? 'Editar Tarjeta' : 'Agregar Nueva Tarjeta',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Tipo de Tarjeta
              const Text(
                'Tipo de Tarjeta',
                style: TextStyle(
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
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!widget.isEditing) setState(() => _isCredit = true);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isCredit ? AppTheme.cardDark : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: _isCredit ? Border.all(color: AppTheme.borderLight) : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Crédito',
                            style: TextStyle(
                              color: _isCredit 
                                  ? AppTheme.accentGreen 
                                  : (widget.isEditing ? AppTheme.textSecondary.withOpacity(0.2) : AppTheme.textSecondary),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!widget.isEditing) setState(() => _isCredit = false);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isCredit ? AppTheme.cardDark : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: !_isCredit ? Border.all(color: AppTheme.borderLight) : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Débito',
                            style: TextStyle(
                              color: !_isCredit 
                                  ? AppTheme.accentGreen 
                                  : (widget.isEditing ? AppTheme.textSecondary.withOpacity(0.2) : AppTheme.textSecondary),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Producto Financiero
              _buildTextField('Producto Financiero (Banco y Tarjeta)', 'Ej: Interbank Amex Gold, BCP Sueldo...', _nameController),
              const SizedBox(height: 16),
              
              // Botón IA
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentGreen.withOpacity(0.5)),
                  color: AppTheme.accentGreen.withOpacity(0.05),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.auto_awesome, color: AppTheme.accentGreen, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Autocompletar con IA',
                      style: TextStyle(
                        color: AppTheme.accentGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Apodo
              _buildTextField('Apodo de la Tarjeta (Opcional)', 'Ej: Para Streaming, Gastos Diarios, Viajes...', _nicknameController),
              const SizedBox(height: 8),
              const Text(
                'Esto ayuda a la IA a entender para qué usas esta tarjeta y darte mejores consejos.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 24),

              // Dynamic Fields
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Column(
                  children: [
                    if (_isCredit) ...[
                      Row(
                        children: [
                          _buildTextField('Límite de Crédito (S/)', '0.00', _balanceOrLimitController, flex: true),
                          const SizedBox(width: 16),
                          _buildTextField('Deuda Actual (S/)', '0.00', _debtController, flex: true),
                        ],
                      ).animate().fade().slideY(begin: 0.1),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildTextField('TEA (%)', '0.00', _teaController, flex: true),
                          const SizedBox(width: 16),
                          _buildTextField('Día de Corte', 'Ej: 15', _billingDateController, flex: true),
                        ],
                      ).animate().fade().slideY(begin: 0.1, delay: 50.ms),
                    ] else ...[
                      Row(
                        children: [
                          _buildTextField('Saldo Actual (S/)', '0.00', _balanceOrLimitController, flex: true),
                          const SizedBox(width: 16),
                          _buildTextField('TREA (%)', '0.00', _treaController, flex: true),
                        ],
                      ).animate().fade().slideY(begin: 0.1),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildTextField('Comisión Mantenimiento (S/)', '0.00', _maintenanceController, flex: true),
                          const SizedBox(width: 16),
                          const Expanded(child: SizedBox()), // Empty space to match layout
                        ],
                      ).animate().fade().slideY(begin: 0.1, delay: 50.ms),
                      const SizedBox(height: 24),
                      const Text(
                        '¿Billeteras vinculadas a esta cuenta?',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fade().slideY(begin: 0.1, delay: 100.ms),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('Yape', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            selected: _linkedYape,
                            selectedColor: const Color(0xFF742284),
                            checkmarkColor: Colors.white,
                            backgroundColor: const Color(0xFF23262F),
                            onSelected: (val) => setState(() => _linkedYape = val),
                          ),
                          const SizedBox(width: 12),
                          FilterChip(
                            label: const Text('Plin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            selected: _linkedPlin,
                            selectedColor: const Color(0xFF00E2FF).withOpacity(0.5),
                            checkmarkColor: Colors.white,
                            backgroundColor: const Color(0xFF23262F),
                            onSelected: (val) => setState(() => _linkedPlin = val),
                          ),
                        ],
                      ).animate().fade().slideY(begin: 0.1, delay: 150.ms),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Divider
              Container(height: 1, color: AppTheme.borderLight),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderLight),
                          color: AppTheme.cardDark,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _saveCard,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.accentGreen,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Guardar Tarjeta',
                          style: TextStyle(
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
