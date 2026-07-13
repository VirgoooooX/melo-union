#pragma once

#include <memory>
#include <string>
#include <mutex>
#include "All.h"
#include "MACLib.h"

class ApeDecodeSession final : public std::enable_shared_from_this<ApeDecodeSession> {
public:
    static std::shared_ptr<ApeDecodeSession> Open(const std::wstring& path);
    ~ApeDecodeSession();

    uint32_t SampleRate() const { return sample_rate_; }
    uint32_t ChannelCount() const { return channel_count_; }
    uint32_t BitsPerSample() const { return bits_per_sample_; }
    uint32_t BytesPerFrame() const { return bytes_per_frame_; }
    int64_t TotalBlocks() const { return total_blocks_; }
    int64_t CurrentBlock() const { return current_block_; }

    // Reads blocks of audio. Returns 0 (ERROR_SUCCESS) on success or an error code.
    int ReadBlocks(unsigned char* buffer, uint32_t requested_blocks, uint32_t& blocks_retrieved);
    void SeekToBlock(int64_t block);
    void Close() noexcept;

private:
    ApeDecodeSession() = default;
    void EnsureOpen() const;

    APE::IAPEDecompress* decoder_ = nullptr;

    uint32_t sample_rate_ = 0;
    uint32_t channel_count_ = 0;
    uint32_t bits_per_sample_ = 0;
    uint32_t bytes_per_frame_ = 0;

    int64_t total_blocks_ = 0;
    int64_t current_block_ = 0;

    mutable std::mutex decoder_mutex_;
    bool closed_ = false;
};
