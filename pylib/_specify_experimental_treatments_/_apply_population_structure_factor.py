import typing


def apply_population_structure_factor(params: typing.Dict) -> typing.Dict:
    return {
        **params,
        **{
            "num_islands": 1024,
        },
    }
