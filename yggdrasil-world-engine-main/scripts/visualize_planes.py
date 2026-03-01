#!/usr/bin/env python3
"""Generate and save a histogram of base_plane distribution.

Usage:
  python3 scripts/visualize_planes.py --n 5000 --out out/plane_hist.png

Optional: provide `--canonical` to include mapped entries from
`data/cosmology/canonical-pattern-vectors.json` (heuristic mapping).
"""
import argparse
import json
import os
import random
from typing import List

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

from scripts.plane import compute_base_plane_from_s


def sample_random_s(n: int):
    return np.random.rand(n, 4)  # columns: C,S,P,H


def map_canonical_to_s(entry: dict):
    # Heuristic mapping from canonical pattern vector to structural s
    vec = entry.get('vector', {})
    H = float(vec.get('H_entropy', vec.get('H', 0.5)))
    S = float(vec.get('S_symmetry', vec.get('S', 0.5)))
    K = float(vec.get('K_complexity', vec.get('K', 0.5)))
    D = float(vec.get('D_fractal_dim', vec.get('D', 2.0)))

    # heuristics: compressibility ~ 1 - complexity; persistence ~ normalized fractal dim
    C = max(0.0, min(1.0, 1.0 - K))
    P = max(0.0, min(1.0, (D - 1.0) / 2.0))
    return [C, S, P, H]


def compute_planes_from_array(arr):
    planes = []
    for row in arr:
        s = {'C': float(row[0]), 'S': float(row[1]), 'P': float(row[2]), 'H': float(row[3])}
        planes.append(compute_base_plane_from_s(s))
    return planes


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--n', type=int, default=5000)
    p.add_argument('--out', type=str, default='out/plane_hist.png')
    p.add_argument('--canonical', action='store_true', help='Include canonical-pattern-vectors.json mapped entries')
    args = p.parse_args()

    rnd = sample_random_s(args.n)
    rnd_planes = compute_planes_from_array(rnd)

    planes_all = rnd_planes.copy()

    labels = ['random']

    if args.canonical:
        path = os.path.join('data', 'cosmology', 'canonical-pattern-vectors.json')
        try:
            with open(path, 'r', encoding='utf-8') as f:
                canon = json.load(f)
        except Exception as e:
            print('Failed to load canonical file:', e)
            canon = None

        if canon:
            mapped = [map_canonical_to_s(e) for e in canon.get('entities', [])]
            canon_planes = compute_planes_from_array(mapped)
            planes_all.extend(canon_planes)
            labels.append('canonical')

    # histogram
    counts, bins = np.histogram(planes_all, bins=np.arange(1, 11) - 0.5)

    os.makedirs(os.path.dirname(args.out) or '.', exist_ok=True)
    fig, ax = plt.subplots(figsize=(8, 4))
    ax.bar(range(1, 10), counts, align='center', color='C0')
    ax.set_xlabel('Base Plane (1..9)')
    ax.set_ylabel('Count')
    ax.set_title(f'Base Plane Distribution (n={args.n}{" + canonical" if args.canonical else ""})')
    ax.set_xticks(range(1, 10))
    ax.set_xlim(0.5, 9.5)
    plt.tight_layout()
    plt.savefig(args.out)
    print('Saved histogram to', args.out)


if __name__ == '__main__':
    main()
