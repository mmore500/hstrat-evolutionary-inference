from pylib import describe_effect


def test_describe_effect_negligible():
    assert describe_effect([1, 2, 3, 4], [1, 2, 3, 4]) == ""


def test_describe_effect_big():
    assert describe_effect([*range(100)], [*range(100, 200)]) == "*+++"
