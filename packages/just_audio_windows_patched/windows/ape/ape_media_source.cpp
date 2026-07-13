#include "ape_media_source.hpp"
#include "ape_error.hpp"
#include <robuffer.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Media.Core.h>
#include <winrt/Windows.Media.MediaProperties.h>
#include <winrt/Windows.Storage.Streams.h>
#include <chrono>

using namespace winrt::Windows::Media::Core;
using namespace winrt::Windows::Media::MediaProperties;
using namespace winrt::Windows::Storage::Streams;
using namespace winrt::Windows::Foundation;

std::shared_ptr<ApeMediaSource> ApeMediaSource::Create(const std::wstring& path) {
    auto self = std::shared_ptr<ApeMediaSource>(new ApeMediaSource());
    self->Initialize(path);
    return self;
}

ApeMediaSource::~ApeMediaSource() {
    Close();
}

void ApeMediaSource::Initialize(const std::wstring& path) {
    path_ = path;
    decoder_ = ApeDecodeSession::Open(path);

    auto pcmProperties = AudioEncodingProperties::CreatePcm(
        decoder_->SampleRate(),
        decoder_->ChannelCount(),
        decoder_->BitsPerSample()
    );

    AudioStreamDescriptor descriptor(pcmProperties);

    media_stream_source_ = MediaStreamSource(descriptor);
    media_stream_source_.CanSeek(true);
    media_stream_source_.Duration(BlocksToTimeSpan(decoder_->TotalBlocks()));
    media_stream_source_.BufferTime(std::chrono::milliseconds(200));

    starting_token_ = media_stream_source_.Starting({ this, &ApeMediaSource::OnStarting });
    sample_requested_token_ = media_stream_source_.SampleRequested({ this, &ApeMediaSource::OnSampleRequested });

    media_source_ = MediaSource::CreateFromMediaStreamSource(media_stream_source_);
}

void ApeMediaSource::Close() noexcept {
    std::lock_guard<std::mutex> lock(session_mutex_);
    if (!closed_) {
        closed_ = true;
        generation_.fetch_add(1);

        if (media_stream_source_) {
            media_stream_source_.Starting(starting_token_);
            media_stream_source_.SampleRequested(sample_requested_token_);
            media_stream_source_ = nullptr;
        }

        media_source_ = nullptr;
        decode_queue_.Stop();

        if (decoder_) {
            decoder_->Close();
            decoder_ = nullptr;
        }
    }
}

void ApeMediaSource::OnStarting(
    const MediaStreamSource&,
    const MediaStreamSourceStartingEventArgs& args) {
    auto request = args.Request();
    auto deferral = request.GetDeferral();
    auto weak = std::weak_ptr<ApeMediaSource>(this->shared_from_this());

    decode_queue_.Post([weak, request, deferral]() mutable {
        try {
            auto self = weak.lock();
            if (!self) {
                deferral.Complete();
                return;
            }

            std::lock_guard<std::mutex> lock(self->session_mutex_);
            if (self->closed_) {
                deferral.Complete();
                return;
            }

            auto requestedPosition = request.StartPosition();
            self->generation_.fetch_add(1);

            if (requestedPosition) {
                const auto targetBlock = self->TimeSpanToBlock(requestedPosition.Value());
                self->decoder_->SeekToBlock(targetBlock);
                self->next_sample_discontinuous_ = true;
                request.SetActualStartPosition(self->BlocksToTimeSpan(targetBlock));
            } else {
                request.SetActualStartPosition(self->BlocksToTimeSpan(self->decoder_->CurrentBlock()));
            }
        } catch (const std::exception&) {
            // Log or ignore
        } catch (...) {
            // Ignore
        }
        deferral.Complete();
    });
}

void ApeMediaSource::OnSampleRequested(
    const MediaStreamSource&,
    const MediaStreamSourceSampleRequestedEventArgs& args) {
    auto request = args.Request();
    auto deferral = request.GetDeferral();
    auto weak = std::weak_ptr<ApeMediaSource>(this->shared_from_this());
    const auto taskGeneration = generation_.load();

    decode_queue_.Post([weak, request, deferral, taskGeneration]() mutable {
        try {
            auto self = weak.lock();
            if (self) {
                self->FulfillSampleRequest(request, taskGeneration);
            } else {
                request.Sample(nullptr);
            }
        } catch (...) {
            request.Sample(nullptr);
        }
        deferral.Complete();
    });
}

void ApeMediaSource::FulfillSampleRequest(
    const MediaStreamSourceSampleRequest& request,
    uint64_t taskGeneration) {
    std::lock_guard<std::mutex> lock(session_mutex_);
    if (closed_ || generation_.load() != taskGeneration) {
        return;
    }

    int64_t currentBlock = decoder_->CurrentBlock();
    int64_t totalBlocks = decoder_->TotalBlocks();

    if (currentBlock >= totalBlocks) {
        request.Sample(nullptr);
        return;
    }

    uint32_t requestBlocks = 4096;
    if (currentBlock + requestBlocks > totalBlocks) {
        requestBlocks = static_cast<uint32_t>(totalBlocks - currentBlock);
    }

    uint32_t bytesPerFrame = decoder_->BytesPerFrame();
    uint32_t bytesRequired = requestBlocks * bytesPerFrame;

    Buffer buffer(bytesRequired);
    auto byteAccess = buffer.as<::Windows::Storage::Streams::IBufferByteAccess>();
    byte* destination = nullptr;
    winrt::check_hresult(byteAccess->Buffer(&destination));

    uint32_t blocksRetrieved = 0;
    int result = decoder_->ReadBlocks(destination, requestBlocks, blocksRetrieved);

    if (result != 0) {
        NotifyDecodeFailure(result);
        request.Sample(nullptr);
        return;
    }

    buffer.Length(blocksRetrieved * bytesPerFrame);

    auto sample = MediaStreamSample::CreateFromBuffer(
        buffer,
        BlocksToTimeSpan(currentBlock)
    );

    sample.Duration(BlocksToTimeSpan(blocksRetrieved));
    sample.Discontinuous(next_sample_discontinuous_);
    next_sample_discontinuous_ = false;

    request.Sample(sample);
}

TimeSpan ApeMediaSource::BlocksToTimeSpan(int64_t blocks) const {
    constexpr int64_t kTicksPerSecond = 10000000;
    int64_t ticks = blocks * kTicksPerSecond / decoder_->SampleRate();
    return TimeSpan{ ticks };
}

int64_t ApeMediaSource::TimeSpanToBlock(TimeSpan time) const {
    constexpr int64_t kTicksPerSecond = 10000000;
    return time.count() * decoder_->SampleRate() / kTicksPerSecond;
}

void ApeMediaSource::NotifyDecodeFailure(int errorCode) {
    auto status = MediaStreamSourceErrorStatus::Other;
    if (errorCode == 2000) {
        status = MediaStreamSourceErrorStatus::OutOfMemory;
    }
    if (media_stream_source_) {
        media_stream_source_.NotifyError(status);
    }
}
