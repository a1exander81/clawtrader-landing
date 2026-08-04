#!/usr/bin/env bash
# apply_chart_stage2_polish.sh
# U-CHART-STAGE2-POLISH-20260726 -- direction-coloring polish on the chart page.
# (R:R header chip was already shipped in Stage 1 -- nothing to do there.)
#
# Edits chart.html (clawtrader-landing):
#   - #chart-wrap gets a subtle border tint matching LONG/SHORT
#   - Entry price line tints green/red-ish by direction instead of flat white
#
# Usage:
#   cd /Users/alex/Desktop/my-ai-assistant/clawtrader-landing
#   bash apply_chart_stage2_polish.sh           # DRYRUN (default)
#   APPLY=1 bash apply_chart_stage2_polish.sh   # actually writes

set -euo pipefail

DRYRUN=1
if [[ "${APPLY:-0}" == "1" ]]; then
  DRYRUN=0
fi

python3 - "$DRYRUN" << 'PYINNER'
import sys, json, base64, shutil, datetime, os

dryrun = sys.argv[1] == "1"
plan_b64 = "W1siY2hhcnQuaHRtbCIsIFtbIiAgI2NoYXJ0LXdyYXAge1xuICAgIG1hcmdpbi10b3A6IDE2cHg7XG4gICAgd2lkdGg6IDEwMCU7XG4gICAgaGVpZ2h0OiA0MjBweDtcbiAgICBib3JkZXI6IDFweCBzb2xpZCB2YXIoLS1wYW5lbC1ib3JkZXIpO1xuICAgIGJvcmRlci1yYWRpdXM6IDE0cHg7XG4gICAgb3ZlcmZsb3c6IGhpZGRlbjtcbiAgICBiYWNrZ3JvdW5kOiB2YXIoLS1wYW5lbCk7XG4gICAgcG9zaXRpb246IHJlbGF0aXZlO1xuICB9IiwgIiAgI2NoYXJ0LXdyYXAge1xuICAgIG1hcmdpbi10b3A6IDE2cHg7XG4gICAgd2lkdGg6IDEwMCU7XG4gICAgaGVpZ2h0OiA0MjBweDtcbiAgICBib3JkZXI6IDFweCBzb2xpZCB2YXIoLS1wYW5lbC1ib3JkZXIpO1xuICAgIGJvcmRlci1yYWRpdXM6IDE0cHg7XG4gICAgb3ZlcmZsb3c6IGhpZGRlbjtcbiAgICBiYWNrZ3JvdW5kOiB2YXIoLS1wYW5lbCk7XG4gICAgcG9zaXRpb246IHJlbGF0aXZlO1xuICB9XG4gICNjaGFydC13cmFwLmFjY2VudC1sb25nIHsgYm9yZGVyLWNvbG9yOiByZ2JhKDQzLCAyMTMsIDExOCwgMC40KTsgfVxuICAjY2hhcnQtd3JhcC5hY2NlbnQtc2hvcnQgeyBib3JkZXItY29sb3I6IHJnYmEoMjU1LCA3MSwgODcsIDAuNCk7IH0iXSwgWyIgIGlmIChkaXIgPT09ICdMT05HJyB8fCBkaXIgPT09ICdTSE9SVCcpIHtcbiAgICBjb25zdCBiYWRnZSA9IGVscygnZGlyQmFkZ2UnKTtcbiAgICBiYWRnZS50ZXh0Q29udGVudCA9IGRpcjtcbiAgICBiYWRnZS5jbGFzc05hbWUgPSAnZGlyLWJhZGdlICcgKyBkaXIudG9Mb3dlckNhc2UoKTtcbiAgfSIsICIgIGlmIChkaXIgPT09ICdMT05HJyB8fCBkaXIgPT09ICdTSE9SVCcpIHtcbiAgICBjb25zdCBiYWRnZSA9IGVscygnZGlyQmFkZ2UnKTtcbiAgICBiYWRnZS50ZXh0Q29udGVudCA9IGRpcjtcbiAgICBiYWRnZS5jbGFzc05hbWUgPSAnZGlyLWJhZGdlICcgKyBkaXIudG9Mb3dlckNhc2UoKTtcbiAgICBlbHMoJ2NoYXJ0LXdyYXAnKS5jbGFzc0xpc3QuYWRkKCdhY2NlbnQtJyArIGRpci50b0xvd2VyQ2FzZSgpKTtcbiAgfSJdLCBbIiAgICBzZXJpZXMuY3JlYXRlUHJpY2VMaW5lKHtcbiAgICAgIHByaWNlOiBlbnRyeSwgY29sb3I6ICcjRjJGMEVDJywgbGluZVdpZHRoOiAxLFxuICAgICAgbGluZVN0eWxlOiBMaWdodHdlaWdodENoYXJ0cy5MaW5lU3R5bGUuRGFzaGVkLCBheGlzTGFiZWxWaXNpYmxlOiB0cnVlLCB0aXRsZTogJ0VudHJ5JyxcbiAgICB9KTsiLCAiICAgIGNvbnN0IGVudHJ5Q29sb3IgPSBkaXIgPT09ICdMT05HJyA/ICcjOUZFOEMwJyA6IGRpciA9PT0gJ1NIT1JUJyA/ICcjRkZCM0IzJyA6ICcjRjJGMEVDJztcbiAgICBzZXJpZXMuY3JlYXRlUHJpY2VMaW5lKHtcbiAgICAgIHByaWNlOiBlbnRyeSwgY29sb3I6IGVudHJ5Q29sb3IsIGxpbmVXaWR0aDogMSxcbiAgICAgIGxpbmVTdHlsZTogTGlnaHR3ZWlnaHRDaGFydHMuTGluZVN0eWxlLkRhc2hlZCwgYXhpc0xhYmVsVmlzaWJsZTogdHJ1ZSwgdGl0bGU6ICdFbnRyeScsXG4gICAgfSk7Il1dXV0="
plan = json.loads(base64.b64decode(plan_b64).decode())  # plan already contains raw old/new strings

ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
touched = []
errors = []

