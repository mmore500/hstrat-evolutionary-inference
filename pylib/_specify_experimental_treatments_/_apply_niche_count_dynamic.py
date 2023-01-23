import typing


def apply_niche_count_dynamic(params: typing.Dict) -> typing.Dict:
    return {
        **params,
        **{
            "num_niches": 8,
        },
    }
