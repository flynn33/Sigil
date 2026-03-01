"""Plane calculation utilities for Yggdrasil Engine.

Provides deterministic mapping from structural vector `s` to base plane (1..9)
and Kripke ladder enforcement helpers used by unit tests and gameplay code.
"""
from typing import Mapping, Sequence, Union
import math


def clamp(v: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, v))


def compute_score(s: Union[Mapping[str, float], Sequence[float]]) -> float:
    """Compute score = C + S + P + (1 - H).

    Accepts either a mapping with keys 'C','S','P','H' or a sequence [C,S,P,H].
    """
    if hasattr(s, 'get'):
        C = float(s.get('C', 0.0))
        S = float(s.get('S', 0.0))
        P = float(s.get('P', 0.0))
        H = float(s.get('H', 0.0))
    else:
        C, S, P, H = (float(x) for x in s)

    return C + S + P + (1.0 - H)


def base_plane_from_score(score: float) -> int:
    """Map score to base plane using the canonical formula."""
    base_plane = math.floor(score * 2.25) + 1
    return int(clamp(base_plane, 1, 9))


def compute_base_plane_from_s(s: Union[Mapping[str, float], Sequence[float]]) -> int:
    return base_plane_from_score(compute_score(s))


def enforce_kripke(current_plane: int, proposed_plane: int) -> int:
    """Enforce |current - proposed| <= 1 by snapping at most one step toward target."""
    if abs(proposed_plane - current_plane) > 1:
        step = 1 if proposed_plane > current_plane else -1
        return current_plane + step
    return proposed_plane


__all__ = [
    'compute_score',
    'base_plane_from_score',
    'compute_base_plane_from_s',
    'enforce_kripke',
    'clamp',
]