print("== " + ("DRYRUN" if dryrun else "APPLY") + " ==")

for path, pairs in plan:
    if not os.path.isfile(path):
        errors.append(path + ": file not found")
        continue
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    file_ok = True
    any_new_edit = False
    for old, new in pairs:
        # Check "already applied" FIRST -- some edits append to the anchor
        # (new contains old as a prefix), so old can still appear inside an
        # already-patched file. Testing for new's presence up front avoids
        # re-applying (and duplicating) an append-style edit.
        if new in content:
            print("  " + path + ": already applied -- skip -- " + repr(new[:50]) + "...")
            continue
        old_count = content.count(old)
        if old_count == 1:
            content = content.replace(old, new, 1)
            any_new_edit = True
            print("  " + path + ": anchor OK (1 match) -- " + repr(old[:50]) + "...")
        elif old_count == 0:
            print("  ABORT " + path + ": anchor NOT FOUND -- " + repr(old[:60]) + "...")
            errors.append(path + ": anchor not found")
            file_ok = False
        else:
            print("  ABORT " + path + ": anchor matched " + str(old_count) + " times -- " + repr(old[:60]) + "...")
            errors.append(path + ": anchor matched " + str(old_count) + " times")
            file_ok = False

    if not file_ok:
        continue
    if not any_new_edit:
        print("  SKIP " + path + ": already fully applied (no-op)")
        continue
    if dryrun:
        print("  DRYRUN would write: " + path)
        continue

    backup = path + ".bak.pre-u-chart-stage2-polish-" + ts
    shutil.copy2(path, backup)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    touched.append((path, backup))
    print("  WROTE " + path + " (backup: " + backup + ")")

if errors:
    print("---")
    print("ERRORS -- restoring:")
    for e in errors:
        print("  - " + e)
    for path, backup in touched:
        shutil.copy2(backup, path)
        print("  restored " + path)
    sys.exit(1)

if dryrun:
    print("---")
    print("DRYRUN clean. Re-run with APPLY=1 to write.")
else:
    print("---")
    print("Done. Review with: git status && git diff --stat")
PYINNER
