"""Reglas de jugabilidad para el pad fisico.

El Arduino ignora un pad durante 1 segundo despues de un golpe, asi que ningun
carril puede repetirse en menos de ese tiempo. Esta regla reasigna la nota a
otro carril libre y, si no hay ninguno, la descarta.

Uso:  py -3 tools/chart_rules.py levels/mi_chart.json [mas charts...]
"""

import json
import sys

MIN_LANE_GAP = 1.0
LANES = 4


def enforce_lane_gap(notes, gap=MIN_LANE_GAP):
    """Devuelve (notas_corregidas, movidas, descartadas)."""
    ordered = sorted(notes, key=lambda n: (n["time"], n["lane"]))
    last_use = [-999.0] * LANES
    result = []
    moved = dropped = 0
    index = 0
    while index < len(ordered):
        # notas que suenan a la vez (acordes) se procesan como grupo
        group = [ordered[index]]
        while index + len(group) < len(ordered) and abs(ordered[index + len(group)]["time"] - group[0]["time"]) < 1e-4:
            group.append(ordered[index + len(group)])
        index += len(group)
        used_now = set()
        for note in group:
            t = note["time"]
            lane = note["lane"]
            free = [l for l in range(LANES) if l not in used_now and t - last_use[l] >= gap - 1e-6]
            if lane in free:
                chosen = lane
            elif free:
                chosen = min(free, key=lambda l: (abs(l - lane), last_use[l]))
                moved += 1
            else:
                dropped += 1
                continue
            used_now.add(chosen)
            last_use[chosen] = t
            result.append({"time": note["time"], "lane": chosen})
    return result, moved, dropped


def min_same_lane_gap(notes):
    last = {}
    best = 999.0
    for note in sorted(notes, key=lambda n: n["time"]):
        lane = note["lane"]
        if lane in last:
            best = min(best, note["time"] - last[lane])
        last[lane] = note["time"]
    return best


def main():
    for path in sys.argv[1:]:
        with open(path, encoding="utf-8") as f:
            notes = json.load(f)
        fixed, moved, dropped = enforce_lane_gap(notes)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(fixed, f)
        print("%s: %d -> %d notas (%d movidas, %d descartadas), repeticion minima %.2f s"
              % (path, len(notes), len(fixed), moved, dropped, min_same_lane_gap(fixed)))


if __name__ == "__main__":
    main()
