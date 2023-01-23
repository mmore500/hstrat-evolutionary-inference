import typing


def apply_ecology_factor(params: typing.Dict) -> typing.Dict:
    return {
        **params,
        **{
            "num_niches": 4,
        },
    }
