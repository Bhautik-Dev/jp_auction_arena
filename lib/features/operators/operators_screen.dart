import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/supabase/supabase_auth_service.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';

class OperatorsScreen extends ConsumerStatefulWidget {
  const OperatorsScreen({super.key});

  @override
  ConsumerState<OperatorsScreen> createState() => _OperatorsScreenState();
}

class _OperatorsScreenState extends ConsumerState<OperatorsScreen> {
  final _emailController = TextEditingController();
  final _roleController = TextEditingController(text: 'operator');
  String _selectedAuctionId = '';
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  List<Map<String, dynamic>> _operators = [];

  @override
  void dispose() {
    _emailController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _clearMessages() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
  }

  Future<void> _loadOperators() async {
    if (_selectedAuctionId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final members = await SupabaseAuthService.instance.getAuctionMembers(
        _selectedAuctionId,
      );
      if (mounted) {
        setState(() {
          _operators = members
              .map((p) => {
                'id': p.id,
                'email': p.email ?? '',
                'fullName': p.fullName ?? '',
                'role': p.role ?? 'operator',
              })
              .toList();
          });
        _clearMessages();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load operators: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addOperator() async {
    final email = _emailController.text.trim();
    final role = _roleController.text.trim().isEmpty
        ? 'operator'
        : _roleController.text.trim();
    if (email.isEmpty || _selectedAuctionId.isEmpty) {
      setState(() => _errorMessage = 'Please select an auction and enter an email');
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await SupabaseAuthService.instance.addAuctionMember(
        auctionId: _selectedAuctionId,
        email: email,
        role: role,
      );
      if (mounted) {
        setState(() {
          _successMessage = 'Operator $email added successfully';
          _emailController.clear();
          _roleController.text = 'operator';
        });
        await _loadOperators();
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _mapAuthError(e.message);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to add operator: $e';
          _isLoading = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeOperator(String email) async {
    if (_selectedAuctionId.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseAuthService.instance.removeAuctionMember(
        auctionId: _selectedAuctionId,
        email: email,
      );
      if (mounted) {
        setState(() {
          _successMessage = 'Operator $email removed';
        });
        await _loadOperators();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to remove operator: $e';
          _isLoading = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(String? message) {
    final msg = (message ?? '').toLowerCase();
    if (msg.contains('network') || msg.contains('failed to fetch')) {
      return 'Network error. Please check your connection.';
    }
    if (msg.contains('only the auction owner')) {
      return 'Only the auction owner can add members.';
    }
    if (msg.contains('no user found')) {
      return 'No user found with that email.';
    }
    return message ?? 'Operation failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Operators'),
        backgroundColor: AppColors.card,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Auction Operators',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add operators who can run live auctions for this auction.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),

            // Auction selector
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Auction',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                    initialValue: _selectedAuctionId.isEmpty ? null : _selectedAuctionId,
                    hint: const Text('Select an auction'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                    ),
                    items: const [],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedAuctionId = val);
                        _loadOperators();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Auction list will appear once auctions are created.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Add operator form
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Operator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _emailController,
                          onChanged: (_) => _clearMessages(),
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'operator@club.com',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _roleController,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            hintText: 'operator',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GradientButton(
                        onPressed: _isLoading ? null : _addOperator,
                        isLoading: _isLoading,
                        icon: Icons.person_add_rounded,
                        label: 'Add',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Active operators list
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Active Operators',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_operators.length} operator${_operators.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_operators.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_off_outlined,
                                size: 48,
                                color: AppColors.textMuted,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No operators yet',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: _operators.length,
                          itemBuilder: (context, index) {
                            final op = _operators[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.cardBorder.withValues(alpha: 0.5),
                                ),
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppColors.accentPink.withValues(alpha: 0.2),
                                  child: Text(
                                    (op['fullName'] as String? ?? op['email'] as String).isNotEmpty
                                        ? (op['fullName'] as String? ??
                                            op['email'] as String)[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: AppColors.accentPink,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  op['email'] as String? ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${op['role'] as String? ?? 'operator'} • ${op['fullName'] as String? ?? ''}',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () => _removeOperator(op['email'] as String? ?? ''),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
