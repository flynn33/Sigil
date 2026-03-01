import math
from scripts import plane


def approx_eq(a, b, eps=1e-6):
    return abs(a - b) <= eps


def test_example_given():
    s = {'C': 0.48, 'S': 0.32, 'P': 0.21, 'H': 0.55}
    score = plane.compute_score(s)
    assert approx_eq(score, 1.46, eps=1e-3)

    base = plane.compute_base_plane_from_s(s)
    assert base == 4

    # Kripke enforcement: cannot jump from 1 -> 4 in one tick
    enforced = plane.enforce_kripke(1, base)
    assert enforced == 2


def test_bounds_min_max():
    # minimal score: all zeros -> score = 0 + 0 + 0 + (1 - 0) = 1 -> check mapping
    s_min = {'C': 0.0, 'S': 0.0, 'P': 0.0, 'H': 1.0}
    score_min = plane.compute_score(s_min)
    assert approx_eq(score_min, 0.0 + 0.0 + 0.0 + (1 - 1.0))
    assert plane.compute_base_plane_from_s(s_min) == 1

    # maximal structural bias: C=S=P=1, H=0 -> score = 4 -> maps to plane 9
    s_max = {'C': 1.0, 'S': 1.0, 'P': 1.0, 'H': 0.0}
    assert plane.compute_score(s_max) == 4.0
    assert plane.compute_base_plane_from_s(s_max) == 9


def test_enforce_kripke_noop():
    # adjacent movement allowed
    assert plane.enforce_kripke(3, 4) == 4
    assert plane.enforce_kripke(3, 2) == 2

def test_kripke_multi_step_snap():
    # Test snapping for larger jumps
    assert plane.enforce_kripke(3, 7) == 4  # Upward snap
    assert plane.enforce_kripke(5, 1) == 4  # Downward snap
    assert plane.enforce_kripke(1, 9) == 2  # Max upward from bottom
    assert plane.enforce_kripke(9, 1) == 8  # Max downward from top
    assert plane.enforce_kripke(4, 4) == 4  # No change
    assert plane.enforce_kripke(4, 5) == 5  # Adjacent up
    assert plane.enforce_kripke(4, 3) == 3  # Adjacent down
