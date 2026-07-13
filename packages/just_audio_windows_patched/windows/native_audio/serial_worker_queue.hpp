#pragma once
#include <queue>
#include <mutex>
#include <thread>
#include <condition_variable>
#include <functional>

class SerialWorkerQueue {
public:
    SerialWorkerQueue() {
        worker_thread_ = std::thread([this]() {
            Run();
        });
    }

    ~SerialWorkerQueue() {
        Stop();
    }

    void Post(std::function<void()> task) {
        std::scoped_lock lock(mutex_);
        if (stop_) return;
        tasks_.push(task);
        cv_.notify_one();
    }

    void Stop() {
        {
            std::scoped_lock lock(mutex_);
            if (stop_) return;
            stop_ = true;
            cv_.notify_all();
        }
        if (worker_thread_.joinable()) {
            worker_thread_.join();
        }
        // clear remaining tasks
        std::queue<std::function<void()>> empty;
        std::swap(tasks_, empty);
    }

private:
    void Run() {
        while (true) {
            std::function<void()> task;
            {
                std::unique_lock<std::mutex> lock(mutex_);
                cv_.wait(lock, [this]() {
                    return stop_ || !tasks_.empty();
                });
                if (stop_ && tasks_.empty()) {
                    return;
                }
                if (!tasks_.empty()) {
                    task = std::move(tasks_.front());
                    tasks_.pop();
                }
            }
            if (task) {
                try {
                    task();
                } catch (...) {
                    // Task threw, ignore or log
                }
            }
        }
    }

    std::queue<std::function<void()>> tasks_;
    std::mutex mutex_;
    std::condition_variable cv_;
    std::thread worker_thread_;
    bool stop_ = false;
};
