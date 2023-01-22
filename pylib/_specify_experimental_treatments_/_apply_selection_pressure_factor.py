import typing


def apply_selection_pressure_factor(params: typing.Dict) -> typing.Dict:
    return {
        **params,
        **{
            "tournament_size": 8,
        },
    }
