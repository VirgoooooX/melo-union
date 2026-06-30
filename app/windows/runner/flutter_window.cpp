#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include <flutter/standard_method_codec.h>
#include <wincred.h>
#include <string>

#pragma comment(lib, "Advapi32.lib")

namespace {

std::wstring Utf8ToUtf16(const std::string& utf8) {
  if (utf8.empty()) return L"";
  int size_needed = ::MultiByteToWideChar(CP_UTF8, 0, &utf8[0], static_cast<int>(utf8.size()), NULL, 0);
  std::wstring utf16(size_needed, 0);
  ::MultiByteToWideChar(CP_UTF8, 0, &utf8[0], static_cast<int>(utf8.size()), &utf16[0], size_needed);
  return utf16;
}

std::string Utf16ToUtf8(const std::wstring& utf16) {
  if (utf16.empty()) return "";
  int size_needed = ::WideCharToMultiByte(CP_UTF8, 0, &utf16[0], static_cast<int>(utf16.size()), NULL, 0, NULL, NULL);
  std::string utf8(size_needed, 0);
  ::WideCharToMultiByte(CP_UTF8, 0, &utf16[0], static_cast<int>(utf16.size()), &utf8[0], size_needed, NULL, NULL);
  return utf8;
}

bool WriteCredentials(const std::wstring& target_name, const std::wstring& serialized_data) {
  CREDENTIALW credential = {};
  credential.Type = CRED_TYPE_GENERIC;
  credential.TargetName = const_cast<LPWSTR>(target_name.c_str());
  credential.CredentialBlobSize = static_cast<DWORD>(serialized_data.size() * sizeof(wchar_t));
  credential.CredentialBlob = reinterpret_cast<LPBYTE>(const_cast<wchar_t*>(serialized_data.data()));
  credential.Persist = CRED_PERSIST_ENTERPRISE;
  
  return ::CredWriteW(&credential, 0) == TRUE;
}

std::wstring ReadCredentials(const std::wstring& target_name) {
  PCREDENTIALW credential = nullptr;
  if (::CredReadW(target_name.c_str(), CRED_TYPE_GENERIC, 0, &credential) == TRUE) {
    std::wstring result(reinterpret_cast<wchar_t*>(credential->CredentialBlob),
                         credential->CredentialBlobSize / sizeof(wchar_t));
    ::CredFree(credential);
    return result;
  }
  return L"";
}

bool DeleteCredentials(const std::wstring& target_name) {
  return ::CredDeleteW(target_name.c_str(), CRED_TYPE_GENERIC, 0) == TRUE;
}

} // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Initialize and register method channel for credentials
  flutter::BinaryMessenger* messenger = flutter_controller_->engine()->messenger();
  credentials_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "melo_union/provider_credentials",
      &flutter::StandardMethodCodec::GetInstance());

  credentials_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "readNeteaseCredentials") {
          std::wstring serialized = ReadCredentials(L"MeloUnion/NetEase");
          if (serialized.empty()) {
            result->Success(flutter::EncodableValue());
            return;
          }

          std::string utf8_serialized = Utf16ToUtf8(serialized);
          size_t newline_pos = utf8_serialized.find('\n');
          if (newline_pos == std::string::npos) {
            result->Success(flutter::EncodableValue());
            return;
          }

          std::string userId = utf8_serialized.substr(0, newline_pos);
          std::string cookie = utf8_serialized.substr(newline_pos + 1);

          flutter::EncodableMap response;
          response[flutter::EncodableValue("cookie")] = flutter::EncodableValue(cookie);
          if (!userId.empty()) {
            response[flutter::EncodableValue("userId")] = flutter::EncodableValue(userId);
          }
          result->Success(flutter::EncodableValue(response));
        }
        else if (call.method_name() == "writeNeteaseCredentials") {
          const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
          if (!arguments) {
            result->Error("invalid_arguments", "Arguments must be a map.");
            return;
          }

          std::string cookie;
          std::string userId;

          auto cookie_it = arguments->find(flutter::EncodableValue("cookie"));
          if (cookie_it != arguments->end() && !cookie_it->second.IsNull()) {
            if (auto val = std::get_if<std::string>(&cookie_it->second)) {
              cookie = *val;
            }
          }

          if (cookie.empty()) {
            result->Error("invalid_credentials", "NetEase cookie must not be empty.");
            return;
          }

          auto userId_it = arguments->find(flutter::EncodableValue("userId"));
          if (userId_it != arguments->end() && !userId_it->second.IsNull()) {
            if (auto val = std::get_if<std::string>(&userId_it->second)) {
              userId = *val;
            }
          }

          std::wstring serialized = Utf8ToUtf16(userId + "\n" + cookie);
          if (WriteCredentials(L"MeloUnion/NetEase", serialized)) {
            result->Success(flutter::EncodableValue(true));
          } else {
            result->Error("storage_error", "Failed to write credential to Windows Credential Manager.");
          }
        }
        else if (call.method_name() == "deleteNeteaseCredentials") {
          DeleteCredentials(L"MeloUnion/NetEase");
          result->Success(flutter::EncodableValue(true));
        }
        else if (call.method_name() == "readQqMusicCredentials") {
          std::wstring serialized = ReadCredentials(L"MeloUnion/QQMusic");
          if (serialized.empty()) {
            result->Success(flutter::EncodableValue());
            return;
          }
          flutter::EncodableMap response;
          response[flutter::EncodableValue("cookie")] = flutter::EncodableValue(Utf16ToUtf8(serialized));
          result->Success(flutter::EncodableValue(response));
        }
        else if (call.method_name() == "writeQqMusicCredentials") {
          const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
          if (!arguments) {
            result->Error("invalid_arguments", "Arguments must be a map.");
            return;
          }

          std::string cookie;
          auto cookie_it = arguments->find(flutter::EncodableValue("cookie"));
          if (cookie_it != arguments->end() && !cookie_it->second.IsNull()) {
            if (auto val = std::get_if<std::string>(&cookie_it->second)) {
              cookie = *val;
            }
          }

          if (cookie.empty()) {
            result->Error("invalid_credentials", "QQ Music cookie must not be empty.");
            return;
          }

          if (WriteCredentials(L"MeloUnion/QQMusic", Utf8ToUtf16(cookie))) {
            result->Success(flutter::EncodableValue(true));
          } else {
            result->Error("storage_error", "Failed to write credential to Windows Credential Manager.");
          }
        }
        else if (call.method_name() == "deleteQqMusicCredentials") {
          DeleteCredentials(L"MeloUnion/QQMusic");
          result->Success(flutter::EncodableValue(true));
        }
        else {
          result->NotImplemented();
        }
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
