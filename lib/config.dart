
// https://admin.dotgaming.pt/
const String apiBaseUrl = 'https://admin.dotgaming.pt';

/// Resolves a media URL returned by Strapi.
/// If [url] is already absolute (e.g. served by S3), returns it unchanged.
/// Otherwise prepends [apiBaseUrl] (for local Strapi uploads served as `/uploads/...`).
String resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  return '$apiBaseUrl$url';
}
