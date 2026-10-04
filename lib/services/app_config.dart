/// Global app flags set at bootstrap.
///
/// When Firebase cannot be initialized (e.g. the developer hasn't run
/// `flutterfire configure` yet), `useMockData` flips to `true` and the
/// service layer serves data from an in-memory [MockBackend] so the app
/// is fully explorable without any backend.
class AppConfig {
  static bool useMockData = true;
}
