import 'package:flutter/widgets.dart';

// Stub per piattaforme non-web: il pulsante GIS esiste solo sul web.
// Su mobile/desktop si continua a usare il pulsante custom + signInWithGoogle().
Widget buildGoogleWebButton() => const SizedBox.shrink();
