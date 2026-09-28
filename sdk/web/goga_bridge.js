/**
 * goga_bridge.js - the SDK bridge for GOGABox web games (v043 pass 3).
 *
 * THE ONE API rule: web games speak the SAME vocabulary every other
 * transport speaks (embedded doors / the native C ABI / the standalone
 * TCP bridge) - this file carries it over the box's WebSocket door
 * (ws://127.0.0.1:31443). Loopback only; the box is the server.
 *
 * Usage (include from the game's index.html):
 *   <script src="goga_bridge.js"></script>
 *
 *   await GOGA.hello()          // handshake (auto-runs on load, but the
 *                               //   game can await it explicitly)
 *   GOGA.coins()        -> n   // THE ONE WALLET (a Promise of the balance)
 *   await GOGA.spend(10) -> bool
 *   await GOGA.earn(5)
 *   await GOGA.saveWrite("save", "any string")   // THE PORTABLE SAVE LAW
 *   const txt = await GOGA.saveRead("save")      //   lands in the GOGAs tree
 *   await GOGA.toast("hello from the game")
 *   GOGA.connected()             // true when the box answered hello
 *
 * Every call resolves (or rejects when the box is not there) - the honest
 * door: a web game run outside the box gets the refusal, never a hang.
 */
(function (global) {
        "use strict";

        var WS_PORT = 31443;
        var ws = null;
        var seq = 0;
        var pending = {};      // id -> {resolve, reject}
        var ready = null;      // the hello promise
        var connected = false;

        function connect() {
                if (ws && (ws.readyState === 0 || ws.readyState === 1)) {
                        return;
                }
                try {
                        ws = new WebSocket("ws://127.0.0.1:" + WS_PORT);
                } catch (e) {
                        connected = false;
                        return;
                }
                ws.onopen = function () {
                        send({ op: "hello", client: clientName(), proto: 1 }, true);
                };
                ws.onmessage = function (ev) {
                        var msg;
                        try { msg = JSON.parse(ev.data); } catch (e) { return; }
                        if (msg.reply_to !== undefined && pending[msg.reply_to]) {
                                var p = pending[msg.reply_to];
                                delete pending[msg.reply_to];
                                if (msg.ok) { p.resolve(msg); }
                                else { p.reject(new Error(msg.err || "refused")); }
                        } else if (msg.op === "hello" || msg.proto !== undefined) {
                                connected = !!msg.ok;
                                if (ready && msg.ok !== undefined) {
                                        var r = ready; ready = null;
                                        if (msg.ok) { r.resolve(msg); }
                                        else { r.reject(new Error("the box refused the hello")); }
                                }
                        }
                };
                ws.onclose = function () { connected = false; };
                ws.onerror = function () { connected = false; };
        }

        function clientName() {
                // the package id rides the URL: /<pkg root name>/game/web/...
                var parts = location.pathname.split("/").filter(Boolean);
                return parts.length > 0 ? parts[0] : "webgame";
        }

        function send(obj, fire_and_forget) {
                if (!ws || ws.readyState !== 1) {
                        return fire_and_forget ? false
                                : Promise.reject(new Error("the box bridge is not connected"));
                }
                if (fire_and_forget) {
                        ws.send(JSON.stringify(obj));
                        return true;
                }
                seq += 1;
                obj.reply_to = seq;
                ws.send(JSON.stringify(obj));
                return new Promise(function (resolve, reject) {
                        pending[seq] = { resolve: resolve, reject: reject };
                        setTimeout(function () {
                                if (pending[seq]) {
                                        pending[seq].reject(new Error("the box timed out"));
                                        delete pending[seq];
                                }
                        }, 10000);
                });
        }

        function call(op, extra) {
                var msg = { op: op };
                if (extra) { for (var k in extra) { msg[k] = extra[k]; } }
                return send(msg);
        }

        connect();

        global.GOGA = {
                hello: function () {
                        if (connected) { return Promise.resolve({ ok: true }); }
                        if (!ready) { ready = new Promise(function () {}); connect(); }
                        return ready;
                },
                coins: function () {
                        return call("coins.balance").then(function (m) { return m.coins | 0; });
                },
                spend: function (n) {
                        return call("coins.spend", { n: n | 0 }).then(function (m) { return !!m.ok; });
                },
                earn: function (n) {
                        return call("coins.earn", { n: n | 0 }).then(function () { return true; });
                },
                saveWrite: function (key, data) {
                        return call("save.write", { key: String(key), data: String(data) })
                                .then(function (m) { return !!m.ok; });
                },
                saveRead: function (key) {
                        return call("save.read", { key: String(key) })
                                .then(function (m) { return (m.data === undefined ? "" : String(m.data)); });
                },
                toast: function (msg) {
                        return call("toast", { msg: String(msg) }).then(function () { return true; });
                },
                connected: function () { return connected; },
        };
})(window);
