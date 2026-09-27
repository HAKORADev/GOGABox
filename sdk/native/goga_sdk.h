/* goga_sdk.h — THE GOGABOX NATIVE ABI (v043, protocol 1)
 *
 * The low-level, OS-specific door a NATIVE game links against to live
 * inside the running GOGABox - the Steam model: the box runs, the game
 * requires it. Pure C, zero engine types, one transport: a localhost TCP
 * wire to the box's SDK BRIDGE (port 31442) speaking newline-delimited
 * JSON - the exact vocabulary in goga_core.gd. A native game may speak
 * that wire directly over its own sockets, or link a tiny wrapper built
 * on this header (goga_sdk.dll / libgoga_sdk.so, dropped in GOGAs/libs/).
 *
 * THE LAWS THAT HOLD AT THIS LAYER:
 *   - THE PORTABLE SAVE LAW: saves land under GOGAs/libs/clients/<id>/
 *     inside the GOGAs tree - never app-data bloat.
 *   - THE ONE WALLET: GOGACoins are the box's; a native game never keeps
 *     its own currency ledger.
 *   - THE HONEST DOOR: every call answers 0/NULL/negative on "no box
 *     running"; a native game decides what that means for itself.
 *
 * Build shape (per platform):
 *   Windows  goga_sdk.dll   (x86_64 + x86, links ws2_32)
 *   Android  libgoga_sdk.so (arm64-v8a + armeabi-v7a)
 * The compiled bridges land in GOGAs/libs/ and the box's boot scan lists
 * them; their absence never breaks the box (the honest libs law).
 */

#ifndef GOGA_SDK_H
#define GOGA_SDK_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define GOGA_SDK_PORT    31442
#define GOGA_SDK_PROTO   1

/* Connect to the running box and perform the hello handshake.
 * Returns 0 on success; negative on any failure (no box, refused).
 * `client_id` names this game on the wire (its save folder + logs). */
int  goga_connect(const char *client_id);

/* Tear the wire down. Safe to call twice. */
void goga_disconnect(void);

/* 1 while the wire is alive and the handshake holds. */
int  goga_is_connected(void);

/* ---- THE ONE WALLET (GOGACoins) ----------------------------------- */

/* The player's balance; 0 when disconnected (the honest door). */
int  goga_coins_balance(void);

/* Try to spend n coins; 1 when it landed, 0 when refused (dry wallet
 * or disconnected). The box is the ledger - never keep your own. */
int  goga_coins_spend(int n);

/* Reward the player n coins. */
void goga_coins_earn(int n);

/* ---- THE PORTABLE SAVE LAW ---------------------------------------- */

/* Write one save slot. `data` is the game's own bytes-as-string (JSON
 * recommended, anything allowed). Returns 0 on success. */
int  goga_save_write(const char *key, const char *data);

/* Read one save slot into `buf` (capacity `cap`, NUL-terminated).
 * Returns the length written, or negative when unset / disconnected. */
int  goga_save_read(const char *key, char *buf, size_t cap);

/* ---- THE BOX'S VOICE ----------------------------------------------- */

/* Push a toast into the box's top-level note layer (shows anywhere). */
void goga_toast(const char *msg);

/* ---- PROTOCOL (for direct implementations) -------------------------
 *
 *   connect 127.0.0.1:31442
 *   -> {"op":"hello","client":"<id>","proto":1}\n
 *   <- {"ok":true,"box":"<version>","proto":1}\n
 *   -> {"op":"coins.balance"}\n        <- {"ok":true,"coins":<n>}\n
 *   -> {"op":"coins.spend","n":<n>}\n  <- {"ok":true|false}\n
 *   -> {"op":"coins.earn","n":<n>}\n   <- {"ok":true}\n
 *   -> {"op":"save.write","key":"<k>","data":"<s>"}\n  <- {"ok":true}\n
 *   -> {"op":"save.read","key":"<k>"}\n <- {"ok":true,"data":"<s>"}\n
 *   -> {"op":"toast","msg":"<s>"}\n    <- {"ok":true}\n
 *
 * One request line, one answer line. UTF-8 everywhere. */

#ifdef __cplusplus
}
#endif

#endif /* GOGA_SDK_H */
