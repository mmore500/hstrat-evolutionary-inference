import typing

from cliffs_delta import cliffs_delta
from scipy import stats as scipy_stats


def describe_effect(
    x: typing.Sequence[float], y: typing.Sequence[float]
) -> str:
    """Compare two groups of scalar data and return a description of the
    significance and size of the difference between them."""
    description = []

    _u, p = scipy_stats.mannwhitneyu(x, y)
    description.append(
        {
            True: "*",
            False: "",
        }[p < 0.05],
    )

    d, res = cliffs_delta(x, y)
    description.append(
        {
            "negligible": "",
            "small": "+",
            "medium": "++",
            "large": "+++",
        }[res],
    )

    return "".join(description)
