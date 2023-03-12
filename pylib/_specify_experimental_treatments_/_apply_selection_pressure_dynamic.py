import typing


def apply_selection_pressure_dynamic(params: typing.Dict) -> typing.Dict:
    return {
        **params,
        **{
            "tournament_size": 4,
        },
    }
