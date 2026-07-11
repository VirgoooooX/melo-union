#include "desktop_lyrics_window.h"
#include "desktop_lyrics_tokens.h"

#include <gdiplus.h>

#include <functional>
#include <utility>

namespace {
constexpr wchar_t kLyricsClass[] = L"MeloUnionDesktopLyrics";
constexpr wchar_t kControlClass[] = L"MeloUnionDesktopLyricsControl";
constexpr int kLyricsWidth = 744;
constexpr int kLyricsHeight = 136;
constexpr int kCardInset = 12;
constexpr int kCardWidth = 720;
constexpr int kCardHeight = 112;
constexpr int kControlWidth = 32;
constexpr int kControlHeight = 32;

void RegisterWindowClass(const wchar_t* name, WNDPROC procedure) {
  WNDCLASSW window_class = {};
  window_class.lpfnWndProc = procedure;
  window_class.hInstance = GetModuleHandle(nullptr);
  window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
  window_class.lpszClassName = name;
  RegisterClassW(&window_class);
}

void AddRoundedRect(Gdiplus::GraphicsPath& path, float x, float y, float width,
                    float height, float radius) {
  const float diameter = radius * 2;
  path.AddArc(x, y, diameter, diameter, 180, 90);
  path.AddArc(x + width - diameter, y, diameter, diameter, 270, 90);
  path.AddArc(x + width - diameter, y + height - diameter, diameter, diameter,
              0, 90);
  path.AddArc(x, y + height - diameter, diameter, diameter, 90, 90);
  path.CloseFigure();
}

void PresentLayeredWindow(HWND window, int width, int height,
                          const std::function<void(Gdiplus::Graphics&)>& draw) {
  HDC screen_dc = GetDC(nullptr);
  HDC memory_dc = CreateCompatibleDC(screen_dc);
  BITMAPINFO bitmap_info = {};
  bitmap_info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bitmap_info.bmiHeader.biWidth = width;
  bitmap_info.bmiHeader.biHeight = -height;
  bitmap_info.bmiHeader.biPlanes = 1;
  bitmap_info.bmiHeader.biBitCount = 32;
  bitmap_info.bmiHeader.biCompression = BI_RGB;
  void* pixels = nullptr;
  HBITMAP bitmap = CreateDIBSection(screen_dc, &bitmap_info, DIB_RGB_COLORS,
                                    &pixels, nullptr, 0);
  auto old_bitmap = SelectObject(memory_dc, bitmap);

  {
    Gdiplus::Graphics graphics(memory_dc);
    graphics.SetSmoothingMode(Gdiplus::SmoothingModeAntiAlias);
    graphics.SetPixelOffsetMode(Gdiplus::PixelOffsetModeHighQuality);
    graphics.SetTextRenderingHint(Gdiplus::TextRenderingHintAntiAliasGridFit);
    graphics.Clear(Gdiplus::Color(0, 0, 0, 0));
    draw(graphics);
  }

  POINT source = {0, 0};
  SIZE size = {width, height};
  RECT window_rect;
  GetWindowRect(window, &window_rect);
  POINT destination = {window_rect.left, window_rect.top};
  BLENDFUNCTION blend = {AC_SRC_OVER, 0, 255, AC_SRC_ALPHA};
  UpdateLayeredWindow(window, screen_dc, &destination, &size, memory_dc,
                      &source, 0, &blend, ULW_ALPHA);

  SelectObject(memory_dc, old_bitmap);
  DeleteObject(bitmap);
  DeleteDC(memory_dc);
  ReleaseDC(nullptr, screen_dc);
}

void DrawCenteredText(Gdiplus::Graphics& graphics, const std::wstring& text,
                      const Gdiplus::RectF& bounds, float size,
                      Gdiplus::FontStyle style, Gdiplus::Color color) {
  if (text.empty()) return;
  Gdiplus::FontFamily family(L"Microsoft YaHei UI");
  Gdiplus::Font font(&family, size, style, Gdiplus::UnitPixel);
  Gdiplus::StringFormat format;
  format.SetAlignment(Gdiplus::StringAlignmentCenter);
  format.SetLineAlignment(Gdiplus::StringAlignmentCenter);
  format.SetTrimming(Gdiplus::StringTrimmingEllipsisCharacter);
  format.SetFormatFlags(Gdiplus::StringFormatFlagsNoWrap);
  Gdiplus::SolidBrush foreground(color);
  graphics.DrawString(text.c_str(), -1, &font, bounds, &format, &foreground);
}

void DrawCenteredTextWithShadow(Gdiplus::Graphics& graphics, const std::wstring& text,
                                const Gdiplus::RectF& bounds, float size,
                                Gdiplus::FontStyle style, Gdiplus::Color color,
                                Gdiplus::Color shadow_color, float offset_x, float offset_y) {
  if (text.empty()) return;
  Gdiplus::FontFamily family(L"Microsoft YaHei UI");
  Gdiplus::Font font(&family, size, style, Gdiplus::UnitPixel);
  Gdiplus::StringFormat format;
  format.SetAlignment(Gdiplus::StringAlignmentCenter);
  format.SetLineAlignment(Gdiplus::StringAlignmentCenter);
  format.SetTrimming(Gdiplus::StringTrimmingEllipsisCharacter);
  format.SetFormatFlags(Gdiplus::StringFormatFlagsNoWrap);

  // Draw shadow first
  Gdiplus::RectF shadow_bounds(bounds.X + offset_x, bounds.Y + offset_y, bounds.Width, bounds.Height);
  Gdiplus::SolidBrush shadow_brush(shadow_color);
  graphics.DrawString(text.c_str(), -1, &font, shadow_bounds, &format, &shadow_brush);

  // Draw foreground
  Gdiplus::SolidBrush foreground(color);
  graphics.DrawString(text.c_str(), -1, &font, bounds, &format, &foreground);
}
}  // namespace

