/// Web build of [AudioVolumeService] — there's no system mixer to control,
/// so every call reports "unsupported" rather than touching anything.
class AudioVolumeService {
  const AudioVolumeService();

  bool get isSupported => false;

  Future<int?> readPercent() async => null;

  Future<bool> setPercent(int percent) async => false;
}
