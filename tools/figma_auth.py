#!/usr/bin/env python3
"""Neue Figma-OAuth-Anmeldung für den MCP-Import.

Ablauf: baut die Autorisierungs-URL aus dem im Schlüsselbund gespeicherten
Client („Claude Code-credentials“), öffnet sie im Browser, fängt den
Callback auf 127.0.0.1:3118 ab und tauscht den Code am Token-Endpunkt.
Der frische accessToken wird in denselben Schlüsselbund-Eintrag
zurückgeschrieben, aus dem die Client-Daten kamen — Claude Code profitiert
mit. Das Geheimnis wird nirgends ausgegeben.

Callbacks mit nicht passendem state (veraltete Tabs, frühere Versuche)
werden höflich abgewiesen; gewartet wird auf den passenden.

Aufruf:  python3 tools/figma_auth.py

Sicherheit: https-Festwerte auf erlaubte Hosts, die Host-Auflösung wird
gegen Privat-/Loopback-Adressen geprüft, Umleitungen sind abgeschaltet.
"""
import base64
import hashlib
import http.server
import ipaddress
import json
import secrets
import socket
import subprocess
import threading
import time
import urllib.error
import urllib.parse
import urllib.request

SCHLUESSELBUND = 'Claude Code-credentials'
ACCOUNT = 'clausmedvesek'
REDIRECT = 'http://localhost:3118/callback'
PORT = 3118
ZEITLIMIT = 420  # Sekunden auf die Zustimmung im Browser
URL = 'https://mcp.figma.com/mcp'
AUTHORISIERUNG = 'https://www.figma.com/oauth/mcp'
TOKEN_ENDE = 'https://api.figma.com/v1/oauth/token'
ERLAUBTE_HOSTS = {'mcp.figma.com', 'api.figma.com', 'www.figma.com'}


