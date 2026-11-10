#!/usr/bin/env bash
# Builds transcribe.cpp (runtime for the Parakeet, Qwen3-ASR and Cohere speech
# models) with GPU support, using the same toolchain the Whisper build used.
# Source: https://github.com/handy-computer/transcribe.cpp
set -e
D=/mnt/storage/files/dictation
cd "$D/transcribe.cpp"
source "$D/toolchain/1.4.363.1/setup-env.sh"
export PATH="$D/toolchain/cmake/bin:$PATH"
cmake -B build -DTRANSCRIBE_VULKAN=ON -DCMAKE_BUILD_TYPE=Release -DTRANSCRIBE_BUILD_TESTS=OFF
cmake --build build -j 12 --target transcribe-cli
echo BUILD_OK
