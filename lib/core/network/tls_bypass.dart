/// Conditional export of TLS bypass implementation.
///
/// On mobile/desktop platforms (dart:io), configuring TLS bypass disables
/// certificate verification so that servers with self-signed or invalid
/// certificates can be reached. On web, the function is a no-op.
export 'tls_bypass_stub.dart'
    if (dart.library.io) 'tls_bypass_io.dart';
