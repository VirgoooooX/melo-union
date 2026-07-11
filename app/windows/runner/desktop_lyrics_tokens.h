#ifndef RUNNER_DESKTOP_LYRICS_TOKENS_H_
#define RUNNER_DESKTOP_LYRICS_TOKENS_H_

#include <gdiplus.h>

// Native mirror of lib/src/design/melo_tokens.dart. Keep the values aligned
// with MeloColors, MeloSpacing, MeloRadii and MeloShadows.
namespace melo_tokens {
inline const Gdiplus::Color kSurface(248, 255, 255, 255);
inline const Gdiplus::Color kSurfaceMuted(246, 247, 249, 252);
inline const Gdiplus::Color kSurfaceSelected(255, 234, 248, 246);
inline const Gdiplus::Color kBorder(255, 231, 236, 241);
inline const Gdiplus::Color kPrimary700(255, 8, 124, 118);
inline const Gdiplus::Color kPrimary100(255, 207, 243, 238);
inline const Gdiplus::Color kPrimary50(255, 234, 248, 246);
inline const Gdiplus::Color kTextPrimary(255, 28, 39, 54);
inline const Gdiplus::Color kTextSecondary(255, 102, 112, 133);
inline const Gdiplus::Color kFloatingShadow(18, 28, 39, 54);
inline const Gdiplus::Color kControlShadow(12, 8, 124, 118);

constexpr float kSpacingXs = 8.0f;
constexpr float kSpacingSm = 12.0f;
constexpr float kSpacingMd = 16.0f;
constexpr float kSpacingXl = 24.0f;
constexpr float kRadiusSm = 8.0f;
constexpr float kRadiusLg = 16.0f;
}  // namespace melo_tokens

#endif  // RUNNER_DESKTOP_LYRICS_TOKENS_H_