class KeineUmleitung(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise urllib.error.HTTPError(
            req.full_url, code, 'Umleitungen sind deaktiviert', headers, fp)


def geprueft(url):
    """Nur https auf einen der erlaubten Hosts, und der Host darf sich nicht
    in eine Privat-/Loopback-Adresse auflösen (SSRF-Leitplanke)."""
    teile = urllib.parse.urlparse(url)
    if teile.scheme != 'https' or teile.hostname not in ERLAUBTE_HOSTS:
        raise SystemExit(f'Endpunkt nicht erlaubt: {url}')
    for info in socket.getaddrinfo(teile.hostname, 443, proto=socket.IPPROTO_TCP):
        adresse = ipaddress.ip_address(info[4][0])
        if (adresse.is_private or adresse.is_loopback or adresse.is_link_local
                or adresse.is_reserved or adresse.is_multicast):
            raise SystemExit(f'Host löst auf gesperrte Adresse auf: {adresse}')
    return url


opener = urllib.request.build_opener(KeineUmleitung)


def hole(url, daten=None, kopf=None, methode=None, zeitlimit=300):
    anfrage = urllib.request.Request(geprueft(url), data=daten,
                                     headers=kopf or {}, method=methode)
    return opener.open(anfrage, timeout=zeitlimit)


def lese_ablage():
    roh = subprocess.check_output(
        ['security', 'find-generic-password', '-s', SCHLUESSELBUND, '-w']).decode().strip()
    return json.loads(roh)


def schreibe_ablage(ablage):
    """Schreibt den kompletten Ablage-Inhalt zurück — nur das accessToken-
    Feld des gewählten Eintrags ändert sich, alles andere bleibt erhalten."""
    subprocess.check_output(
        ['security', 'add-generic-password', '-U',
         '-s', SCHLUESSELBUND, '-a', ACCOUNT, '-w', json.dumps(ablage)])


def kandidaten(ablage):
    """Figma-Einträge mit vollständigen Client-Daten."""
    reif = []
    for schluessel, wert in ablage.get('mcpOAuth', {}).items():
        if 'figma' not in schluessel or not isinstance(wert, dict):
            continue
        if wert.get('clientId') and wert.get('clientSecret'):
            reif.append((schluessel, wert))
    return reif


def main():
    ablage = lese_ablage()
    eintraege = kandidaten(ablage)
    if not eintraege:
        raise SystemExit('kein Figma-Eintrag mit Client-Daten im Schlüsselbund')

    pruefer = secrets.token_urlsafe(64)
    herausforderung = base64.urlsafe_b64encode(
        hashlib.sha256(pruefer.encode()).digest()).rstrip(b'=').decode()
    zustand = secrets.token_urlsafe(16)

    ergebnis = {}
    hinweis = {'falsch': 0}

    class Callback(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            pfad = urllib.parse.urlparse(self.path).path
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.end_headers()
            if pfad != '/callback' or 'code' in ergebnis:
                self.wfile.write(b'<html><body></body></html>')
                return
            query = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
            kam = (query.get('state') or [''])[0]
            if kam != zustand:
                # Veralteter oder fremder Callback — weiter warten.
                hinweis['falsch'] += 1
                self.wfile.write('<html><body><h2>Veralteter Link — bitte den neu '
                                 'geöffneten Tab bestätigen.</h2></body></html>'
                                 .encode('utf-8'))
                return
            ergebnis['code'] = (query.get('code') or [''])[0]
            ergebnis['fehler'] = (query.get('error') or [''])[0]
            self.wfile.write('<html><body><h2>✓ Figma-Bestätigung erhalten '
                             '— zurück im Terminal.</h2></body></html>'
                             .encode('utf-8'))

        def log_message(self, *args):
            pass

    server = http.server.HTTPServer(('127.0.0.1', PORT), Callback)
    threading.Thread(target=server.serve_forever, daemon=True).start()

    for schluessel, client in eintraege:
        anfrage = urllib.parse.urlencode({
            'response_type': 'code',
            'client_id': client['clientId'],
            'redirect_uri': REDIRECT,
            'scope': 'mcp:connect',
            'state': zustand,
            'code_challenge': herausforderung,
            'code_challenge_method': 'S256',
            'resource': URL,
        })
        ziel = f'{AUTHORISIERUNG}?{anfrage}'
        print('Browser öffnet die Figma-Zustimmung — bitte im NEU geöffneten Tab '
              'bestätigen (alte Tabs werden ignoriert). Falls kein Browser kommt:')
        print(ziel)
        subprocess.run(['open', ziel], check=False)

        frist = time.time() + ZEITLIMIT
        while time.time() < frist and not ergebnis:
            time.sleep(0.3)
        server.shutdown()
        if not ergebnis:
            raise SystemExit('Zeit abgelaufen — keine Bestätigung im Browser.')
        if ergebnis.get('fehler'):
            print(f'Autorisierung abgelehnt: {ergebnis["fehler"]} — nächster Kandidat.')
            ergebnis.clear()
            continue

        tausch = urllib.parse.urlencode({
            'grant_type': 'authorization_code',
            'code': ergebnis['code'],
            'redirect_uri': REDIRECT,
            'client_id': client['clientId'],
            'client_secret': client['clientSecret'],
            'code_verifier': pruefer,
            'resource': URL,
        }).encode()
        try:
            with hole(TOKEN_ENDE, daten=tausch, kopf={
                    'Content-Type': 'application/x-www-form-urlencoded'},
                    methode='POST') as antwort:
                tokens = json.loads(antwort.read().decode())
        except urllib.error.HTTPError as fehler:
            einzelheiten = fehler.read().decode(errors='replace')[:300]
            print(f'Token-Endpunkt lehnte ab (HTTP {fehler.code}): {einzelheiten}')
            print('— nächster Kandidat; bitte im neuen Tab erneut bestätigen.')
            ergebnis.clear()
            continue
        if not tokens.get('access_token'):
            raise SystemExit('Token-Endpunkt lieferte kein access_token: '
                             + json.dumps(tokens)[:300])

        client['accessToken'] = tokens['access_token']
        if tokens.get('refresh_token'):
            client['refreshToken'] = tokens['refresh_token']
        ablage['mcpOAuth'][schluessel] = client
        schreibe_ablage(ablage)
        print(f'✓ Neue Anmeldung gespeichert ({schluessel[:36]}…). Der Import kann laufen.')
        return

    raise SystemExit('alle Kandidaten gescheitert')


if __name__ == '__main__':
    main()
