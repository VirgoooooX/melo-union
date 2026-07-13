#pragma once

#include <memory>
#include <string>
#include <atomic>
#include <winrt/Windows.Media.Core.h>
#include <winrt/Windows.Media.Playback.h>
#include <winrt/Windows.Storage.Streams.h>
#include "audio_source_session.hpp"
#include "ape_decode_session.hpp"
#include "serial_worker_queue.hpp"

class ApeMediaSource final
    : public AudioSourceSession,
      public std::enable_shared_from_this<ApeMediaSource> {
public:
    static std::shared_ptr<ApeMediaSource> Create(const std::wstring& path);
    ~ApeMediaSource();

    winrt::Windows::Media::Core::MediaSource MediaSource() const { return media_source_; }
    void Close() noexcept override;

private:
    ApeMediaSource() = default;

    void Initialize(const std::wstring& path);
    void OnStarting(
        const winrt::Windows::Media::Core::MediaStreamSource& sender,
        const winrt::Windows::Media::Core::MediaStreamSourceStartingEventArgs& args);
    void OnSampleRequested(
        const winrt::Windows::Media::Core::MediaStreamSource& sender,
        const winrt::Windows::Media::Core::MediaStreamSourceSampleRequestedEventArgs& args);
    void FulfillSampleRequest(
        const winrt::Windows::Media::Core::MediaStreamSourceSampleRequest& request,
        uint64_t task_generation);

    winrt::Windows::Foundation::TimeSpan BlocksToTimeSpan(int64_t blocks) const;
    int64_t TimeSpanToBlock(winrt::Windows::Foundation::TimeSpan time) const;
    void NotifyDecodeFailure(int errorCode);

    std::wstring path_;
    std::shared_ptr<ApeDecodeSession> decoder_;

    winrt::Windows::Media::Core::MediaStreamSource media_stream_source_{nullptr};
    winrt::Windows::Media::Core::MediaSource media_source_{nullptr};

    SerialWorkerQueue decode_queue_;
    std::atomic<uint64_t> generation_{0};
    bool next_sample_discontinuous_ = false;

    winrt::event_token starting_token_;
    winrt::event_token sample_requested_token_;
    bool closed_ = false;
    std::mutex session_mutex_;
};
