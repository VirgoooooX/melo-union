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
constexpr int kControlWidth = 190;
constexpr int kControlHeight = 56;

void RegisterWindowClass(const wchar_t* name, WNDPROC procedure) {
  WNDCLASSW window_class = {};
  window_class.lpfnWndProc = procedure;
  window_class.hInstance = GetModuleHandle(nullptr);
  window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
  window_class.lpszClassName = name;
  window_class.style = CS_HREDRAW | CS_VREDRAW;
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

void PresentLayeredWindow(HWND window, int width, int height, BYTE constant_alpha,
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
  BLENDFUNCTION blend = {AC_SRC_OVER, 0, constant_alpha, AC_SRC_ALPHA};
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

DesktopLyricsWindow::DesktopLyricsWindow(SettingChangedCallback on_setting_changed)
    : on_setting_changed_(std::move(on_setting_changed)) {
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

  const int current_width = static_cast<int>(kLyricsWidth * font_scale_);
  const int current_height = static_cast<int>(kLyricsHeight * font_scale_);
  const int x = (GetSystemMetrics(SM_CXSCREEN) - current_width) / 2;
  const int y = GetSystemMetrics(SM_CYSCREEN) - 220;
  
  // Added WS_THICKFRAME to support resizing
  lyrics_window_ = CreateWindowExW(
      WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE | WS_EX_LAYERED,
      kLyricsClass, L"MeloUnion 桌面歌词", WS_POPUP | WS_THICKFRAME, x, y, current_width,
      current_height, nullptr, nullptr, GetModuleHandle(nullptr), this);
      
  control_window_ = CreateWindowExW(
      WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE | WS_EX_LAYERED,
      kControlClass, L"桌面歌词控制工具栏", WS_POPUP,
      x + (current_width - kControlWidth) / 2,
      y + kCardInset - kControlHeight - 4, // Float 4px above the card's top edge
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
  UpdateControlVisibility();
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
  UpdateControlVisibility();
  if (control_window_) PaintControl(control_window_);
}

void DesktopLyricsWindow::SetSettings(bool locked, double opacity, bool double_line, bool show_card, double font_scale) {
  double_line_ = double_line;
  show_card_ = show_card;
  font_scale_ = font_scale;
  opacity_alpha_ = static_cast<BYTE>(opacity * 255.0);
  
  if (lyrics_window_) {
    RECT rect;
    GetWindowRect(lyrics_window_, &rect);
    int new_width = static_cast<int>(kLyricsWidth * font_scale_);
    int new_height = static_cast<int>(kLyricsHeight * font_scale_);
    int cx = rect.left + (rect.right - rect.left) / 2;
    int cy = rect.top + (rect.bottom - rect.top) / 2;
    SetWindowPos(lyrics_window_, nullptr,
                 cx - new_width / 2, cy - new_height / 2,
                 new_width, new_height,
                 SWP_NOZORDER | SWP_NOACTIVATE);
  }
  
  SetLocked(locked);
  if (lyrics_window_) PaintLyrics(lyrics_window_);
  if (control_window_) PaintControl(control_window_);
}

void DesktopLyricsWindow::PositionControl() {
  if (!lyrics_window_ || !control_window_) return;
  RECT rect;
  GetWindowRect(lyrics_window_, &rect);
  int width = rect.right - rect.left;
  SetWindowPos(control_window_, HWND_TOPMOST,
               rect.left + (width - kControlWidth) / 2,
               rect.top + kCardInset - kControlHeight - 4, // Float 4px above the card's top edge
               kControlWidth, kControlHeight,
               SWP_NOACTIVATE | SWP_SHOWWINDOW);
}

void DesktopLyricsWindow::UpdateControlVisibility() {
  if (!control_window_) return;
  bool should_show = locked_ || lyrics_hovered_ || control_hovered_;
  ShowWindow(control_window_, should_show ? SW_SHOWNOACTIVATE : SW_HIDE);
}

void DesktopLyricsWindow::PaintLyrics(HWND window) {
  RECT rect;
  GetClientRect(window, &rect);
  int width = rect.right - rect.left;
  int height = rect.bottom - rect.top;
  if (width <= 0 || height <= 0) return;

  PresentLayeredWindow(window, width, height, opacity_alpha_,
                       [this, width, height](Gdiplus::Graphics& graphics) {
    using namespace melo_tokens;
    float f_inset = static_cast<float>(kCardInset);
    float card_width = static_cast<float>(width) - f_inset * 2.0f;
    float card_height = static_cast<float>(height) - f_inset * 2.0f;

    if (show_card_) {
      for (int layer = 5; layer >= 1; --layer) {
        Gdiplus::GraphicsPath shadow;
        const float spread = static_cast<float>(layer * 2);
        AddRoundedRect(shadow, f_inset - spread,
                       f_inset + 6.0f - spread / 2.0f,
                       card_width + spread * 2.0f,
                       card_height + spread, kRadiusLg + spread);
        Gdiplus::SolidBrush shadow_brush(
            Gdiplus::Color(static_cast<BYTE>(2 + layer), kFloatingShadow.GetR(),
                           kFloatingShadow.GetG(), kFloatingShadow.GetB()));
        graphics.FillPath(&shadow_brush, &shadow);
      }

      Gdiplus::GraphicsPath panel;
      AddRoundedRect(panel, f_inset, f_inset, card_width, card_height,
                     kRadiusLg);
      
      // Create a beautiful linear gradient brush from top to bottom
      Gdiplus::LinearGradientBrush background_brush(
          Gdiplus::PointF(f_inset, f_inset),
          Gdiplus::PointF(f_inset, f_inset + card_height),
          Gdiplus::Color(215, 255, 255, 255), // Top: soft translucent white
          Gdiplus::Color(215, 234, 248, 246)  // Bottom: soft translucent kPrimary50
      );
      graphics.FillPath(&background_brush, &panel);
      
      // Soft transparent border using kPrimary100
      Gdiplus::Pen border(Gdiplus::Color(200, 207, 243, 238), 1.0f);
      graphics.DrawPath(&border, &panel);
    }

    // Dynamic layout: 1 line or 2 lines
    if (!double_line_ || card_height < 80.0f) {
      // 1 line mode - centered lyrics occupying full width
      float current_font_size = card_height * 0.32f;
      if (current_font_size < 12.0f) current_font_size = 12.0f;
      if (current_font_size > 72.0f) current_font_size = 72.0f;
      
      DrawCenteredTextWithShadow(
          graphics, current_,
          Gdiplus::RectF(f_inset + 20.0f, f_inset + 4.0f,
                         card_width - 40.0f, card_height - 8.0f),
          current_font_size, Gdiplus::FontStyleBold, kPrimary700,
          Gdiplus::Color(35, 8, 124, 118), 1.0f, 1.5f);
    } else {
      // 2 lines mode - centered lyrics occupying full width
      float current_font_size = card_height * 0.22f;
      if (current_font_size < 12.0f) current_font_size = 12.0f;
      if (current_font_size > 64.0f) current_font_size = 64.0f;
      
      float next_font_size = card_height * 0.14f;
      if (next_font_size < 10.0f) next_font_size = 10.0f;
      if (next_font_size > 40.0f) next_font_size = 40.0f;
      
      float current_y = f_inset + card_height * 0.15f;
      float current_h = card_height * 0.45f;
      float next_y = f_inset + card_height * 0.58f;
      float next_h = card_height * 0.30f;

      // Draw current lyric
      DrawCenteredTextWithShadow(
          graphics, current_,
          Gdiplus::RectF(f_inset + 20.0f, current_y,
                         card_width - 40.0f, current_h),
          current_font_size, Gdiplus::FontStyleBold, kPrimary700,
          Gdiplus::Color(35, 8, 124, 118), 1.0f, 1.5f);
          
      // Draw next lyric
      DrawCenteredText(
          graphics, next_,
          Gdiplus::RectF(f_inset + 20.0f, next_y,
                         card_width - 40.0f, next_h),
          next_font_size, Gdiplus::FontStyleRegular, kTextSecondary);
    }
  });
}

void DesktopLyricsWindow::PaintControl(HWND window) {
  PresentLayeredWindow(window, kControlWidth, kControlHeight, 255,
                       [this](Gdiplus::Graphics& graphics) {
    using namespace melo_tokens;
    
    Gdiplus::Color icon_color = kPrimary700;
    Gdiplus::Color hover_bg_color = Gdiplus::Color(180, 207, 243, 238); // Soft translucent hover circle

    auto draw_button_bg = [&](float btn_x, float btn_y, bool is_hovered) {
      if (is_hovered) {
        Gdiplus::GraphicsPath btn_path;
        AddRoundedRect(btn_path, btn_x, btn_y, 24.0f, 24.0f, 12.0f);
        Gdiplus::SolidBrush btn_bg(hover_bg_color);
        graphics.FillPath(&btn_bg, &btn_path);
      }
    };

    std::wstring tooltip_text;

    if (!locked_) {
      // Draw horizontal pill frame around the entire control panel (190x32 inside 190x56 window at y = 20.0f)
      Gdiplus::GraphicsPath panel_path;
      AddRoundedRect(panel_path, 0.0f, 20.0f, 190.0f, 32.0f, 16.0f);
      Gdiplus::SolidBrush panel_bg(Gdiplus::Color(215, 248, 252, 250)); // Translucent mint white glass
      graphics.FillPath(&panel_bg, &panel_path);
      Gdiplus::Pen panel_border(Gdiplus::Color(180, 207, 243, 238), 1.0f);
      graphics.DrawPath(&panel_border, &panel_path);

      float y = 24.0f; // Buttons are at y = 24

      // Button 1: Mode (x = 8)
      draw_button_bg(8.0f, y, hovered_button_ == HoveredButton::Mode);
      float x1 = 8.0f;
      Gdiplus::Pen pen_mode(icon_color, 2.0f);
      pen_mode.SetStartCap(Gdiplus::LineCapRound);
      pen_mode.SetEndCap(Gdiplus::LineCapRound);
      if (double_line_) {
        // Modern minimalist text alignment icon (top line longer, bottom line shorter)
        graphics.DrawLine(&pen_mode, x1 + 6.0f, y + 9.0f, x1 + 18.0f, y + 9.0f);
        graphics.DrawLine(&pen_mode, x1 + 6.0f, y + 15.0f, x1 + 15.0f, y + 15.0f);
      } else {
        Gdiplus::Pen single_pen(icon_color, 2.5f);
        single_pen.SetStartCap(Gdiplus::LineCapRound);
        single_pen.SetEndCap(Gdiplus::LineCapRound);
        graphics.DrawLine(&single_pen, x1 + 5.0f, y + 12.0f, x1 + 19.0f, y + 12.0f);
      }
      if (hovered_button_ == HoveredButton::Mode) tooltip_text = L"单行 / 双行 切换";

      // Button 2: Show/Hide Card (x = 38)
      draw_button_bg(38.0f, y, hovered_button_ == HoveredButton::ShowCard);
      float x2 = 38.0f;
      Gdiplus::Pen pen_card(icon_color, 1.8f);
      graphics.DrawRectangle(&pen_card, x2 + 6.0f, y + 6.0f, 12.0f, 12.0f);
      if (show_card_) {
        Gdiplus::SolidBrush solid_brush(icon_color);
        graphics.FillRectangle(&solid_brush, x2 + 9.5f, y + 9.5f, 5.0f, 5.0f);
      } else {
        graphics.DrawLine(&pen_card, x2 + 6.0f, y + 6.0f, x2 + 18.0f, y + 18.0f);
      }
      if (hovered_button_ == HoveredButton::ShowCard) tooltip_text = L"显示 / 隐藏 背景卡片";

      // Button 3: Opacity (x = 68)
      draw_button_bg(68.0f, y, hovered_button_ == HoveredButton::Opacity);
      float x3 = 68.0f;
      Gdiplus::Pen pen_op(icon_color, 1.5f);
      graphics.DrawEllipse(&pen_op, x3 + 6.0f, y + 6.0f, 12.0f, 12.0f);
      
      // Contrast style half-filled circle representing opacity
      Gdiplus::SolidBrush fill_brush(Gdiplus::Color(opacity_alpha_, icon_color.GetR(), icon_color.GetG(), icon_color.GetB()));
      graphics.FillPie(&fill_brush, x3 + 6.0f, y + 6.0f, 12.0f, 12.0f, 270.0f, 180.0f);
      
      // Draw vertical divider down the middle of the opacity dial
      graphics.DrawLine(&pen_op, x3 + 12.0f, y + 6.0f, x3 + 12.0f, y + 18.0f);
      if (hovered_button_ == HoveredButton::Opacity) tooltip_text = L"调节歌词不透明度";

      // Button 4: Font Size Decrease (x = 98)
      draw_button_bg(98.0f, y, hovered_button_ == HoveredButton::FontSizeDec);
      float x4 = 98.0f;
      Gdiplus::Pen pen_fdec(icon_color, 1.8f);
      graphics.DrawLine(&pen_fdec, x4 + 7.0f, y + 16.0f, x4 + 10.0f, y + 8.0f);
      graphics.DrawLine(&pen_fdec, x4 + 10.0f, y + 8.0f, x4 + 13.0f, y + 16.0f);
      graphics.DrawLine(&pen_fdec, x4 + 8.5f, y + 13.0f, x4 + 11.5f, y + 13.0f);
      graphics.DrawLine(&pen_fdec, x4 + 16.0f, y + 12.0f, x4 + 20.0f, y + 12.0f);
      if (hovered_button_ == HoveredButton::FontSizeDec) tooltip_text = L"减小歌词字号";

      // Button 5: Font Size Increase (x = 128)
      draw_button_bg(128.0f, y, hovered_button_ == HoveredButton::FontSizeInc);
      float x5 = 128.0f;
      Gdiplus::Pen pen_finc(icon_color, 1.8f);
      graphics.DrawLine(&pen_finc, x5 + 7.0f, y + 16.0f, x5 + 10.0f, y + 8.0f);
      graphics.DrawLine(&pen_finc, x5 + 10.0f, y + 8.0f, x5 + 13.0f, y + 16.0f);
      graphics.DrawLine(&pen_finc, x5 + 8.5f, y + 13.0f, x5 + 11.5f, y + 13.0f);
      graphics.DrawLine(&pen_finc, x5 + 15.0f, y + 12.0f, x5 + 21.0f, y + 12.0f);
      graphics.DrawLine(&pen_finc, x5 + 18.0f, y + 9.0f, x5 + 18.0f, y + 15.0f);
      if (hovered_button_ == HoveredButton::FontSizeInc) tooltip_text = L"增大歌词字号";

      // Button 6: Lock (x = 158)
      draw_button_bg(158.0f, y, hovered_button_ == HoveredButton::Lock);
      float x6 = 158.0f;
      Gdiplus::GraphicsPath body_path;
      AddRoundedRect(body_path, x6 + 6.0f, y + 12.0f, 12.0f, 8.0f, 1.5f);
      Gdiplus::SolidBrush body_brush(icon_color);
      graphics.FillPath(&body_brush, &body_path);
      Gdiplus::GraphicsPath shackle_path;
      shackle_path.AddLine(x6 + 8.0f, y + 12.0f, x6 + 8.0f, y + 8.0f);
      shackle_path.AddArc(x6 + 8.0f, y + 4.5f, 8.0f, 7.0f, 180.0f, 180.0f);
      shackle_path.AddLine(x6 + 16.0f, y + 8.0f, x6 + 16.0f, y + 9.5f);
      Gdiplus::Pen shackle_pen(icon_color, 1.8f);
      shackle_pen.SetStartCap(Gdiplus::LineCapRound);
      shackle_pen.SetEndCap(Gdiplus::LineCapRound);
      graphics.DrawPath(&shackle_pen, &shackle_path);
      Gdiplus::Color key_bg = (hovered_button_ == HoveredButton::Lock ? hover_bg_color : kPrimary50);
      Gdiplus::SolidBrush keyhole_brush(key_bg);
      graphics.FillEllipse(&keyhole_brush, x6 + 10.5f, y + 14.5f, 3.0f, 3.0f);
      if (hovered_button_ == HoveredButton::Lock) tooltip_text = L"锁定桌面歌词";
    } else {
      // Locked state: Draw a single Lock button circle at the horizontal center (83.0f, 24.0f)
      draw_button_bg(83.0f, 24.0f, hovered_button_ == HoveredButton::Lock);
      float x = 83.0f;
      float y = 24.0f;
      const bool lock_hovered = hovered_button_ == HoveredButton::Lock;
      const BYTE locked_icon_alpha = 105;
      Gdiplus::Color locked_icon_color = lock_hovered
          ? icon_color
          : Gdiplus::Color(locked_icon_alpha, icon_color.GetR(),
                           icon_color.GetG(), icon_color.GetB());
      Gdiplus::GraphicsPath body_path;
      AddRoundedRect(body_path, x + 6.0f, y + 12.0f, 12.0f, 8.0f, 1.5f);
      Gdiplus::SolidBrush body_brush(locked_icon_color);
      graphics.FillPath(&body_brush, &body_path);
      Gdiplus::GraphicsPath shackle_path;
      shackle_path.AddLine(x + 8.0f, y + 12.0f, x + 8.0f, y + 10.0f);
      shackle_path.AddArc(x + 8.0f, y + 6.5f, 8.0f, 7.0f, 180.0f, 180.0f);
      shackle_path.AddLine(x + 16.0f, y + 10.0f, x + 16.0f, y + 12.0f);
      Gdiplus::Pen shackle_pen(locked_icon_color, 1.8f);
      shackle_pen.SetStartCap(Gdiplus::LineCapRound);
      shackle_pen.SetEndCap(Gdiplus::LineCapRound);
      graphics.DrawPath(&shackle_pen, &shackle_path);
      Gdiplus::Color key_bg = kSurfaceSelected;
      Gdiplus::SolidBrush keyhole_brush(key_bg);
      graphics.FillEllipse(&keyhole_brush, x + 10.5f, y + 14.5f, 3.0f, 3.0f);
      if (hovered_button_ == HoveredButton::Lock) tooltip_text = L"解锁桌面歌词";
    }

    // Draw the tooltip centered at the top of the window (y = 0 to 16)
    if (!tooltip_text.empty()) {
      Gdiplus::RectF tooltip_bounds(0.0f, 0.0f, 190.0f, 16.0f);
      DrawCenteredText(graphics, tooltip_text, tooltip_bounds, 11.0f, Gdiplus::FontStyleRegular, kPrimary700);
    }
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
    case WM_NCCALCSIZE:
      return 0;
    case WM_PAINT: {
      PAINTSTRUCT paint;
      BeginPaint(window, &paint);
      EndPaint(window, &paint);
      PaintLyrics(window);
      return 0;
    }
    case WM_NCHITTEST: {
      if (locked_) return HTTRANSPARENT;
      
      short x = static_cast<short>(LOWORD(lparam));
      short y = static_cast<short>(HIWORD(lparam));
      POINT pt = { x, y };
      RECT rect;
      GetWindowRect(window, &rect);
      
      const int border = 8;
      bool left = (pt.x < rect.left + border);
      bool right = (pt.x >= rect.right - border);
      bool top = (pt.y < rect.top + border);
      bool bottom = (pt.y >= rect.bottom - border);
      
      if (left && top) return HTTOPLEFT;
      if (right && top) return HTTOPRIGHT;
      if (left && bottom) return HTBOTTOMLEFT;
      if (right && bottom) return HTBOTTOMRIGHT;
      if (left) return HTLEFT;
      if (right) return HTRIGHT;
      if (top) return HTTOP;
      if (bottom) return HTBOTTOM;
      
      return HTCAPTION;
    }
    case WM_GETMINMAXINFO: {
      auto* info = reinterpret_cast<MINMAXINFO*>(lparam);
      info->ptMinTrackSize.x = 350;
      info->ptMinTrackSize.y = 80;
      info->ptMaxTrackSize.x = 1920;
      info->ptMaxTrackSize.y = 400;
      return 0;
    }
    case WM_WINDOWPOSCHANGED:
      PositionControl();
      PaintLyrics(window);
      break;
    case WM_MOUSEMOVE: {
      if (locked_) break;
      if (!tracking_lyrics_mouse_) {
        TRACKMOUSEEVENT tme = {};
        tme.cbSize = sizeof(TRACKMOUSEEVENT);
        tme.dwFlags = TME_LEAVE;
        tme.hwndTrack = window;
        TrackMouseEvent(&tme);
        tracking_lyrics_mouse_ = true;
      }
      
      short my = static_cast<short>(HIWORD(lparam));
      // Trigger when the mouse is near the top edge of the card (e.g. from top edge y=12 down to y=45)
      bool in_top_area = (my >= 0 && my < 45);
      if (in_top_area != lyrics_hovered_) {
        lyrics_hovered_ = in_top_area;
        UpdateControlVisibility();
      }
      break;
    }
    case WM_MOUSELEAVE: {
      lyrics_hovered_ = false;
      tracking_lyrics_mouse_ = false;
      UpdateControlVisibility();
      break;
    }
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
      if (!tracking_control_mouse_) {
        TRACKMOUSEEVENT tme = {};
        tme.cbSize = sizeof(TRACKMOUSEEVENT);
        tme.dwFlags = TME_LEAVE;
        tme.hwndTrack = window;
        TrackMouseEvent(&tme);
        tracking_control_mouse_ = true;
      }
      if (!control_hovered_) {
        control_hovered_ = true;
        UpdateControlVisibility();
      }
      
      short mx = static_cast<short>(LOWORD(lparam));
      short my = static_cast<short>(HIWORD(lparam));
      HoveredButton new_hover = HoveredButton::None;
      
      if (!locked_) {
        if (my >= 20 && my < 52) {
          if (mx >= 8 && mx < 32) {
            new_hover = HoveredButton::Mode;
          } else if (mx >= 38 && mx < 62) {
            new_hover = HoveredButton::ShowCard;
          } else if (mx >= 68 && mx < 92) {
            new_hover = HoveredButton::Opacity;
          } else if (mx >= 98 && mx < 122) {
            new_hover = HoveredButton::FontSizeDec;
          } else if (mx >= 128 && mx < 152) {
            new_hover = HoveredButton::FontSizeInc;
          } else if (mx >= 158 && mx < 182) {
            new_hover = HoveredButton::Lock;
          }
        }
      } else {
        if (my >= 24 && my < 48) {
          if (mx >= 83 && mx < 107) {
            new_hover = HoveredButton::Lock;
          }
        }
      }
      
      if (new_hover != hovered_button_) {
        hovered_button_ = new_hover;
        PaintControl(window);
      }
      break;
    }
    case WM_MOUSELEAVE: {
      control_hovered_ = false;
      hovered_button_ = HoveredButton::None;
      tracking_control_mouse_ = false;
      UpdateControlVisibility();
      PaintControl(window);
      break;
    }
    case WM_LBUTTONUP: {
      short mx = static_cast<short>(LOWORD(lparam));
      short my = static_cast<short>(HIWORD(lparam));
      bool changed = false;
      
      if (!locked_) {
        if (my >= 20 && my < 52) {
          if (mx >= 8 && mx < 32) {
            double_line_ = !double_line_;
            if (lyrics_window_) PaintLyrics(lyrics_window_);
            changed = true;
          } else if (mx >= 38 && mx < 62) {
            show_card_ = !show_card_;
            if (lyrics_window_) PaintLyrics(lyrics_window_);
            changed = true;
          } else if (mx >= 68 && mx < 92) {
            // Opacity alpha cycle: 255 (100%) -> 204 (80%) -> 153 (60%) -> 102 (40%)
            if (opacity_alpha_ == 255) opacity_alpha_ = 204;
            else if (opacity_alpha_ == 204) opacity_alpha_ = 153;
            else if (opacity_alpha_ == 153) opacity_alpha_ = 102;
            else opacity_alpha_ = 255;
            if (lyrics_window_) PaintLyrics(lyrics_window_);
            changed = true;
          } else if (mx >= 98 && mx < 122) {
            font_scale_ -= 0.1;
            if (font_scale_ < 0.7) font_scale_ = 0.7;
            if (lyrics_window_) {
              RECT rect;
              GetWindowRect(lyrics_window_, &rect);
              int new_width = static_cast<int>(kLyricsWidth * font_scale_);
              int new_height = static_cast<int>(kLyricsHeight * font_scale_);
              int cx = rect.left + (rect.right - rect.left) / 2;
              int cy = rect.top + (rect.bottom - rect.top) / 2;
              SetWindowPos(lyrics_window_, nullptr,
                           cx - new_width / 2, cy - new_height / 2,
                           new_width, new_height,
                           SWP_NOZORDER | SWP_NOACTIVATE);
            }
            changed = true;
          } else if (mx >= 128 && mx < 152) {
            font_scale_ += 0.1;
            if (font_scale_ > 1.6) font_scale_ = 1.6;
            if (lyrics_window_) {
              RECT rect;
              GetWindowRect(lyrics_window_, &rect);
              int new_width = static_cast<int>(kLyricsWidth * font_scale_);
              int new_height = static_cast<int>(kLyricsHeight * font_scale_);
              int cx = rect.left + (rect.right - rect.left) / 2;
              int cy = rect.top + (rect.bottom - rect.top) / 2;
              SetWindowPos(lyrics_window_, nullptr,
                           cx - new_width / 2, cy - new_height / 2,
                           new_width, new_height,
                           SWP_NOZORDER | SWP_NOACTIVATE);
            }
            changed = true;
          } else if (mx >= 158 && mx < 182) {
            SetLocked(!locked_);
            changed = true;
          }
        }
      } else {
        if (my >= 24 && my < 48) {
          if (mx >= 83 && mx < 107) {
            SetLocked(!locked_);
            changed = true;
          }
        }
      }
      
      if (changed && on_setting_changed_) {
        double opacity = static_cast<double>(opacity_alpha_) / 255.0;
        on_setting_changed_(locked_, opacity, double_line_, show_card_, font_scale_);
      }
      
      PaintControl(window);
      return 0;
    }
    case WM_NCHITTEST:
      return HTCLIENT;
    case WM_ERASEBKGND:
      return 1;
  }
  return DefWindowProc(window, message, wparam, lparam);
}
