#pragma once

#include <algorithm>
#include <cwctype>
#include <string>
#include <shcore.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Media.Core.h>
#include <winrt/Windows.Storage.h>
#include <winrt/Windows.Storage.Streams.h>

namespace see2sound {

inline int HexDigit(char c) {
  if (c >= '0' && c <= '9') return c - '0';
  if (c >= 'A' && c <= 'F') return c - 'A' + 10;
  if (c >= 'a' && c <= 'f') return c - 'a' + 10;
  return -1;
}

// Decode percent-escaped UTF-8 as bytes before WinRT URI parsing can widen
// encoded bytes separately (C3 A7 must become U+00E7, not U+00C3 U+00A7).
inline std::wstring DecodeFilePath(const std::string& encoded) {
  std::string bytes;
  bytes.reserve(encoded.size());
  for (size_t i = 0; i < encoded.size(); ++i) {
    if (encoded[i] == '%') {
      if (i + 2 >= encoded.size()) throw winrt::hresult_invalid_argument();
      const int high = HexDigit(encoded[i + 1]);
      const int low = HexDigit(encoded[i + 2]);
      if (high < 0 || low < 0 || (high == 0 && low == 0)) {
        throw winrt::hresult_invalid_argument();
      }
      bytes.push_back(static_cast<char>((high << 4) | low));
      i += 2;
    } else {
      bytes.push_back(encoded[i]);
    }
  }
  return std::wstring(winrt::to_hstring(bytes));
}

// Media Foundation's file-URI resolver fails for some percent-encoded Unicode
// paths even when the file exists. Open the original file as a native stream;
// preserve URI escaping until the filesystem path is decoded exactly once.
inline winrt::Windows::Media::Core::MediaSource OpenSource(
    const std::string& encoded_uri) {
  using winrt::Windows::Foundation::Uri;
  using winrt::Windows::Media::Core::MediaSource;
  using winrt::Windows::Storage::Streams::IRandomAccessStream;
  const auto remote = [&]() {
    return MediaSource::CreateFromUri(Uri(winrt::to_hstring(encoded_uri)));
  };
  if (encoded_uri.rfind("file://", 0) != 0) return remote();

  // Decode the original Dart URI BEFORE constructing Windows.Foundation.Uri:
  // that constructor already corrupts escaped UTF-8 in its Path property.
  std::string file_part = encoded_uri.substr(7);
  const auto suffix = file_part.find_first_of("?#");
  if (suffix != std::string::npos) file_part.erase(suffix);
  std::wstring path = DecodeFilePath(file_part);
  std::wstring extension = path.size() >= 4 ? path.substr(path.size() - 4) : L"";
  std::transform(extension.begin(), extension.end(), extension.begin(),
                 [](wchar_t c) { return static_cast<wchar_t>(std::towlower(c)); });
  if (extension != L".wav") return remote();

  if (path.rfind(L"localhost/", 0) == 0) path.erase(0, 9);
  if (!path.empty() && path[0] != L'/') {
    path = L"\\\\" + path;
  } else if (path.size() >= 3 && path[0] == L'/' && path[2] == L':') {
    path.erase(0, 1);
  }
  std::replace(path.begin(), path.end(), L'/', L'\\');
  IRandomAccessStream stream{nullptr};
  const HRESULT opened = CreateRandomAccessStreamOnFile(
      path.c_str(),
      static_cast<DWORD>(winrt::Windows::Storage::FileAccessMode::Read),
      winrt::guid_of<IRandomAccessStream>(), winrt::put_abi(stream));
  if (FAILED(opened)) {
    throw winrt::hresult_error(opened, L"See2Sound: WAV path could not be opened: " + path);
  }
  return MediaSource::CreateFromStream(stream, L"audio/wav");
}
}  // namespace see2sound
