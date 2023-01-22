import typing


def apply_niche_stability_dynamic(
    params: typing.Dict, population_size: int
) -> typing.Dict:
    return {
        **params,
        **{
            "p_niche_invasion": 1 / (population_size * 10),
        },
    }
