import 'package:flutter/material.dart';
import 'dart:ui';
import '../widgets/add_product_widget.dart';

class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              title: const Text(
                'Aggiungi Prodotto',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 28,
                  letterSpacing: -0.5,
                ),
              ),
              backgroundColor: colorScheme.surface.withOpacity(0.7),
              foregroundColor: colorScheme.onSurface,
              elevation: 0,
              toolbarHeight: 100,
            ),
          ),
        ),
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: AddProductWidget(),
        ),
      ),
    );
  }
}
