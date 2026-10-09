class AppConfig {
  static const productionApiBaseUrl = 'https://api.transfaintel.xyz';

  const AppConfig({required this.apiBaseUrl, required this.useMockApi});

  factory AppConfig.fromEnvironment() => const AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: productionApiBaseUrl,
    ),
    useMockApi: bool.fromEnvironment('USE_MOCK_API'),
  );

  final String apiBaseUrl;
  final bool useMockApi;

  void validate() {
    if (!useMockApi && apiBaseUrl.trim().isEmpty) {
      throw StateError('API_BASE_URL is required when USE_MOCK_API is false.');
    }

    final uri = Uri.tryParse(apiBaseUrl);
    if (!useMockApi &&
        (uri == null ||
            !uri.hasAuthority ||
            (uri.scheme != 'https' && uri.scheme != 'http'))) {
      throw StateError('API_BASE_URL must be a valid HTTP(S) URL.');
    }
  }
}
