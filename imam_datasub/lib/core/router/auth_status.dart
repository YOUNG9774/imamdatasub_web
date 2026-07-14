/// Auth status enum — kept in a separate file to avoid circular imports
/// between injection.dart and app_router.dart.
enum AuthStatus { authenticated, unauthenticated, loading }
