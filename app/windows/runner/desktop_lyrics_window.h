#ifndef RUNNER_DESKTOP_LYRICS_WINDOW_H_
#define RUNNER_DESKTOP_LYRICS_WINDOW_H_

#include <windows.h>

#include <functional>
#include <string>

class DesktopLyricsWindow {
 public:
  using SettingChangedCallback = std::function<void(bool locked, double opacity, bool doubleLine, bool showCard, double fontScale)>;

  explicit DesktopLyricsWindow(SettingChangedCallback on_setting_changed);
  ~DesktopLyricsWindow();

  bool Show();
  void Hide();
  void Update(const std::wstring& current, const std::wstring& next);
  void SetLocked(bool locked);
  void SetSettings(bool locked, double opacity, bool double_line, bool show_card, double font_scale);

 private:
  enum class HoveredButton {
    None,
    Mode,
    ShowCard,
    Opacity,
    FontSizeDec,
    FontSizeInc,
    Lock
  };

  static LRESULT CALLBACK LyricsWndProc(HWND window, UINT message,
                                        WPARAM wparam, LPARAM lparam);
  static LRESULT CALLBACK HandleWndProc(HWND window, UINT message,
                                        WPARAM wparam, LPARAM lparam);
  LRESULT HandleLyricsMessage(HWND window, UINT message, WPARAM wparam,
                              LPARAM lparam);
  LRESULT HandleControlMessage(HWND window, UINT message, WPARAM wparam,
                              LPARAM lparam);
  bool EnsureCreated();
  void PositionControl();
  void PaintLyrics(HWND window);
  void PaintControl(HWND window);
  void UpdateControlVisibility();

  HWND lyrics_window_ = nullptr;
  HWND control_window_ = nullptr;
  
  bool locked_ = false;
  bool lyrics_hovered_ = false;
  bool control_hovered_ = false;
  bool tracking_lyrics_mouse_ = false;
  bool tracking_control_mouse_ = false;
  
  bool double_line_ = true;
  bool show_card_ = true;
  double font_scale_ = 1.0;
  BYTE opacity_alpha_ = 255;
  HoveredButton hovered_button_ = HoveredButton::None;

  std::wstring current_ = L"播放歌曲后显示桌面歌词";
  std::wstring next_;
  SettingChangedCallback on_setting_changed_;
  ULONG_PTR gdiplus_token_ = 0;
};

#endif  // RUNNER_DESKTOP_LYRICS_WINDOW_H_
