#pragma once

#include <algorithm>
#include <cctype>
#include <string>

// Encodes literal space characters in a URI string as "%20" so that
// Windows::Foundation::Uri accepts URIs that contain unencoded spaces
// (e.g. local file paths like "file:///C:/My Files/song.mp3").
//
// Already percent-encoded sequences such as "%20" or "%E2%80%99" are never
// modified, because they contain no literal space character.
inline std::string EncodeSpacesInUri(const std::string& uri) {
  std::string encoded;
  // Reserve worst-case capacity (every char is a space → 3 chars each).
  encoded.reserve(uri.length() * 3);
  for (char c : uri) {
    if (c == ' ') {
      encoded += "%20";
    } else {
      encoded += c;
    }
  }
  return encoded;
}

// Percent-decodes URI octets while preserving their raw UTF-8 representation.
inline std::string UrlDecodeUtf8(const std::string& uri) {
  std::string out;
  out.reserve(uri.length());
  const size_t n = uri.length();
  for (size_t i = 0; i < n; ++i) {
    if (uri[i] == '%' && i + 2 < n) {
      auto hex = [](char c) -> int {
        if (c >= '0' && c <= '9') return c - '0';
        if (c >= 'A' && c <= 'F') return c - 'A' + 10;
        if (c >= 'a' && c <= 'f') return c - 'a' + 10;
        return -1;
      };
      int hi = hex(uri[i + 1]);
      int lo = hex(uri[i + 2]);
      if (hi >= 0 && lo >= 0) {
        out += static_cast<char>((hi << 4) | lo);
        i += 2;
        continue;
      }
    }
    out += uri[i];
  }
  return out;
}

// Converts a file:// URI into a UTF-8 Windows path without asking WinRT's
// Uri parser to interpret percent-encoded non-ASCII bytes.
inline std::string FileUriToUtf8WindowsPath(const std::string& uri) {
  std::string path;
  if (uri.rfind("file:///", 0) == 0) {
    path = uri.substr(8);
  } else if (uri.rfind("file://", 0) == 0) {
    path = "//" + uri.substr(7);
  } else {
    return std::string();
  }
  path = UrlDecodeUtf8(path);
  for (char& c : path) {
    if (c == '/') c = '\\';
  }
  return path;
}

inline std::string AudioMimeTypeForPath(const std::string& path) {
  auto dot = path.find_last_of('.');
  if (dot == std::string::npos) return "application/octet-stream";
  auto extension = path.substr(dot);
  std::transform(extension.begin(), extension.end(), extension.begin(),
                 [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
  if (extension == ".mp3") return "audio/mpeg";
  if (extension == ".flac") return "audio/flac";
  if (extension == ".m4a") return "audio/mp4";
  if (extension == ".aac") return "audio/aac";
  if (extension == ".wav") return "audio/wav";
  if (extension == ".ogg" || extension == ".opus") return "audio/ogg";
  if (extension == ".ape") return "audio/ape";
  return "application/octet-stream";
}
