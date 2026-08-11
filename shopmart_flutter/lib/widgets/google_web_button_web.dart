import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi_web;

// Pulsante ufficiale Google Identity Services. Al click, l'account (con idToken)
// arriva tramite GoogleSignIn.onCurrentUserChanged, gestito in AuthService.
Widget buildGoogleWebButton() => gsi_web.renderButton();
