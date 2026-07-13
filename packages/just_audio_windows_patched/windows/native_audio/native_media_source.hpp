#pragma once
#include <memory>
#include "audio_source_session.hpp"
#include <winrt/Windows.Media.Core.h>
#include <winrt/Windows.Media.Playback.h>

struct NativeMediaSource {
    winrt::Windows::Media::Core::MediaSource media_source{nullptr};
    std::shared_ptr<AudioSourceSession> session;
};

struct NativePlaybackItem {
    winrt::Windows::Media::Playback::MediaPlaybackItem item{nullptr};
    std::shared_ptr<AudioSourceSession> session;
};
