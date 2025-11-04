// baseURL
const String _defaultBaseUrl = 'https://cjdwjdwleo.duckdns.org';

const String baseUrl = String.fromEnvironment('API_BASE', defaultValue: _defaultBaseUrl);