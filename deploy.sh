#!/bin/sh
# Haalt nieuwe versies van wittesneakers.com op bij GitHub en zet ze op de site.
# Draait elke 5 minuten via een cronjob in DirectAdmin.
#
# Waarom: sinds 16 november 2026 kan GitHub deze server niet meer bereiken.
# Daarom haalt de server het nu zelf op. Zie publiceer.py in wittesneakers-bot.
#
# De cronjob haalt dit script op via een VASTE commit (niet via 'main'), zodat
# wat er op de server draait niet stilletjes kan veranderen. Wijzig je dit
# script, dan moet de cronregel naar de nieuwe commit wijzen.
#
# Verwijdert nooit iets, laat de .htaccess in de webroot met rust en neemt
# geen PHP-bestanden over. Alles wat er gebeurt komt in ~/site-deploy.log.

exec >> "$HOME/site-deploy.log" 2>&1
cd "$HOME" || exit 1

REPO=hveeuwen/wittesneakers-site
WEBMAP="$HOME/domains/wittesneakers.com/public_html"

# Snelle check: is er een nieuwe versie? Zo niet, dan meteen stoppen.
# curl, met wget als terugval voor het geval curl ontbreekt.
haal() { curl -fsSL --max-time 180 "$1" 2>/dev/null || wget -qO- --timeout=180 "$1"; }

nieuw=$(haal "https://raw.githubusercontent.com/$REPO/main/versie.txt") || exit 0
[ -n "$nieuw" ] || exit 0
[ "$nieuw" = "$(cat .site-versie 2>/dev/null)" ] && exit 0

rm -rf .site-tmp && mkdir .site-tmp || exit 1
PAKKET="https://codeload.github.com/$REPO/tar.gz/refs/heads/main"
if haal "$PAKKET" | tar xz -C .site-tmp --strip-components=1; then
    rm -f .site-tmp/README.md .site-tmp/.htaccess .site-tmp/deploy.sh
    find .site-tmp -iname '*.php' -delete
    if cp -R .site-tmp/. "$WEBMAP"/; then
        # De versie uit het gedownloade pakket zelf, zodat versie en inhoud
        # altijd bij elkaar horen.
        cat .site-tmp/versie.txt > .site-versie
        echo "$(date) gepubliceerd: $(cat .site-versie)"
    else
        echo "$(date) KOPIEREN MISLUKT"
    fi
else
    echo "$(date) OPHALEN MISLUKT"
fi
rm -rf .site-tmp
