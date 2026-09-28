/* GOGA ORBIT (v043 pass 3 - the WEB PILOT) - a three.js game riding the
 * box's web runner. 100% original geometry, no external assets: rings of
 * rock drift along the orbit lane, gold shards pay GOGACoins through the
 * SDK bridge (window.GOGA - goga_bridge.js), the best run lands in the
 * package's portable save through GOGA.saveWrite. Drag anywhere to steer
 * the ship's lane angle. Proves the whole web seat: the box's localhost
 * server, the in-app surface (Android WebView / PC app-mode window) and
 * the WebSocket SDK bridge - one game, zero Godot. */
(function () {
        "use strict";

        var W = function () { return window.innerWidth; };
        var H = function () { return window.innerHeight; };

        var renderer = new THREE.WebGLRenderer({ antialias: true });
        renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
        renderer.setSize(W(), H());
        document.body.appendChild(renderer.domElement);

        var scene = new THREE.Scene();
        scene.background = new THREE.Color(0x0b0d16);
        scene.fog = new THREE.Fog(0x0b0d16, 60, 140);

        var camera = new THREE.PerspectiveCamera(62, W() / H(), 0.1, 300);

        // ---- the orbit lane: a torus track + a planet core ----
        var R = 22;                       // the lane's radius
        var core = new THREE.Mesh(
                new THREE.IcosahedronGeometry(6, 1),
                new THREE.MeshStandardMaterial({ color: 0x2a3550, flatShading: true }));
        scene.add(core);
        var lane = new THREE.Mesh(
                new THREE.TorusGeometry(R, 0.55, 10, 72),
                new THREE.MeshStandardMaterial({ color: 0x3a2c18, roughness: 0.9 }));
        lane.rotation.x = Math.PI / 2;
        scene.add(lane);
        // the runway lights
        for (var i = 0; i < 36; i++) {
                var a = (i / 36) * Math.PI * 2;
                var post = new THREE.Mesh(
                        new THREE.BoxGeometry(0.3, 1.2, 0.3),
                        new THREE.MeshBasicMaterial({ color: i % 3 ? 0x51402a : 0xf5c56b }));
                post.position.set(Math.cos(a) * R, 0.8, Math.sin(a) * R);
                scene.add(post);
        }
        // the star sky
        var starGeo = new THREE.BufferGeometry();
        var starPos = [];
        for (var s = 0; s < 500; s++) {
                var v = new THREE.Vector3().randomDirection().multiplyScalar(90 + Math.random() * 40);
                starPos.push(v.x, v.y, v.z);
        }
        starGeo.setAttribute("position", new THREE.Float32BufferAttribute(starPos, 3));
        scene.add(new THREE.Points(starGeo,
                new THREE.PointsMaterial({ color: 0x8a90b8, size: 0.5 })));
        scene.add(new THREE.HemisphereLight(0xbfc8ff, 0x201408, 0.9));
        var sun = new THREE.DirectionalLight(0xffd76b, 1.1);
        sun.position.set(30, 40, 20);
        scene.add(sun);

        // ---- the ship: an original dart built from primitives ----
        var ship = new THREE.Group();
        var hull = new THREE.Mesh(
                new THREE.ConeGeometry(0.7, 2.6, 6),
                new THREE.MeshStandardMaterial({ color: 0xf5c56b, flatShading: true }));
        hull.rotation.x = Math.PI / 2;
        ship.add(hull);
        var fin = new THREE.Mesh(
                new THREE.BoxGeometry(2.2, 0.12, 0.7),
                new THREE.MeshStandardMaterial({ color: 0xb3542e, flatShading: true }));
        ship.add(fin);
        scene.add(ship);

        // ---- the drifters: rocks (hurt) and gold (pay) ----
        var rocks = [], golds = [];
        function makeRock() {
                var m = new THREE.Mesh(
                        new THREE.DodecahedronGeometry(0.9 + Math.random() * 0.7, 0),
                        new THREE.MeshStandardMaterial({ color: 0x6d6f80, flatShading: true }));
                scene.add(m);
                return m;
        }
        function makeGold() {
                var m = new THREE.Mesh(
                        new THREE.OctahedronGeometry(0.55, 0),
                        new THREE.MeshStandardMaterial({ color: 0xffd76b, emissive: 0x8a6a10 }));
                scene.add(m);
                return m;
        }
        function seed(obj, gold) {
                obj.userData.a = Math.random() * Math.PI * 2;
                obj.userData.spin = (Math.random() - 0.5) * 2;
                obj.userData.h = (Math.random() - 0.5) * 2.4;
                obj.userData.gold = !!gold;
                var pool = gold ? golds : rocks;
                obj.position.set(Math.cos(obj.userData.a) * R, obj.userData.h, Math.sin(obj.userData.a) * R);
                pool.push(obj);
        }
        for (var r = 0; r < 14; r++) seed(makeRock(), false);
        for (var g = 0; g < 6; g++) seed(makeGold(), true);

        // ---- the state ----
        var shipA = 0;             // the ship's lane angle
        var targetA = 0;
        var speed = 0.55;          // lane radians/sec the world drifts
        var score = 0;
        var best = 0;
        var alive = false;
        var started = false;
        var t = 0;

        var hudScore = document.getElementById("score");
        var hudCoin = document.getElementById("coin");
        var msg = document.getElementById("msg");

        // ---- the SDK bridge (window.GOGA - goga_bridge.js) ----
        var bridge = window.GOGA || null;
        if (bridge) {
                bridge.hello().then(function () {
                        bridge.saveRead("best").then(function (txt) {
                                best = parseInt(txt || "0", 10) || 0;
                                hudCoin.textContent = "BEST " + best;
                        }).catch(function () {});
                        bridge.toast("GOGA ORBIT is live - the web bridge works");
                }).catch(function () {
                        hudCoin.textContent = "(box away)";
                });
        }

        function bank() {
                if (score > best) {
                        best = score;
                        if (bridge) { bridge.saveWrite("best", String(best)).catch(function () {}); }
                }
        }

        function die() {
                alive = false;
                bank();
                msg.innerHTML = "RUN OVER - " + score +
                        '<div id="sub">drag or press to fly again</div>';
                msg.style.display = "block";
                if (bridge) { bridge.earn(Math.min(30, Math.floor(score / 10))).catch(function () {}); }
        }

        // ---- input: drag to steer (touch + mouse) ----
        var dragging = false, lastX = 0;
        function down(x) { dragging = true; lastX = x; start(); }
        function move(x) {
                if (!dragging) return;
                targetA -= (x - lastX) * 0.012;
                lastX = x;
        }
        function up() { dragging = false; }
        window.addEventListener("pointerdown", function (e) { down(e.clientX); });
        window.addEventListener("pointermove", function (e) { move(e.clientX); });
        window.addEventListener("pointerup", up);
        window.addEventListener("pointercancel", up);
        window.addEventListener("keydown", function (e) {
                if (e.code === "ArrowLeft" || e.code === "ArrowRight") start();
        });
        window.addEventListener("keyup", function (e) {
                if (e.code === "ArrowLeft") targetA += 0.25;
                if (e.code === "ArrowRight") targetA -= 0.25;
        });

        function start() {
                if (!started || alive) return;
                score = 0;
                hudScore.textContent = "0";
                alive = true;
                msg.style.display = "none";
        }

        // ---- the loop ----
        function reset(obj) {
                obj.userData.a += Math.PI * 2;             // a full lap ahead
                obj.userData.h = (Math.random() - 0.5) * 2.4;
        }

        function tick() {
                requestAnimationFrame(tick);
                var dt = Math.min(0.05, (performance.now() - (tick._p || performance.now())) / 1000);
                tick._p = performance.now();
                t += dt;

                shipA += (targetA - shipA) * Math.min(1, dt * 9);
                ship.position.set(Math.cos(shipA) * R, 1.1, Math.sin(shipA) * R);
                ship.rotation.y = -shipA + Math.PI / 2;
                if (alive) {
                        score += Math.round(dt * 6);
                        hudScore.textContent = String(score);
                }
                speed = 0.55 + Math.min(1.4, score / 400);

                core.rotation.y += dt * 0.15;
                core.rotation.x += dt * 0.03;

                var pools = [rocks, golds];
                for (var pi = 0; pi < 2; pi++) {
                        var pool = pools[pi];
                        for (var i = 0; i < pool.length; i++) {
                                var o = pool[i];
                                o.userData.a -= speed * dt * (o.userData.gold ? 0.8 : 1.0);
                                o.position.set(
                                        Math.cos(o.userData.a) * R,
                                        o.userData.h + Math.sin(t * 2 + i) * 0.25,
                                        Math.sin(o.userData.a) * R);
                                o.rotation.x += dt * o.userData.spin;
                                o.rotation.y += dt * o.userData.spin * 0.7;
                                if (o.userData.a < shipA - Math.PI * 0.5) reset(o);
                                // the catch test (lane distance)
                                if (alive) {
                                        var d = Math.abs(_wrap(o.userData.a - shipA));
                                        var near = d < 0.13 && Math.abs(o.position.y - ship.position.y) < 1.6;
                                        if (near && o.userData.gold) {
                                                score += 25;
                                                bridge && bridge.earn(1).catch(function () {});
                                                reset(o);
                                                o.position.y = o.userData.h;
                                        } else if (near && !o.userData.gold) {
                                                die();
                                        }
                                }
                        }
                }
                camera.position.set(Math.cos(shipA + 0.28) * (R + 7), 4.6,
                                Math.sin(shipA + 0.28) * (R + 7));
                camera.lookAt(ship.position);
                renderer.render(scene, camera);
        }

        function _wrap(a) {
                while (a > Math.PI) a -= Math.PI * 2;
                while (a < -Math.PI) a += Math.PI * 2;
                return a;
        }

        window.addEventListener("resize", function () {
                camera.aspect = W() / H();
                camera.updateProjectionMatrix();
                renderer.setSize(W(), H());
        });

        msg.style.display = "block";
        tick();
})();