DesktopLyricsWindow::DesktopLyricsWindow(LockChangedCallback on_lock_changed)
    : on_lock_changed_(std::move(on_lock_changed)) {
  Gdiplus::GdiplusStartupInput startup_input;
  Gdiplus::GdiplusStartup(&gdiplus_token_, &startup_input, nullptr);
}

DesktopLyricsWindow::~DesktopLyricsWindow() {
  if (control_window_) DestroyWindow(control_window_);
  if (lyrics_window_) DestroyWindow(lyrics_window_);
  if (gdiplus_token_) Gdiplus::GdiplusShutdown(gdiplus_token_);
}

bool DesktopLyricsWindow::EnsureCreated() {
  if (lyrics_window_ && control_window_) return true;
  RegisterWindowClass(kLyricsClass, LyricsWndProc);
  RegisterWindowClass(kControlClass, HandleWndProc);

  const int x = (GetSystemMetrics(SM_CXSCREEN) - kLyricsWidth) / 2;
  const int y = GetSystemMetrics(SM_CYSCREEN) - 220;
  lyrics_window_ = CreateWindowExW(
      WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE | WS_EX_LAYERED,
      kLyricsClass, L"MeloUnion 桌面歌词", WS_POPUP, x, y, kLyricsWidth,
      kLyricsHeight, nullptr, nullptr, GetModuleHandle(nullptr), this);
  control_window_ = CreateWindowExW(
      WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE | WS_EX_LAYERED,
      kControlClass, L"桌面歌词锁定控制", WS_POPUP,
      x + kCardInset + kCardWidth - kControlWidth - 20,
      y + kCardInset + (kCardHeight - kControlHeight) / 2,
      kControlWidth,
      kControlHeight,
      nullptr, nullptr, GetModuleHandle(nullptr), this);
  return lyrics_window_ && control_window_;
}

bool DesktopLyricsWindow::Show() {
  if (!EnsureCreated()) return false;
  PaintLyrics(lyrics_window_);
  PaintControl(control_window_);
  ShowWindow(lyrics_window_, SW_SHOWNOACTIVATE);
  ShowWindow(control_window_, SW_SHOWNOACTIVATE);
  return true;
}

void DesktopLyricsWindow::Hide() {
  if (lyrics_window_) ShowWindow(lyrics_window_, SW_HIDE);
  if (control_window_) ShowWindow(control_window_, SW_HIDE);
}

void DesktopLyricsWindow::Update(const std::wstring& current,
                                 const std::wstring& next) {
  current_ = current;
  next_ = next;
  if (lyrics_window_) PaintLyrics(lyrics_window_);
}

void DesktopLyricsWindow::SetLocked(bool locked) {
  locked_ = locked;
  if (lyrics_window_) {
    LONG_PTR style = GetWindowLongPtr(lyrics_window_, GWL_EXSTYLE);
    style = locked ? style | WS_EX_TRANSPARENT
                   : style & ~static_cast<LONG_PTR>(WS_EX_TRANSPARENT);
    SetWindowLongPtr(lyrics_window_, GWL_EXSTYLE, style);
  }
  if (control_window_) PaintControl(control_window_);
}

void DesktopLyricsWindow::PositionControl() {
  if (!lyrics_window_ || !control_window_) return;
  RECT rect;
  GetWindowRect(lyrics_window_, &rect);
  SetWindowPos(control_window_, HWND_TOPMOST,
               rect.left + kCardInset + kCardWidth - kControlWidth - 20,
               rect.top + kCardInset + (kCardHeight - kControlHeight) / 2,
               kControlWidth, kControlHeight,
               SWP_NOACTIVATE | SWP_SHOWWINDOW);
}

