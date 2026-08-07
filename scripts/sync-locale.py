#!/usr/bin/env python3
"""index.html -> tw/index.html 로케일 사본 생성.

루트 index.html이 정본이다. 이 스크립트로만 tw/ 를 갱신할 것 —
tw/index.html을 직접 고치면 다음 실행 때 덮어써진다.
"""
import re, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
LOCALES = {
    "tw": {
        "htmlLang": "zh-Hant",
        "title": "Recipe Cocy — 正在紅的話題食譜",
        "desc": "從杜拜巧克力到韓式泡菜鍋，網路上正紅的話題食譜總整理。份量自動換算、分段計時器、語音控制，完全免費。",
    },
}

def build(code, meta):
    s = (ROOT / "index.html").read_text(encoding="utf-8")
    s = s.replace('<html lang="ko">', f'<html lang="{meta["htmlLang"]}">', 1)
    # 데이터/정적 자산은 한 단계 위
    s = re.sub(r'`recipes(\.[a-z]+)?\.json\?v=', lambda m: '`../recipes%s.json?v=' % (m.group(1) or ''), s)
    for asset in ("manifest.webmanifest", "icon.svg", "images/"):
        s = s.replace(f'"{asset}', f'"../{asset}').replace(f"'{asset}", f"'../{asset}")
    # 로케일 고정
    s = s.replace('const FORCE_LANG = null;', f'const FORCE_LANG = "{code}";', 1)
    s = s.replace('const SITE_BASE = "https://recipe.cocy.io/";',
                  f'const SITE_BASE = "https://recipe.cocy.io/{code}/";', 1)
    # 서비스워커는 루트 스코프라 사본에서 등록하지 않는다
    s = s.replace('navigator.serviceWorker.register("./service-worker.js").catch(() => {});',
                  '/* locale copy: service worker는 루트에서만 등록 */', 1)
    # head 기본값
    s = re.sub(r'<title>[^<]*</title>', f'<title>{meta["title"]}</title>', s, count=1)
    s = re.sub(r'(<meta id="meta-description" name="description" content=")[^"]*(")',
               lambda m: m.group(1) + meta["desc"] + m.group(2), s, count=1)
    s = re.sub(r'(<link id="canonical-link" rel="canonical" href=")[^"]*(")',
               lambda m: m.group(1) + f"https://recipe.cocy.io/{code}/" + m.group(2), s, count=1)
    out = ROOT / code
    out.mkdir(exist_ok=True)
    (out / "index.html").write_text(s, encoding="utf-8")
    return out / "index.html"

if __name__ == "__main__":
    for code, meta in LOCALES.items():
        p = build(code, meta)
        print("wrote", p.relative_to(ROOT), p.stat().st_size, "bytes")
