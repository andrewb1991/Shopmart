import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _notificationsEnabled = true;
  int _urgentDays = 3;
  int _warningDays = 7;

  String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:5001';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  Future<void> _loadSettings() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final settings = data['notificationSettings'];

        setState(() {
          _notificationsEnabled = settings['enabled'] ?? true;
          _urgentDays = settings['urgentDays'] ?? 3;
          _warningDays = settings['warningDays'] ?? 7;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Errore caricamento impostazioni: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'enabled': _notificationsEnabled,
          'urgentDays': _urgentDays,
          'warningDays': _warningDays,
        }),
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impostazioni salvate con successo'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _requestPermissions() async {
    final granted = await _notificationService.requestPermissions();

    if (!mounted) return;

    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permessi notifiche concessi'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permessi notifiche negati'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testNotification() async {
    await _notificationService.showNotification(
      id: 0,
      title: 'Test Notifica',
      body: 'Questa è una notifica di prova da Shopmart!',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifica di test inviata'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.8),
                Colors.white.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[600]!, Colors.blue[800]!],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F7),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Impostazioni Notifiche',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.black87),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Abilita notifiche
              _buildSettingCard(
                icon: Icons.notifications_active,
                title: 'Notifiche Abilitate',
                subtitle: 'Ricevi avvisi per prodotti in scadenza',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                  activeColor: Colors.blue[700],
                ),
              ),

              const SizedBox(height: 16),

              // Giorni urgente
              _buildSettingCard(
                icon: Icons.warning_amber_rounded,
                title: 'Avviso Urgente',
                subtitle: 'Notifica quando mancano $_urgentDays giorni alla scadenza',
                trailing: SizedBox(
                  width: 80,
                  child: DropdownButton<int>(
                    value: _urgentDays,
                    isExpanded: true,
                    underline: Container(),
                    items: [1, 2, 3, 4, 5].map((days) {
                      return DropdownMenuItem(
                        value: days,
                        child: Text('$days giorni'),
                      );
                    }).toList(),
                    onChanged: _notificationsEnabled
                        ? (value) {
                            if (value != null) {
                              setState(() {
                                _urgentDays = value;
                              });
                            }
                          }
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Giorni avviso
              _buildSettingCard(
                icon: Icons.info_outline,
                title: 'Avviso Preventivo',
                subtitle: 'Notifica quando mancano $_warningDays giorni alla scadenza',
                trailing: SizedBox(
                  width: 80,
                  child: DropdownButton<int>(
                    value: _warningDays,
                    isExpanded: true,
                    underline: Container(),
                    items: [5, 7, 10, 14].map((days) {
                      return DropdownMenuItem(
                        value: days,
                        child: Text('$days giorni'),
                      );
                    }).toList(),
                    onChanged: _notificationsEnabled
                        ? (value) {
                            if (value != null) {
                              setState(() {
                                _warningDays = value;
                              });
                            }
                          }
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Sezione Test e Permessi
              Text(
                'Gestione',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),

              const SizedBox(height: 16),

              // Pulsante Richiedi Permessi
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange[600]!,
                      Colors.orange[700]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: -5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _requestPermissions,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Richiedi Permessi Notifiche',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Pulsante Test Notifica
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[600]!,
                      Colors.blue[700]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: -5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _testNotification,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_active, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Invia Notifica di Test',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blue[200]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Le notifiche ti avviseranno quando i tuoi prodotti stanno per scadere e ti suggeriranno ricette per utilizzarli.',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
