import typing


def apply_selection_drift_dynamic(params: typing.Dict) -> typing.Dict:
    return {
        **params,
        **{
            "tournament_size": 1,
        },
    }
