/* Cafcalog — der Rundgang in Bewegung.
   GSAP leiht den Takt, three.js das Punktraster im Hero. Ohne beides
   bleibt eine vollständige, ruhige Seite — Bewegung ist Zugabe, nicht
   Bedingung. */

(function () {
  "use strict";

  var ruhig = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var hatGSAP = typeof gsap !== "undefined";
  var hatDrei = typeof THREE !== "undefined";

  /* ——— Farben aus den CSS-Variablen ———————————————————————————
     Der Canvas malt mit denselben Tönen wie die Seite; im Dunkelmodus
     wechselt er mit, weil er dieselben Variablen liest. */
  function lese(name, ersatz) {
    var wert = getComputedStyle(document.documentElement)
      .getPropertyValue(name).trim();
    return wert || ersatz;
  }

  function dreiFarbe(hex) {
    hex = hex.replace("#", "");
    if (hex.length === 3) hex = hex.replace(/./g, function (c) { return c + c; });
    return parseInt(hex, 16);
  }

  // ——— Der Tag als Punktraster (three.js) ——————————————————————
  var tagBand = null;

  function baueBand() {
    var halter = document.getElementById("tagband");
    if (!halter || !hatDrei) return;

    var szene = new THREE.Scene();
    var kamera = new THREE.PerspectiveCamera(38, 1, 1, 2000);
    kamera.position.set(0, 190, 420);
    kamera.lookAt(0, 0, 0);

    var renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    halter.appendChild(renderer.domElement);

    var SPALTEN = 96, REIHEN = 13;
    var BREITE = 960, TIEFE = 300;
    var schrittX = BREITE / (SPALTEN - 1);
    var schrittZ = TIEFE / (REIHEN - 1);

    // Der Mustertrag: oben Kalorienbögen, unten Koffein — derselbe Tag
    // wie auf den Schirmen (10. september: Espresso, Porridge,
    // Linsensuppe, Filterkaffee, Pasta).
    var kcal = { 20: 5, 21: 6, 22: 6, 23: 6, 33: 5, 34: 6, 35: 6, 36: 5,
                 52: 6, 53: 7, 54: 7, 55: 6, 64: 3, 65: 4, 77: 6, 78: 7,
                 79: 7, 80: 7, 81: 7 };
    var mg = { 20: 2, 21: 2, 33: 2, 64: 2, 65: 2 };

    var farben = {
      matrix: dreiFarbe(lese("--matrix", "#e8e7e3")),
      tinte: dreiFarbe(lese("--ink", "#161614")),
      roast: dreiFarbe(lese("--roast", "#b4531f"))
    };

    var positionen = [], farbe = new Float32Array(SPALTEN * REIHEN * 3);
    var basis = new THREE.Color(farben.matrix);
    var an = []; // Spalten- und Reihennummer je Punkt, für das Einlaufen

    for (var s = 0; s < SPALTEN; s++) {
      for (var r = 0; r < REIHEN; r++) {
        var i = s * REIHEN + r;
        var x = s * schrittX - BREITE / 2;
        var z = r * schrittZ - TIEFE / 2;
        var y = 0;
        var c = basis;
        var oben = REIHEN - 1 - r;           // Reihen von oben gezählt
        if (kcal[s] && oben < kcal[s]) { c = new THREE.Color(farben.tinte); y = 14; }
        if (mg[s] && r < mg[s]) { c = new THREE.Color(farben.roast); y = 10; }
        positionen.push(x, y, z);
        farbe[i * 3] = c.r; farbe[i * 3 + 1] = c.g; farbe[i * 3 + 2] = c.b;
        an.push(s);
      }
    }

    var geo = new THREE.BufferGeometry();
    geo.setAttribute("position",
      new THREE.Float32BufferAttribute(positionen, 3));
    geo.setAttribute("color", new THREE.BufferAttribute(farbe, 3));

    var material = new THREE.PointsMaterial({
      size: 5.2, vertexColors: true, transparent: true, opacity: 0.95,
      sizeAttenuation: true
    });
    var wolke = new THREE.Points(geo, material);

    // Die Jetzt-Linie: eine dünne Linie quer durchs Band.
    var linienGeo = new THREE.BufferGeometry().setFromPoints([
      new THREE.Vector3(0, 1, -TIEFE / 2 - 14),
      new THREE.Vector3(0, 1, TIEFE / 2 + 14)
    ]);
    var linie = new THREE.Line(linienGeo, new THREE.LineBasicMaterial({
      color: farben.tinte, transparent: true, opacity: 0.55
    }));

    var gruppe = new THREE.Group();
    gruppe.add(wolke); gruppe.add(linie);
    gruppe.rotation.x = -0.42;
    szene.add(gruppe);

    function messen() {
      var b = halter.clientWidth, h = halter.clientHeight;
      renderer.setSize(b, h);
      kamera.aspect = b / h;
      kamera.updateProjectionMatrix();
    }
    messen();
    window.addEventListener("resize", messen);

    // Wie weit der Tag schon „gelaufen" ist — der Scroll führt, die
    // Linie folgt. Ohne GSAP steht sie auf jetzt (9:41 ≈ Spalte 38).
    var fortschritt = 38 / SPALTEN;
    var maus = { x: 0, y: 0 };
    var sanft = { x: 0, y: 0 };

    halter.addEventListener("pointermove", function (e) {
      var r = halter.getBoundingClientRect();
      maus.x = (e.clientX - r.left) / r.width - 0.5;
      maus.y = (e.clientY - r.top) / r.height - 0.5;
    });
    halter.addEventListener("pointerleave", function () {
      maus.x = 0; maus.y = 0;
    });

    if (hatGSAP && !ruhig) {
      gsap.to({ p: 0 }, {
        p: 1, ease: "none",
        scrollTrigger: {
          trigger: halter, start: "top bottom", end: "bottom top",
          scrub: 0.6,
          onUpdate: function (selbst) { fortschritt = selbst.progress; }
        }
      });
    }

    var tmp = new THREE.Color(farben.matrix);
    var voll = []; // Originalfarben je Punkt
    for (var k = 0; k < SPALTEN * REIHEN; k++) {
      voll.push(new THREE.Color(farbe[k * 3], farbe[k * 3 + 1], farbe[k * 3 + 2]));
    }

    function tick(t) {
      if (document.hidden) { requestAnimationFrame(tick); return; }
      var wandern = ruhig ? 0 : Math.sin(t * 0.0006);

      // Spalten links der Linie in voller Farbe, rechts noch im Raster.
      var stunde = fortschritt * SPALTEN;
      var attribut = geo.getAttribute("color");
      for (var p = 0; p < SPALTEN * REIHEN; p++) {
        var c2 = voll[p];
        if (an[p] <= stunde || ruhig) {
          attribut.setXYZ(p, c2.r, c2.g, c2.b);
        } else {
          attribut.setXYZ(p, tmp.r, tmp.g, tmp.b);
        }
      }
      attribut.needsUpdate = true;
      linie.position.x = stunde * schrittX - BREITE / 2;

      // Parallax: die Gruppe neigt sich dem Zeiger ein wenig zu.
      sanft.x += (maus.x - sanft.x) * 0.04;
      sanft.y += (maus.y - sanft.y) * 0.04;
      gruppe.rotation.y = sanft.x * 0.22 + wandern * 0.04;
      gruppe.rotation.x = -0.42 + sanft.y * 0.1;

      renderer.render(szene, kamera);
      requestAnimationFrame(tick);
    }
    requestAnimationFrame(tick);

    tagBand = { gruppe: gruppe };
  }

  // ——— Der Takt (GSAP) ——————————————————————————————————————————
  function baueTakt() {
    if (!hatGSAP || ruhig) return;
    if (typeof ScrollTrigger === "undefined") return;
    gsap.registerPlugin(ScrollTrigger);

    // Sektionen treten auf wie Einträge: leise, von unten, kurz.
    document.querySelectorAll(".block, .held").forEach(function (el) {
      gsap.from(el, {
        y: 28, opacity: 0, duration: 0.7, ease: "power2.out",
        scrollTrigger: { trigger: el, start: "top 88%", once: true }
      });
    });

    // Galerie-Kacheln rasten ein, Reihe für Reihe versetzt.
    document.querySelectorAll(".galerie li").forEach(function (li, i) {
      gsap.from(li, {
        y: 44, opacity: 0, duration: 0.65, ease: "power2.out",
        delay: (i % 4) * 0.08,
        scrollTrigger: { trigger: li, start: "top 92%", once: true }
      });
    });

    // Die Werte zählen sich hoch — ein Zählwerk, wie in der App.
    document.querySelectorAll(".werte dt").forEach(function (dt) {
      var ziel = parseInt(dt.textContent, 10);
      if (isNaN(ziel)) return;
      var zaehler = { n: 0 };
      gsap.to(zaehler, {
        n: ziel, duration: 1.1, ease: "power1.out",
        snap: { n: 1 },
        onUpdate: function () { dt.textContent = zaehler.n; },
        scrollTrigger: { trigger: dt, start: "top 90%", once: true }
      });
    });

    // Das Punktband zwischen den Abschnitten wandert langsam weiter.
    document.querySelectorAll(".raster").forEach(function (band) {
      gsap.fromTo(band,
        { backgroundPositionX: "0px" },
        { backgroundPositionX: "96px", ease: "none",
          scrollTrigger: {
            trigger: band, start: "top bottom", end: "bottom top", scrub: 1
          }
        });
    });

    // Der Zeitstrahl: das Farbwerk wird von links freigegeben, die
    // Leselinie läuft mit. Am Ende tritt sie beiseite — in der App
    // zeigt sie jetzt, hier zeigt sie, wie weit man gelesen hat.
    var farbe = document.getElementById("strahl-farbe");
    var linie = document.getElementById("strahl-linie");
    if (farbe && linie) {
      var volleBreite = 96 * 4; // 96 Spalten, Teilung 4
      ScrollTrigger.create({
        trigger: farbe.closest("figure"),
        start: "top 78%", end: "bottom 45%", scrub: 0.5,
        onUpdate: function (selbst) {
          var p = selbst.progress;
          farbe.style.clipPath = "inset(0 " + (100 - p * 100) + "% 0 0)";
          linie.setAttribute("x", Math.max(0, p * volleBreite - 4));
          linie.style.opacity = p > 0.02 && p < 0.98 ? 0.9 : 0;
        }
      });
    }

    // Die Flipkarten klappen ein: alle Räder zugleich, gestaffelt —
    // die Machart des Zählwerks, in einem Auftritt.
    var flipkarten = document.querySelectorAll(".flipkarte");
    if (flipkarten.length) {
      gsap.from(flipkarten, {
        rotationX: -88, opacity: 0, duration: 0.8, ease: "power2.out",
        stagger: 0.12, transformOrigin: "top center",
        scrollTrigger: { trigger: ".flipwerk", start: "top 85%", once: true }
      });
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", function () {
      baueBand(); baueTakt();
    });
  } else {
    baueBand(); baueTakt();
  }
})();
