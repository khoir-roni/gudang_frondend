class ApiConfig {
  // Ubah ke true untuk menggunakan Ngrok (Device Fisik / Internet)
  // Ubah ke false untuk menggunakan Emulator Android (Localhost)
  static bool useNgrok = true;

  static const String _localUrl = 'http://10.0.2.2:5000';
  static const String _ngrokUrl = 'https://more-golden-teal.ngrok-free.app';

  static String get baseUrl => useNgrok ? _ngrokUrl : _localUrl;
}
