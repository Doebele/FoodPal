/* Cafcalog — der Katalog in Bewegung, zweite Fassung.
   Ein Tag, in Schritten erzaehlt: die Leselinie rueckt im Fünfzehn-Minuten-
   Takt; an jedem Eintrag, den sie erreicht, erscheint seine Marke im Strahl
   und das Ziffernwerk rattert auf die neue Summe. Ohne JS bleibt der
   vollstaendige Katalog mit Endzustaenden stehen. */

(function () {
  "use strict";

  var ruhig = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  // Der zehnte September aus der Demo-Saat: (Spalte, Zwischensumme kcal).
  var SCHRITTE = [
    { spalte: 29, summe: 2 },
    { spalte: 34, summe: 472 },
    { spalte: 53, summe: 932 },
    { spalte: 64, summe: 936 },
    { spalte: 78, summe: 1716 }
  ];
  var SPALTEN = 96;
  var PITCH = 4;
  var UEBERSTAND = 3;

  function summeBei(spalte) {
    var summe = 0;
    for (var i = 0; i < SCHRITTE.length; i++) {
      if (SCHRITTE[i].spalte <= spalte) summe = SCHRITTE[i].summe;
    }
    return summe;
  }

  function stehen() {
    document.querySelectorAll(".flipkarte .ziffer").forEach(function (z, i) {
      z.textContent = "1716"[i] ?? "0";
    });
    var werte = document.querySelectorAll(".inhalt .wieviel");
    if (werte.length >= 2) { werte[0].textContent = "4"; werte[1].textContent = "95"; }
    document.querySelectorAll("#maske .kachel").forEach(function (kachel) {
      var w = kachelWerte(kachel);
      punkte(kachel, 1, w.kcalP);
      punkte(kachel, 2, w.mgP);
    });
    var farbe = document.getElementById("strahl-farbe");
    var linie = document.getElementById("strahl-linie");
    if (farbe) farbe.style.clipPath = "none";
    if (linie) linie.style.opacity = 0;
  }

  if (typeof gsap === "undefined" || ruhig ||
      typeof ScrollTrigger === "undefined") {
    stehen();
    return;
  }
  gsap.registerPlugin(ScrollTrigger);

  // ——— 0: Der Umschalter im Kopf ————————————————————————————————
  // Zunaechst zaehlt die App Koffein (mg aktiv); wer zu scrollen
  // beginnt, wechselt auf Kalorien — der Griff, der alles traegt.
  var schalter = document.getElementById("umschalter");
  var held = document.querySelector(".held");
  if (schalter && held) {
    schalter.dataset.aktiv = "mg";
    ScrollTrigger.create({
      trigger: held, start: "top top+=1", end: "+=45%", scrub: 0.4,
      onUpdate: function (selbst) {
        var zustand = selbst.progress < 0.5 ? "mg" : "kcal";
        if (schalter.dataset.aktiv !== zustand) {
          schalter.dataset.aktiv = zustand;
          gsap.fromTo(schalter, { scale: 0.985 }, {
            scale: 1, duration: 0.3, ease: "power2.out" });
        }
      }
    });
  }

  function kachelWerte(kachel) {
    var text = kachel.querySelector(".kachelwerte").textContent;
    var kcal = parseFloat(text) || 0;
    var mg = parseFloat(text.split("·")[1]) || 0;
    return {
      kcalP: Math.min(12, Math.max(kcal > 0 ? 1 : 0, Math.round(kcal / 40))),
      mgP: Math.min(12, Math.round(mg / 13))
    };
  }

  function punkte(kachel, balkenIndex, anzahl) {
    var balken = kachel.querySelectorAll(".balken")[balkenIndex - 1];
    if (!balken) return;
    balken.querySelectorAll("i").forEach(function (punkt, i) {
      punkt.classList.toggle("an", i < anzahl);
    });
  }

  // ——— 1: Der Strahl in Viertelstunden-Schritten ——————————————————
  // Die ganze Sektion pinnt — Nummer, Text und Band: was oben steht,
  // bleibt stehen, bis der Tag durchgelaufen ist.
  var farbe = document.getElementById("strahl-farbe");
  var linie = document.getElementById("strahl-linie");
  if (farbe && linie) {
    ScrollTrigger.create({
      trigger: farbe.closest(".kapitel"),
      start: "top 8%", end: "+=220%", pin: true, scrub: 0.5,
      onUpdate: function (selbst) {
        var schritt = Math.floor(selbst.progress * SPALTEN);
        var prozent = (schritt / SPALTEN) * 100;
        farbe.style.clipPath = "inset(0 " + (100 - prozent) + "% 0 0)";
        linie.setAttribute("x", Math.max(0, schritt * PITCH - 1 + UEBERSTAND));
        linie.style.opacity = selbst.progress < 0.99 ? 0.9 : 0;
      }
    });
  }

  // ——— 2: Das Ziffernwerk rattert von Summe zu Summe ———————————————
  function werkSektion() {
    var werk = document.querySelector(".flipwerk");
    return werk ? werk.closest(".kapitel") : document.body;
  }

  var karten = document.querySelectorAll(".flipkarte");
  if (karten.length) {
    var ziffern = Array.from(karten).map(function (k) {
      return k.querySelector(".ziffer");
    });
    var letzte = "";
    function rattere(text) {
      ziffern.forEach(function (z, i) {
        if (text[i] !== letzte[i]) {
          z.textContent = text[i];
          gsap.fromTo(karten[i], { rotationX: -80 }, {
            rotationX: 0, duration: 0.24, ease: "power2.out", overwrite: true
          });
        }
      });
      letzte = text;
    }
    rattere("0000");
    ScrollTrigger.create({
      trigger: werkSektion(),
      start: "top 8%", end: "+=120%", pin: true, scrub: 0.5,
      onUpdate: function (selbst) {
        var schritt = Math.floor(selbst.progress * SPALTEN);
        var summe = summeBei(schritt);
        rattere(String(summe).padStart(4, "0"));
      }
    });
    document.querySelectorAll(".buehne img").forEach(function (bild, i) {
      gsap.from(bild, {
        y: 24, opacity: 0, duration: 0.6, delay: i * 0.1,
        scrollTrigger: { trigger: bild, start: "top 90%", once: true }
      });
    });
  }

  // ——— 3: Das Schema baut sich auf ————————————————————————————————
  document.querySelectorAll(".schema-teil").forEach(function (teil, i) {
    gsap.from(teil, {
      opacity: 0, y: 14, duration: 0.5, delay: i * 0.09,
      scrollTrigger: { trigger: ".schema", start: "top 85%", once: true }
    });
  });

  // ——— 4: Die Detailseite stellt ihre Werte ein ————————————————————
  function detailSektion() {
    var i = document.querySelector(".inhalt");
    return i ? i.closest(".kapitel") : document.body;
  }

  var werte = document.querySelectorAll(".inhalt .wieviel");
  if (werte.length >= 2) {
    var kcalFeld = werte[0];
    var mgFeld = werte[1];
    gsap.to({ p: 0 }, {
      p: 1, ease: "none",
      scrollTrigger: {
        trigger: detailSektion(),
        start: "top 8%", end: "+=100%", pin: true, scrub: 0.5
      },
      onUpdate: function () {
        var p = this.targets()[0].p;
        kcalFeld.textContent = Math.round(p * 4);
        mgFeld.textContent = Math.round(p * 95);
      }
    });
    document.querySelectorAll(".inhalt li").forEach(function (zeile, i) {
      gsap.from(zeile, {
        opacity: 0, x: -14, duration: 0.5, delay: i * 0.07,
        scrollTrigger: { trigger: ".inhalt", start: "top 85%", once: true }
      });
    });
  }

  // ——— 5: Die Cafe-Galerie ————————————————————————————————————————
  document.querySelectorAll(".cafe-galerie li").forEach(function (li, i) {
    gsap.from(li, {
      opacity: 0, scale: 0.94, duration: 0.5, delay: (i % 3) * 0.08,
      scrollTrigger: { trigger: li, start: "top 92%", once: true }
    });
  });

  // ——— 6: Die Auswahlmaske setzt ihre Punkte ——————————————————————
  function maskenSektion() {
    var m = document.getElementById("maske");
    return m ? m.closest(".kapitel") : document.body;
  }

  var kacheln = document.querySelectorAll("#maske .kachel");
  if (kacheln.length) {
    kacheln.forEach(function (k) {
      var w = kachelWerte(k);
      punkte(k, 1, 0); punkte(k, 2, 0);
      gsap.to({ p: 0 }, {
        p: 1, ease: "none",
        scrollTrigger: {
          trigger: maskenSektion(), start: "top 8%", end: "+=100%",
          pin: true, scrub: 0.5
        },
        onUpdate: function () {
          var p = this.targets()[0].p;
          punkte(k, 1, Math.round(p * w.kcalP));
          punkte(k, 2, Math.round(p * w.mgP));
        }
      });
    });
  }

  // ——— 7: Rechts, links — gemeinsam und erst nach dem Ansehen —————
  var paar = document.querySelector(".wechsel-paar");
  var lichter = document.querySelectorAll(".wechsel-licht");
  var hinweise = document.querySelectorAll(".wechsel-hinweis");
  if (paar && lichter.length) {
    var grund = Array.from(hinweise).map(function (h) {
      return { grund: h.textContent, links: h.textContent.replace("rechts", "links") };
    });
    // Erst stehen lassen (bis 40 %), dann gemeinsam wenden.
    gsap.to({ p: 0 }, {
      p: 1, ease: "none",
      scrollTrigger: {
        trigger: paar.closest(".kapitel"),
        start: "top 8%", end: "+=110%", pin: true, scrub: 0.7
      },
      onUpdate: function () {
        var p = Math.max(0, (this.targets()[0].p - 0.4) / 0.6);
        var winkel = p * 180;
        lichter.forEach(function (licht) {
          licht.style.transform = "rotateY(" + winkel + "deg)";
        });
        hinweise.forEach(function (h, i) {
          if (!grund[i]) return;
          h.textContent = winkel > 90 ? grund[i].links : grund[i].grund;
        });
      }
    });
  }
})();
