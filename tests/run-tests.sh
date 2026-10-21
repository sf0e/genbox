#!/bin/bash
# genbox test suite (no root required for the syntax and output tests).
set -u

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(dirname "$here")"
fail=0

say() { printf '\n== %s\n' "$*"; }
ok()  { printf 'ok   %s\n' "$*"; }
bad() { printf 'FAIL %s\n' "$*"; fail=$((fail + 1)); }

say "shell syntax"
while IFS= read -r f; do
    case "$f" in
        */Manifest|*.tar.gz) continue ;;
    esac
    if bash -n "$f" 2>/dev/null; then
        ok "$f"
    else
        bad "$f"
    fi
done < <(find "$repo/overlay/sys-apps/genbox-init/files" "$repo/scripts" "$repo/installer" -type f 2>/dev/null)

say "e* output conformance"
fn="$repo/overlay/sys-apps/genbox-init/files/functions.sh"
out="$(sh -c ". '$fn'; ebegin 'Starting foo'; eend 0" 2>/dev/null)"
expected=' * Starting foo ... [ ok ]'
if [ "$out" = "$expected" ]; then
    ok "ebegin/eend success"
else
    bad "ebegin/eend success (got: $out)"
fi

out="$(sh -c ". '$fn'; einfo 'hello world'" 2>/dev/null)"
expected=' * hello world'
if [ "$out" = "$expected" ]; then
    ok "einfo"
else
    bad "einfo (got: $out)"
fi

say "CLI contract"
if sh -c "'$repo/overlay/sys-apps/genbox-init/files/openrc-run'" 2>&1 | grep -q 'should not be run directly'; then
    ok "openrc-run rejects direct use"
else
    bad "openrc-run rejects direct use"
fi

say "documentation"
for d in INSTALL.md FIRST-BOOT.md EDITING-MAKE-CONF.md MAKE-CONF-REFERENCE.md SERVICES.md BOOT.md ARCHITECTURE.md FAQ.md TROUBLESHOOTING.md GLOSSARY.md; do
    if [ -s "$repo/docs/$d" ]; then ok "docs/$d"; else bad "docs/$d missing"; fi
done

say "installer assets"
[ -s "$repo/installer/make.conf" ] && ok "installer/make.conf" || bad "installer/make.conf"
[ -x "$repo/installer/genbox-installer" ] && ok "installer/genbox-installer" || bad "installer/genbox-installer"

printf '\n'
if [ "$fail" -eq 0 ]; then
    echo "all tests passed"
    exit 0
fi
echo "$fail test(s) failed"
exit 1
