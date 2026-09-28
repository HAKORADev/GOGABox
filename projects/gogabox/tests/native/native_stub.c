/* native_stub.c - THE NATIVE RUNNER'S RIG PROOF (v043 pass 3).
 *
 * A tiny "native game" built at test time: it behaves exactly like a
 * third-party native game that links the box's C ABI (sdk/native/
 * goga_sdk.h) - it connects to the SDK bridge on 127.0.0.1:31442,
 * says hello with its client id, reads the wallet, writes a save into
 * the portable seat (GOGAs/libs/clients/<client>/) and exits. The box's
 * runner watches the process and ends the session when it dies - the
 * same contract a real delisted exe (a Zuma-shaped import) rides.
 *
 * Build: cc -O2 -o nativestub.bin native_stub.c
 * Exit code 0 = the whole bridge roundtrip worked.
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#pragma comment(lib, "ws2_32.lib")
typedef SOCKET sock_t;
#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
typedef int sock_t;
#define INVALID_SOCKET (-1)
#define closesocket(s) close(s)
#endif

static int send_line(sock_t s, const char *buf) {
        size_t n = strlen(buf);
        return send(s, buf, (int)n, 0) == (int)n ? 0 : 1;
}

static int read_line(sock_t s, char *out, int cap) {
        int i = 0;
        char c;
        while (i < cap - 1) {
                if (recv(s, &c, 1, 0) <= 0) return 1;
                if (c == '\n') break;
                out[i++] = c;
        }
        out[i] = 0;
        return 0;
}

int main(void) {
#ifdef _WIN32
        WSADATA wsa; WSAStartup(MAKEWORD(2,2), &wsa);
#endif
        sock_t s = socket(AF_INET, SOCK_STREAM, 0);
        if (s == INVALID_SOCKET) return 2;
        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_port = htons(31442);
        addr.sin_addr.s_addr = inet_addr("127.0.0.1");
        if (connect(s, (struct sockaddr *)&addr, sizeof(addr)) != 0) {
                closesocket(s);
                return 3;
        }
        char line[512];
        if (send_line(s, "{\"op\":\"hello\",\"client\":\"nativestub\",\"proto\":1}\n")) return 4;
        if (read_line(s, line, sizeof line)) return 5;
        if (!strstr(line, "\"ok\":true")) return 6;
        if (send_line(s, "{\"op\":\"coins.balance\"}\n")) return 7;
        if (read_line(s, line, sizeof line)) return 8;
        if (!strstr(line, "\"coins\"")) return 9;
        if (send_line(s, "{\"op\":\"save.write\",\"key\":\"save\",\"data\":\"native-stub-was-here\"}\n")) return 10;
        if (read_line(s, line, sizeof line)) return 11;
        if (!strstr(line, "\"ok\":true")) return 12;
        if (send_line(s, "{\"op\":\"toast\",\"msg\":\"the native stub says hi\"}\n")) return 13;
        if (read_line(s, line, sizeof line)) return 14;
        closesocket(s);
        return 0;
}
