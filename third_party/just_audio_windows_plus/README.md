# See2Sound Windows audio implementation

Vendored from just_audio_windows_plus 0.5.5 (MIT):
https://github.com/OmarAfifi-CSE/just_audio_windows_plus
https://pub.dev/packages/just_audio_windows_plus/versions/0.5.5

The upstream Win32 platform-thread dispatcher and just_audio protocol are preserved.
See2Sound patch: local WAV sources are opened read-only by their decoded UTF-16
Windows path and passed to MediaSource as a native random-access stream. Escaped
UTF-8 is decoded before constructing a WinRT Uri, whose file-path handling was
reproduced corrupting accented characters. Literal #, % and spaces are preserved.
No HTTP proxy, renamed playback file, temporary copy or simulated player is used.
Remote URLs and other media types retain the upstream source path.

Modified upstream files: windows/player.hpp, windows/CMakeLists.txt.
Added: windows/local_wav_source.hpp.
The MIT license and upstream attribution are included. The package stays the only
Windows implementation registered for just_audio. Recheck this patch against
upstream when upgrading; do not restore just_audio_windows alongside it.

Validation: integration_test/windows_player_test.dart in the application.
