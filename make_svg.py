# -*- coding: utf-8 -*-
"""Erzeugt die SVG-Version des AA Intelligence Index Charts (identisch zum Penpot-Frame)."""

DATA = [
    ("Claude Fable 5.1 (max with fallback)", 53.3737509623252, "Anthropic", "#CC785C"),
    ("GPT-6 Astra (max)", 52.814069395513, "OpenAI", "#1F1F1F"),
    ("Claude Opus 5 (max)", 50.7001865797629, "Anthropic", "#CC785C"),
    ("Claude Fable 5 (with fallback)", 49.6994452733378, "Anthropic", "#CC785C"),
    ("Muse Spark 1.3 (max)", 48.1690107719685, "Muse", "#0089F4"),
    ("GPT-5.6 Sol (max)", 47.0613568915036, "OpenAI", "#1F1F1F"),
    ("GLM-5.3 (max)", 44.855717385614, "Zhipu", "#1C7FF8"),
    ("Grok 4.6 (high)", 44.4050073012592, "xAI", "#736CD3"),
    ("Kimi K3 (max)", 43.7841729518782, "Moonshot AI", "#047AFE"),
    ("GPT-5.6 Terra (max)", 42.2514998239494, "OpenAI", "#1F1F1F"),
    ("GLM-5.3-Flash", 41.907366113455, "Zhipu", "#1C7FF8"),
    ("Gemini 3.8 Flash (high)", 41.1863571765904, "Google", "#34A853"),
    ("Qwen3.8 2.4T A95B", 40.0445723105325, "Alibaba", "#FF7018"),
    ("DeepSeek V4.1 Flash (max)", 39.545442472527, "DeepSeek", "#2243E6"),
    ("GPT-5.6 Luna (max)", 37.5048489690841, "OpenAI", "#1F1F1F"),
    ("DeepSeek V4 Pro 0813 (max)", 36.2828791278402, "DeepSeek", "#2243E6"),
    ("Qwen3.8 27B (xhigh)", 33.9015108057476, "Alibaba", "#FF7018"),
    ("K2 Horizon 375B A23B", 30.7949302696723, "Moonshot AI", "#047AFE"),
    ("MiniMax-M3", 29.6125932236316, "MiniMax", "#EB3568"),
    ("Inkling", 25.5423060999384, "Inkling", "#7F4BF3"),
]

W, H = 1280, 1240
FONT = "Inter, -apple-system, 'Segoe UI', Roboto, sans-serif"
CHART_TOP, BAR_X, SCALE, BAR_H, PITCH = 240, 336, 13, 26, 40
CHART_BOTTOM = CHART_TOP + 19 * PITCH + BAR_H  # 1026

parts = []
parts.append(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">')
parts.append(f'<rect width="{W}" height="{H}" fill="#FFFFFF"/>')

def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

def text(x, y, s, size, fill, weight=400, anchor="start", extra=""):
    parts.append(
        f'<text x="{x}" y="{y}" font-family="{FONT}" font-size="{size}" '
        f'font-weight="{weight}" fill="{fill}" text-anchor="{anchor}" {extra}>{esc(s)}</text>'
    )

# Header
parts.append(f'<rect x="56" y="44" width="246" height="28" rx="14" fill="#F1EAFD"/>')
text(179, 62, "UPDATED · 14 SEP 2026", 12, "#7F4BF3", 600, "middle")
text(56, 116, "Artificial Analysis Intelligence Index", 30, "#161616", 700)
text(56, 152, "Intelligence Index v4.3 incorporates 10 evaluations: AA-Briefcase, GDPval-AA v2, AutomationBench-AA,", 14, "#555555")
text(56, 172, "Terminal-Bench v4.0, SciCode, Humanity's Last Exam, GDP.pdf, CritPt, AA-Omniscience, AA-LCR v1.1", 14, "#555555")
text(56, 208, "Intelligence evaluations measured independently by Artificial Analysis · Higher is better", 12, "#7A7A7A")

# Gridlines + axis labels
for v in range(0, 61, 10):
    x = BAR_X + v * SCALE
    color = "#C9C9C9" if v == 0 else "#ECECEC"
    wline = 1.5 if v == 0 else 1
    parts.append(f'<rect x="{x}" y="228" width="{wline}" height="{CHART_BOTTOM - 224}" fill="{color}"/>')
    text(x + 1, CHART_BOTTOM + 26, str(v), 11, "#9A9A9A", 400, "middle")

# Rows
for i, (label, val, provider, color) in enumerate(DATA):
    y = CHART_TOP + i * PITCH
    w = val * SCALE
    parts.append(f'<rect x="{BAR_X}" y="{y}" width="{w}" height="{BAR_H}" rx="3" fill="{color}"/>')
    text(312, y + 18, label, 13, "#333333", 400, "end")
    text(BAR_X + w + 8, y + 18, f"{val:.1f}", 13, "#161616", 600)

# Legend
PROVIDERS = [
    ("Anthropic", "#CC785C"), ("OpenAI", "#1F1F1F"), ("Muse", "#0089F4"),
    ("Zhipu", "#1C7FF8"), ("xAI", "#736CD3"), ("Moonshot AI", "#047AFE"),
    ("Google", "#34A853"), ("Alibaba", "#FF7018"), ("DeepSeek", "#2243E6"),
    ("MiniMax", "#EB3568"), ("Inkling", "#7F4BF3"),
]
LEG_Y = 1086
text(56, LEG_Y - 8, "Bar color = model provider", 12, "#555555", 600)
for i, (name, color) in enumerate(PROVIDERS):
    col, row = i % 6, i // 6
    x, y = 56 + col * 190, LEG_Y + row * 30
    parts.append(f'<rect x="{x}" y="{y + 3}" width="10" height="10" rx="2" fill="{color}"/>')
    text(x + 18, y + 12, name, 12, "#444444")

# Footer
text(56, H - 40,
     "Source: artificialanalysis.ai/models · Retrieved 14 Sep 2026 · Top 20 models by Intelligence Index v4.3 · "
     "Provider colors approximated from brand palette — fully editable.", 11, "#9A9A9A")

parts.append("</svg>")
svg = "\n".join(parts)
out = "/Users/clausmedvesek/Developer/projects/food-pal/aa_intelligence_index.svg"
with open(out, "w", encoding="utf-8") as f:
    f.write(svg)
print(out, len(svg), "bytes")
