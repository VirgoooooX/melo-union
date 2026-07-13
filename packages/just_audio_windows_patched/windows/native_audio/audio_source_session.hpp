#pragma once

class AudioSourceSession {
public:
    virtual ~AudioSourceSession() = default;
    virtual void Close() noexcept = 0;
};