void DesktopLyricsWindow::PaintLyrics(HWND window) {
  PresentLayeredWindow(window, kLyricsWidth, kLyricsHeight,
                       [this](Gdiplus::Graphics& graphics) {
    using namespace melo_tokens;
    for (int layer = 5; layer >= 1; --layer) {
      Gdiplus::GraphicsPath shadow;
      const float spread = static_cast<float>(layer * 2);
      AddRoundedRect(shadow, kCardInset - spread,
                     kCardInset + 6 - spread / 2,
                     kCardWidth + spread * 2,
                     kCardHeight + spread, kRadiusLg + spread);
      Gdiplus::SolidBrush shadow_brush(
          Gdiplus::Color(static_cast<BYTE>(2 + layer), kFloatingShadow.GetR(),
                         kFloatingShadow.GetG(), kFloatingShadow.GetB()));
      graphics.FillPath(&shadow_brush, &shadow);
    }

    Gdiplus::GraphicsPath panel;
    AddRoundedRect(panel, kCardInset, kCardInset, kCardWidth, kCardHeight,
                   kRadiusLg);
    
    // Create a beautiful linear gradient brush from top to bottom
    Gdiplus::LinearGradientBrush background_brush(
        Gdiplus::PointF(static_cast<float>(kCardInset), static_cast<float>(kCardInset)),
        Gdiplus::PointF(static_cast<float>(kCardInset), static_cast<float>(kCardInset + kCardHeight)),
        Gdiplus::Color(215, 255, 255, 255), // Top: soft translucent white
        Gdiplus::Color(215, 234, 248, 246)  // Bottom: soft translucent kPrimary50
    );
    graphics.FillPath(&background_brush, &panel);
    
    // Soft transparent border using kPrimary100
    Gdiplus::Pen border(Gdiplus::Color(200, 207, 243, 238), 1.0f);
    graphics.DrawPath(&border, &panel);

    // Perfectly centered current lyric with themed glow shadow
    DrawCenteredTextWithShadow(
        graphics, current_,
        Gdiplus::RectF(static_cast<float>(kCardInset + 54), static_cast<float>(kCardInset + 14),
                       static_cast<float>(kCardWidth - 108), 48.0f),
        24.0f, Gdiplus::FontStyleBold, kPrimary700,
        Gdiplus::Color(35, 8, 124, 118), 1.0f, 1.5f);
        
    // Perfectly centered next lyric
    DrawCenteredText(
        graphics, next_,
        Gdiplus::RectF(static_cast<float>(kCardInset + 54), static_cast<float>(kCardInset + 64),
                       static_cast<float>(kCardWidth - 108), 30.0f),
        15.0f, Gdiplus::FontStyleRegular, kTextSecondary);
  });
}

void DesktopLyricsWindow::PaintControl(HWND window) {
  PresentLayeredWindow(window, kControlWidth, kControlHeight,
                       [this](Gdiplus::Graphics& graphics) {
    using namespace melo_tokens;
    Gdiplus::GraphicsPath pill;
    AddRoundedRect(pill, 1.0f, 1.0f, kControlWidth - 2.0f, kControlHeight - 2.0f,
                   (kControlHeight - 2.0f) / 2);
    
    // Choose colors based on locked and hovered state
    Gdiplus::Color bg_color;
    Gdiplus::Color border_color = kPrimary100;
    Gdiplus::Color icon_color = kPrimary700;
    
    if (locked_) {
      bg_color = control_hovered_ ? kPrimary100 : kSurfaceSelected;
    } else {
      bg_color = control_hovered_ ? kPrimary100 : kPrimary50;
    }
    
    Gdiplus::SolidBrush background(bg_color);
    graphics.FillPath(&background, &pill);
    
    Gdiplus::Pen border(border_color, 1.0f);
    graphics.DrawPath(&border, &pill);
    
    // Draw vector lock icon!
    float icon_size = 32.0f;
    float x = (kControlWidth - icon_size) / 2.0f;
    float y = (kControlHeight - icon_size) / 2.0f;
    
    // Body of the lock: width 14, height 10, radius 2
    Gdiplus::GraphicsPath body_path;
    AddRoundedRect(body_path, x + 9.0f, y + 15.0f, 14.0f, 10.0f, 2.0f);
    Gdiplus::SolidBrush body_brush(icon_color);
    graphics.FillPath(&body_brush, &body_path);
    
    // Shackle of the lock
    Gdiplus::GraphicsPath shackle_path;
    if (locked_) {
      // Locked: Closed shackle
      shackle_path.AddArc(x + 11.5f, y + 8.0f, 9.0f, 9.0f, 180.0f, 180.0f);
      shackle_path.AddLine(x + 11.5f, y + 12.5f, x + 11.5f, y + 15.0f);
      shackle_path.AddLine(x + 20.5f, y + 12.5f, x + 20.5f, y + 15.0f);
    } else {
      // Unlocked: Open shackle (shifted up and open on the right)
      shackle_path.AddArc(x + 11.5f, y + 5.0f, 9.0f, 9.0f, 180.0f, 180.0f);
      shackle_path.AddLine(x + 11.5f, y + 9.5f, x + 11.5f, y + 15.0f);
      shackle_path.AddLine(x + 20.5f, y + 9.5f, x + 20.5f, y + 11.5f);
    }
    
    Gdiplus::Pen shackle_pen(icon_color, 2.0f);
    shackle_pen.SetStartCap(Gdiplus::LineCapRound);
    shackle_pen.SetEndCap(Gdiplus::LineCapRound);
    graphics.DrawPath(&shackle_pen, &shackle_path);
    
    // Keyhole
    Gdiplus::SolidBrush keyhole_brush(bg_color);
    graphics.FillEllipse(&keyhole_brush, x + 14.5f, y + 18.5f, 3.0f, 3.0f);
  });
}

