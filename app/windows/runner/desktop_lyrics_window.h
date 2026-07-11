#ifndef RUNNER_DESKTOP_LYRICS_WINDOW_H_
#define RUNNER_DESKTOP_LYRICS_WINDOW_H_

#include <windows.h>

#include <functional>
#include <string>

class DesktopLyricsWindow {
 public:
  using LockChangedCallback = std::function<void(bool)>;

  explicit DesktopLyricsWindow(LockChangedCallback on_lock_changed);
  ~DesktopLyricsWindow();

  bool Show();
  void Hide();
  void Update(const std::wstring& current, const std::wstring& next);
  void SetLocked(bool locked);

 private:
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

  HWND lyrics_window_ = nullptr;
  HWND control_window_ = nullptr;
  bool locked_ = false;
  bool control_hovered_ = false;
  bool tracking_mouse_ = false;
  std::wstring current_ = L"播放歌曲后显示桌面歌词";
  std::wstring next_;
  LockChangedCallback on_lock_changed_;
  ULONG_PTR gdiplus_token_ = 0;
};

#endif  // RUNNER_DESKTOP_LYRICS_WINDOW_H_
