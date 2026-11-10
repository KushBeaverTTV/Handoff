// cornerstone-qwen-server: keeps one speech model loaded and transcribes
// WAV files on request, so each dictation skips the model load.
//
//   cornerstone-qwen-server MODEL.gguf [PORT]
//
// Listens on 127.0.0.1 only. One request per connection, one line:
//     <path to 16 kHz mono WAV> TAB <context/term list, may be empty> NEWLINE
// Reply: the transcript and a newline, or a line starting with "ERR: ".
// Built on the transcribe.cpp C API (https://github.com/handy-computer/transcribe.cpp).
#include "transcribe.h"

#define DR_WAV_IMPLEMENTATION
#include "dr_wav.h"

#include <arpa/inet.h>
#include <netinet/in.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <unistd.h>

static float * load_wav_mono(const char * path, int * n, unsigned int * rate) {
    unsigned int ch = 0;
    drwav_uint64 frames = 0;
    float * buf = drwav_open_file_and_read_pcm_frames_f32(path, &ch, rate, &frames, NULL);
    if (buf == NULL) return NULL;
    if (ch > 1) {
        for (drwav_uint64 i = 0; i < frames; ++i) {
            float acc = 0.0f;
            for (unsigned int c = 0; c < ch; ++c) acc += buf[i * ch + c];
            buf[i] = acc / (float) ch;
        }
    }
    *n = (int) frames;
    return buf;
}

static void reply(int fd, const char * a, const char * b) {
    (void) !write(fd, a, strlen(a));
    if (b) (void) !write(fd, b, strlen(b));
    (void) !write(fd, "\n", 1);
}

int main(int argc, char ** argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: %s model.gguf [port]\n", argv[0]);
        return 2;
    }
    int port = argc > 2 ? atoi(argv[2]) : 29335;
    signal(SIGPIPE, SIG_IGN);

    struct transcribe_session * session = NULL;
    transcribe_status st = transcribe_open(argv[1], NULL, NULL, &session);
    if (st != TRANSCRIBE_OK) {
        fprintf(stderr, "model load failed: %s\n", transcribe_status_string(st));
        return 1;
    }
    // Warm up so the first real dictation is not the slow one.
    {
        static float silence[16000 * 2];
        struct transcribe_run_params rp;
        transcribe_run_params_init(&rp);
        rp.language = "en";
        (void) transcribe_run(session, silence, 16000 * 2, &rp);
    }

    int srv = socket(AF_INET, SOCK_STREAM, 0);
    int one = 1;
    setsockopt(srv, SOL_SOCKET, SO_REUSEADDR, &one, sizeof one);
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof addr);
    addr.sin_family = AF_INET;
    addr.sin_port = htons((unsigned short) port);
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    if (bind(srv, (struct sockaddr *) &addr, sizeof addr) != 0 || listen(srv, 8) != 0) {
        perror("bind/listen");
        return 1;
    }
    fprintf(stderr, "ready on 127.0.0.1:%d\n", port);

    for (;;) {
        int fd = accept(srv, NULL, NULL);
        if (fd < 0) continue;
        struct timeval tv = {5, 0};
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof tv);

        static char req[16384];
        size_t len = 0;
        while (len < sizeof req - 1) {
            ssize_t r = read(fd, req + len, sizeof req - 1 - len);
            if (r <= 0) break;
            len += (size_t) r;
            if (memchr(req, '\n', len)) break;
        }
        req[len] = '\0';
        char * nl = strchr(req, '\n');
        if (nl == NULL) { reply(fd, "ERR: ", "no request line"); close(fd); continue; }
        *nl = '\0';
        char * prompt = strchr(req, '\t');
        if (prompt) { *prompt = '\0'; ++prompt; }

        int n = 0;
        unsigned int rate = 0;
        float * pcm = load_wav_mono(req, &n, &rate);
        if (pcm == NULL) { reply(fd, "ERR: ", "cannot read WAV"); close(fd); continue; }
        if (rate != 16000) { reply(fd, "ERR: ", "audio must be 16 kHz"); drwav_free(pcm, NULL); close(fd); continue; }

        struct transcribe_run_params rp;
        transcribe_run_params_init(&rp);
        rp.language = "en";
        if (prompt && prompt[0]) rp.prompt = prompt;
        st = transcribe_run(session, pcm, n, &rp);
        if (st != TRANSCRIBE_OK) reply(fd, "ERR: ", transcribe_status_string(st));
        else {
            const char * text = transcribe_full_text(session);
            reply(fd, text ? text : "", NULL);
        }
        drwav_free(pcm, NULL);
        close(fd);
    }
}