LRESULT CALLBACK DesktopLyricsWindow::LyricsWndProc(HWND window, UINT message,
                                                     WPARAM wparam,
                                                     LPARAM lparam) {
  auto* self = reinterpret_cast<DesktopLyricsWindow*>(
      GetWindowLongPtr(window, GWLP_USERDATA));
  if (message == WM_NCCREATE) {
    auto* create = reinterpret_cast<CREATESTRUCT*>(lparam);
    self = static_cast<DesktopLyricsWindow*>(create->lpCreateParams);
    SetWindowLongPtr(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(self));
  }
  return self ? self->HandleLyricsMessage(window, message, wparam, lparam)
              : DefWindowProc(window, message, wparam, lparam);
}

LRESULT CALLBACK DesktopLyricsWindow::HandleWndProc(HWND window, UINT message,
                                                     WPARAM wparam,
                                                     LPARAM lparam) {
  auto* self = reinterpret_cast<DesktopLyricsWindow*>(
      GetWindowLongPtr(window, GWLP_USERDATA));
  if (message == WM_NCCREATE) {
    auto* create = reinterpret_cast<CREATESTRUCT*>(lparam);
    self = static_cast<DesktopLyricsWindow*>(create->lpCreateParams);
    SetWindowLongPtr(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(self));
  }
  return self ? self->HandleControlMessage(window, message, wparam, lparam)
              : DefWindowProc(window, message, wparam, lparam);
}

LRESULT DesktopLyricsWindow::HandleLyricsMessage(HWND window, UINT message,
                                                  WPARAM wparam,
                                                  LPARAM lparam) {
  switch (message) {
    case WM_PAINT: {
      PAINTSTRUCT paint;
      BeginPaint(window, &paint);
      EndPaint(window, &paint);
      PaintLyrics(window);
      return 0;
    }
    case WM_NCHITTEST:
      return locked_ ? HTTRANSPARENT : HTCAPTION;
    case WM_WINDOWPOSCHANGED:
      PositionControl();
      break;
    case WM_ERASEBKGND:
      return 1;
  }
  return DefWindowProc(window, message, wparam, lparam);
}

LRESULT DesktopLyricsWindow::HandleControlMessage(HWND window, UINT message,
                                                   WPARAM wparam,
                                                   LPARAM lparam) {
  switch (message) {
    case WM_PAINT: {
      PAINTSTRUCT paint;
      BeginPaint(window, &paint);
      EndPaint(window, &paint);
      PaintControl(window);
      return 0;
    }
    case WM_MOUSEMOVE: {
      if (!tracking_mouse_) {
        TRACKMOUSEEVENT tme = {};
        tme.cbSize = sizeof(TRACKMOUSEEVENT);
        tme.dwFlags = TME_LEAVE;
        tme.hwndTrack = window;
        TrackMouseEvent(&tme);
        tracking_mouse_ = true;
      }
      if (!control_hovered_) {
        control_hovered_ = true;
        PaintControl(window);
      }
      break;
    }
    case WM_MOUSELEAVE: {
      control_hovered_ = false;
      tracking_mouse_ = false;
      PaintControl(window);
      break;
    }
    case WM_LBUTTONUP:
      SetLocked(!locked_);
      if (on_lock_changed_) on_lock_changed_(locked_);
      return 0;
    case WM_NCHITTEST:
      return HTCLIENT;
    case WM_ERASEBKGND:
      return 1;
  }
  return DefWindowProc(window, message, wparam, lparam);
}
