#include "ape_decode_session.hpp"
#include "ape_error.hpp"
#include "All.h"
#include <stdexcept>

static std::string GetApeErrorMessage(int errorCode) {
    switch (errorCode) {
        case 1000: return "I/O read error";
        case 1001: return "I/O write error";
        case 1002: return "Invalid input file";
        case 1003: return "Invalid output file";
        case 1004: return "Input file too large";
        case 1005: return "Unsupported bit depth";
        case 1006: return "Unsupported sample rate";
        case 1007: return "Unsupported channel count";
        case 1008: return "Input file too small";
        case 1009: return "Invalid checksum (file corrupt)";
        case 1010: return "Error decompressing frame";
        case 1011: return "Error initializing UnMAC";
        case 1012: return "Invalid function parameter";
        case 1013: return "Unsupported file type";
        case 1014: return "Unsupported file version";
        case 1015: return "File is in use";
        case 1016: return "UAC permission error";
        case 2000: return "Insufficient memory";
        default: return "Unknown error (" + std::to_string(errorCode) + ")";
    }
}

std::shared_ptr<ApeDecodeSession> ApeDecodeSession::Open(const std::wstring& path) {
    int errorCode = 0;
    APE::IAPEDecompress* decompressor = CreateIAPEDecompress(path.c_str(), &errorCode, true, true, false);
    if (!decompressor) {
        throw ApeDecodeException("Failed to open APE file: " + GetApeErrorMessage(errorCode));
    }

    auto session = std::shared_ptr<ApeDecodeSession>(new ApeDecodeSession());
    session->decoder_ = decompressor;
    
    // Read parameters
    session->sample_rate_ = static_cast<uint32_t>(decompressor->GetInfo(APE::IAPEInfo::APE_INFO_SAMPLE_RATE));
    session->channel_count_ = static_cast<uint32_t>(decompressor->GetInfo(APE::IAPEInfo::APE_INFO_CHANNELS));
    session->bits_per_sample_ = static_cast<uint32_t>(decompressor->GetInfo(APE::IAPEInfo::APE_INFO_BITS_PER_SAMPLE));
    session->bytes_per_frame_ = static_cast<uint32_t>(decompressor->GetInfo(APE::IAPEInfo::APE_INFO_BLOCK_ALIGN));
    session->total_blocks_ = decompressor->GetInfo(APE::IAPEInfo::APE_DECOMPRESS_TOTAL_BLOCKS);
    session->current_block_ = decompressor->GetInfo(APE::IAPEInfo::APE_DECOMPRESS_CURRENT_BLOCK);

    // Boundary checks
    if (session->sample_rate_ == 0 || session->sample_rate_ > 768000) {
        delete decompressor;
        throw ApeDecodeException("Unsupported sample rate: " + std::to_string(session->sample_rate_));
    }
    if (session->channel_count_ == 0 || session->channel_count_ > 2) {
        delete decompressor;
        throw ApeDecodeException("Unsupported channel count: " + std::to_string(session->channel_count_));
    }
    if (session->bits_per_sample_ != 8 && session->bits_per_sample_ != 16 &&
        session->bits_per_sample_ != 24 && session->bits_per_sample_ != 32) {
        delete decompressor;
        throw ApeDecodeException("Unsupported bit depth: " + std::to_string(session->bits_per_sample_));
    }
    if (session->total_blocks_ <= 0) {
        delete decompressor;
        throw ApeDecodeException("Invalid audio block count: " + std::to_string(session->total_blocks_));
    }

    return session;
}

ApeDecodeSession::~ApeDecodeSession() {
    Close();
}

void ApeDecodeSession::EnsureOpen() const {
    if (closed_ || !decoder_) {
        throw ApeDecodeException("Decoder session is closed");
    }
}

int ApeDecodeSession::ReadBlocks(unsigned char* buffer, uint32_t requested_blocks, uint32_t& blocks_retrieved) {
    std::scoped_lock lock(decoder_mutex_);
    EnsureOpen();

    int64_t retrieved = 0;
    int result = decoder_->GetData(buffer, static_cast<int64_t>(requested_blocks), &retrieved);
    blocks_retrieved = static_cast<uint32_t>(retrieved);
    
    current_block_ = decoder_->GetInfo(APE::IAPEInfo::APE_DECOMPRESS_CURRENT_BLOCK);
    return result;
}

void ApeDecodeSession::SeekToBlock(int64_t block) {
    std::scoped_lock lock(decoder_mutex_);
    EnsureOpen();

    if (block < 0) block = 0;
    if (block > total_blocks_) block = total_blocks_;

    int result = decoder_->Seek(block);
    if (result != 0) {
        throw ApeDecodeException("Failed to seek to block " + std::to_string(block) + ": " + GetApeErrorMessage(result));
    }
    current_block_ = decoder_->GetInfo(APE::IAPEInfo::APE_DECOMPRESS_CURRENT_BLOCK);
}

void ApeDecodeSession::Close() noexcept {
    std::scoped_lock lock(decoder_mutex_);
    if (!closed_) {
        closed_ = true;
        if (decoder_) {
            delete decoder_;
            decoder_ = nullptr;
        }
    }
}
