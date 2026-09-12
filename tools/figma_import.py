#!/usr/bin/env python3
"""Lädt die App-Store-Bilder nach Figma — MCP-Client für den offiziellen
Figma-Server (https://mcp.figma.com/mcp).

Der OAuth-Token wird nicht angetastet, sondern dort gelesen, wo ihn Claude
Code ablegt (macOS-Schlüsselbund, Eintrag „Claude Code-credentials“).

Aufruf:  echo '{"auftrag.json-Inhalt"}' | python3 tools/figma_import.py
Auftrag: {"liste": true}
      |  {"schritte": [{"tool": "get_metadata", "arguments": {...}}, …]}

Sicherheit: der Endpunkt ist ein Festwert (https, nur mcp.figma.com), die
Auflösung des Hosts wird gegen Privat-/Loopback-Adressen geprüft,
Umleitungen sind abgeschaltet.
"""
import ipaddress
import json
import socket
import subprocess
import sys
import urllib.request

URL = 'https://mcp.figma.com/mcp'
ERLAUBT = 'mcp.figma.com'
BUNDLE = 'figma_prod@2_2_107'


class KeineUmleitung(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise urllib.error.HTTPError(
            req.full_url, code, 'Umleitungen sind deaktiviert', headers, fp)


def pruefe_endpunkt():
    if URL != f'https://{ERLAUBT}/mcp':
        raise SystemExit('Endpunkt weicht vom Festwert ab')
    for info in socket.getaddrinfo(ERLAUBT, 443, proto=socket.IPPROTO_TCP):
        adresse = ipaddress.ip_address(info[4][0])
        if (adresse.is_private or adresse.is_loopback or adresse.is_link_local
                or adresse.is_reserved or adresse.is_multicast):
            raise SystemExit(f'Host löst auf gesperrte Adresse auf: {adresse}')


def token():
    roh = subprocess.check_output(
        ['security', 'find-generic-password', '-s', 'Claude Code-credentials', '-w']
    ).decode().strip()
    kandidaten = json.loads(roh).get('mcpOAuth', {})
    for wert in kandidaten.values():
        zugang = wert.get('accessToken') if isinstance(wert, dict) else None
        if zugang:
            yield zugang


def post(nutzdaten, zugang, sitzung=None, zeitlimit=300):
    kopf = {'Content-Type': 'application/json',
            'Accept': 'application/json, text/event-stream',
            'X-Figma-Plugin-Bundle': BUNDLE,
            'Authorization': 'Bearer ' + zugang}
    if sitzung:
        kopf['Mcp-Session-Id'] = sitzung
    anfrage = urllib.request.Request(
        URL, data=json.dumps(nutzdaten).encode(), headers=kopf, method='POST')
    try:
        antwort = opener.open(anfrage, timeout=zeitlimit)
        status, kopf_out, body = antwort.status, dict(antwort.headers), antwort.read().decode()
    except urllib.error.HTTPError as fehler:
        status, kopf_out, body = fehler.code, dict(fehler.headers), fehler.read().decode()
    botschaft = None
    if body.lstrip().startswith('{'):
        botschaft = json.loads(body)
    else:
        for zeile in body.splitlines():
            if zeile.startswith('data:'):
                try:
                    botschaft = json.loads(zeile[5:].strip())
                except ValueError:
                    pass
    sitzung_out = next((v for k, v in kopf_out.items()
                        if k.lower() == 'mcp-session-id'), None)
    return status, sitzung_out, botschaft


opener = urllib.request.build_opener(KeineUmleitung)

def main():
    pruefe_endpunkt()
    auftrag = json.load(sys.stdin)
    sitzung = None
    diagnostik = []
    for zugang in token():
        status, sitzung, botschaft = post(
            {'jsonrpc': '2.0', 'id': 1, 'method': 'initialize', 'params': {
                'protocolVersion': '2025-06-18', 'capabilities': {},
                'clientInfo': {'name': 'cafcalog-import', 'version': '1.0'}}},
            zugang)
        kurzer = json.dumps(botschaft, ensure_ascii=False)[:300] if botschaft else '(leer)'
        diagnostik.append(f'initialize → HTTP {status}: {kurzer}')
        if status == 200 and botschaft and 'result' in botschaft:
            break
    else:
        for zeile in diagnostik:
            print(zeile, file=sys.stderr)
        raise SystemExit('kein gültiger Token')
    post({'jsonrpc': '2.0', 'method': 'notifications/initialized'}, zugang, sitzung)

    if auftrag.get('liste'):
        _, _, botschaft = post({'jsonrpc': '2.0', 'id': 2, 'method': 'tools/list'},
                               zugang, sitzung)
        werkzeuge = botschaft['result']['tools']
        print('Werkzeuge:', ', '.join(w['name'] for w in werkzeuge))
        for w in werkzeuge:
            if w['name'] in ('use_figma', 'upload_assets', 'get_metadata'):
                print('\n===', w['name'], '===')
                print(json.dumps(w.get('inputSchema', {}), ensure_ascii=False)[:2000])
        return

    for nr, schritt in enumerate(auftrag.get('schritte', []), start=1):
        status, _, botschaft = post(
            {'jsonrpc': '2.0', 'id': 10 + nr, 'method': 'tools/call',
             'params': {'name': schritt['tool'], 'arguments': schritt.get('arguments', {})}},
            zugang, sitzung)
        print(f'--- Schritt {nr}: {schritt["tool"]} (HTTP {status})')
        if botschaft and 'error' in botschaft:
            print('FEHLER:', json.dumps(botschaft['error'], ensure_ascii=False)[:800])
        elif botschaft:
            print(json.dumps(botschaft.get('result', {}), ensure_ascii=False)[:2500])


if __name__ == '__main__':
    main()
