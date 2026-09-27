/* goga_sdk.c — the reference implementation of THE GOGABOX NATIVE ABI.
 *
 * A tiny, dependency-free localhost JSON client. Build:
 *   Linux    gcc -shared -fPIC -O2 -o libgoga_sdk.so goga_sdk.c
 *   Windows  (CI) x86_64-w64-mingw32-gcc -shared -O2 -o goga_sdk.dll goga_sdk.c -lws2_32
 * Drop the result in GOGAs/libs/ - the box's boot scan lists it.
 */
#include "goga_sdk.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#else
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#endif

#define GOGA_BUF 8192

static int  g_sock = -1;
static char g_client[128] = "goga_client";

static int sock_open(int port) {
#ifdef _WIN32
        WSADATA wsa;
        if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) return -1;
        SOCKET s = socket(AF_INET, SOCK_STREAM, 0);
#else
        int s = socket(AF_INET, SOCK_STREAM, 0);
#endif
        if (s < 0) return -1;
        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_port = htons((unsigned short)port);
        addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
        if (connect(s, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
#ifdef _WIN32
                closesocket(s);
#else
                close(s);
#endif
                return -1;
        }
        return (int)s;
}

static int sock_send(const char *data, size_t len) {
        size_t off = 0;
        while (off < len) {
#ifdef _WIN32
                int n = send(g_sock, data + off, (int)(len - off), 0);
#else
                ssize_t n = send(g_sock, data + off, len - off, 0);
#endif
                if (n <= 0) return -1;
                off += (size_t)n;
        }
        return 0;
}

/* Read until one full line (\n) lands; NUL-terminates inside buf. */
static int sock_line(char *buf, size_t cap) {
        size_t off = 0;
        while (off + 1 < cap) {
                char ch;
#ifdef _WIN32
                int n = recv(g_sock, &ch, 1, 0);
#else
                ssize_t n = recv(g_sock, &ch, 1, 0);
#endif
                if (n <= 0) return -1;
                if (ch == '\n') { buf[off] = 0; return (int)off; }
                buf[off++] = ch;
        }
        return -1;
}

/* one-line JSON string field grab (the protocol stays tiny on purpose) */
static const char *json_str(const char *line, const char *key, char *out, size_t cap) {
        char needle[64];
        snprintf(needle, sizeof(needle), "\"%s\":\"", key);
        const char *p = strstr(line, needle);
        if (!p) return NULL;
        p += strlen(needle);
        size_t i = 0;
        while (*p && *p != '"' && i + 1 < cap) out[i++] = *p++;
        out[i] = 0;
        return out;
}

static int json_bool(const char *line) {
        /* the answer's first "ok" - true unless it reads false */
        const char *p = strstr(line, "\"ok\"");
        if (!p) return 0;
        return strstr(p, "false") == NULL || p != strstr(p, "\"ok\":false");
}

static char g_ans[GOGA_BUF];

static int rpc(const char *fmt, ...) {
        if (g_sock < 0) return -1;
        char req[GOGA_BUF];
        va_list ap;
        va_start(ap, fmt);
        vsnprintf(req, sizeof(req), fmt, ap);
        va_end(ap);
        size_t len = strlen(req);
        req[len] = '\n';
        if (sock_send(req, len + 1) < 0) return -1;
        if (sock_line(g_ans, sizeof(g_ans)) < 0) return -1;
        return 0;
}

int goga_connect(const char *client_id) {
        if (client_id && *client_id)
                snprintf(g_client, sizeof(g_client), "%s", client_id);
        g_sock = sock_open(GOGA_SDK_PORT);
        if (g_sock < 0) return -1;
        if (rpc("{\"op\":\"hello\",\"client\":\"%s\",\"proto\":%d}",
                        g_client, GOGA_SDK_PROTO) < 0) {
                goga_disconnect();
                return -1;
        }
        if (!json_bool(g_ans)) {
                goga_disconnect();
                return -1;
        }
        return 0;
}

void goga_disconnect(void) {
        if (g_sock >= 0) {
#ifdef _WIN32
                closesocket(g_sock);
#else
                close(g_sock);
#endif
                g_sock = -1;
        }
}

int goga_is_connected(void) { return g_sock >= 0; }

int goga_coins_balance(void) {
        if (rpc("{\"op\":\"coins.balance\"}") < 0) return 0;
        const char *p = strstr(g_ans, "\"coins\":");
        return p ? atoi(p + 8) : 0;
}

int goga_coins_spend(int n) {
        if (rpc("{\"op\":\"coins.spend\",\"n\":%d}", n) < 0) return 0;
        return json_bool(g_ans);
}

void goga_coins_earn(int n) {
        if (rpc("{\"op\":\"coins.earn\",\"n\":%d}", n) < 0) return;
}

int goga_save_write(const char *key, const char *data) {
        char esc[GOGA_BUF];
        size_t j = 0;
        for (const char *p = data; *p && j + 6 < sizeof(esc); p++) {
                if (*p == '"' || *p == '\\') esc[j++] = '\\';
                esc[j++] = *p;
        }
        esc[j] = 0;
        if (rpc("{\"op\":\"save.write\",\"key\":\"%s\",\"data\":\"%s\"}", key, esc) < 0)
                return -1;
        return json_bool(g_ans) ? 0 : -1;
}

int goga_save_read(const char *key, char *buf, size_t cap) {
        if (rpc("{\"op\":\"save.read\",\"key\":\"%s\"}", key) < 0) return -1;
        char tmp[GOGA_BUF];
        if (!json_str(g_ans, "data", tmp, sizeof(tmp))) return -1;
        snprintf(buf, cap, "%s", tmp);
        return (int)strlen(buf);
}

void goga_toast(const char *msg) {
        char esc[1024];
        size_t j = 0;
        for (const char *p = msg; *p && j + 6 < sizeof(esc); p++) {
                if (*p == '"' || *p == '\\') esc[j++] = '\\';
                esc[j++] = *p;
        }
        esc[j] = 0;
        rpc("{\"op\":\"toast\",\"msg\":\"%s\"}", esc);
}
