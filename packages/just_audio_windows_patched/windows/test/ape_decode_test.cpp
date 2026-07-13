#include <gtest/gtest.h>
#include <string>
#include <vector>
#include <iostream>
#include "ape_decode_session.hpp"
#include "ape_error.hpp"

// We can pass the path to a test APE file using an environment variable MELO_TEST_APE_PATH
std::wstring GetTestApePath() {
    wchar_t buf[32768];
    DWORD len = GetEnvironmentVariableW(L"MELO_TEST_APE_PATH", buf, 32768);
    if (len > 0) {
        return std::wstring(buf, len);
    }
    return L"";
}

TEST(ApeDecodeSessionTest, OpenAndReadMetadata) {
    std::wstring path = GetTestApePath();
    if (path.empty()) {
        std::cout << "[ SKIPPED ] MELO_TEST_APE_PATH environment variable is not set. Skipping test." << std::endl;
        return;
    }

    try {
        auto session = ApeDecodeSession::Open(path);
        ASSERT_NE(session, nullptr);
        
        std::cout << "APE Metadata: " << std::endl;
        std::cout << "  Sample Rate: " << session->SampleRate() << " Hz" << std::endl;
        std::cout << "  Channels: " << session->ChannelCount() << std::endl;
        std::cout << "  Bit Depth: " << session->BitsPerSample() << " bits" << std::endl;
        std::cout << "  Bytes per frame: " << session->BytesPerFrame() << std::endl;
        std::cout << "  Total blocks: " << session->TotalBlocks() << std::endl;

        EXPECT_GT(session->SampleRate(), 0u);
        EXPECT_LE(session->SampleRate(), 768000u);
        EXPECT_GT(session->ChannelCount(), 0u);
        EXPECT_LE(session->ChannelCount(), 2u);
        EXPECT_TRUE(session->BitsPerSample() == 8 || session->BitsPerSample() == 16 ||
                    session->BitsPerSample() == 24 || session->BitsPerSample() == 32);
        EXPECT_GT(session->TotalBlocks(), 0);

        session->Close();
    } catch (const ApeDecodeException& e) {
        FAIL() << "ApeDecodeException: " << e.what();
    }
}

TEST(ApeDecodeSessionTest, DecodePCMAndVerify) {
    std::wstring path = GetTestApePath();
    if (path.empty()) {
        return;
    }

    try {
        auto session = ApeDecodeSession::Open(path);
        ASSERT_NE(session, nullptr);

        uint32_t bytesPerFrame = session->BytesPerFrame();
        uint32_t requestBlocks = 4096;
        std::vector<unsigned char> buffer(requestBlocks * bytesPerFrame);

        uint32_t blocksRetrieved = 0;
        int result = session->ReadBlocks(buffer.data(), requestBlocks, blocksRetrieved);

        EXPECT_EQ(result, 0); // ERROR_SUCCESS
        EXPECT_GT(blocksRetrieved, 0u);
        EXPECT_LE(blocksRetrieved, requestBlocks);

        std::cout << "Successfully decoded " << blocksRetrieved << " blocks (" 
                  << blocksRetrieved * bytesPerFrame << " bytes) of PCM." << std::endl;

        session->Close();
    } catch (const ApeDecodeException& e) {
        FAIL() << "ApeDecodeException: " << e.what();
    }
}

TEST(ApeDecodeSessionTest, SeekAndRead) {
    std::wstring path = GetTestApePath();
    if (path.empty()) {
        return;
    }

    try {
        auto session = ApeDecodeSession::Open(path);
        ASSERT_NE(session, nullptr);

        int64_t totalBlocks = session->TotalBlocks();
        if (totalBlocks > 8000) {
            int64_t targetBlock = totalBlocks / 2;
            session->SeekToBlock(targetBlock);
            EXPECT_EQ(session->CurrentBlock(), targetBlock);

            uint32_t bytesPerFrame = session->BytesPerFrame();
            uint32_t requestBlocks = 100;
            std::vector<unsigned char> buffer(requestBlocks * bytesPerFrame);
            uint32_t blocksRetrieved = 0;
            int result = session->ReadBlocks(buffer.data(), requestBlocks, blocksRetrieved);

            EXPECT_EQ(result, 0);
            EXPECT_GT(blocksRetrieved, 0u);
            EXPECT_EQ(session->CurrentBlock(), targetBlock + blocksRetrieved);
        }

        session->Close();
    } catch (const ApeDecodeException& e) {
        FAIL() << "ApeDecodeException: " << e.what();
    }
}
