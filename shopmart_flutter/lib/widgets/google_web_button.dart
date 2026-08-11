// Facade con conditional import: su web usa il pulsante Google Identity
// Services (che restituisce un idToken), su mobile/desktop usa lo stub vuoto.
// Il pulsante GIS è l'unico modo affidabile per ottenere un idToken sul web
// con google_sign_in_web (signIn() sul web non lo fornisce).
export 'google_web_button_stub.dart'
    if (dart.library.html) 'google_web_button_web.dart';
