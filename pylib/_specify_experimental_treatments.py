import itertools as it
import types

import pandas as pd

from ._specify_experimental_treatments_ import *

population_size = 32768

base_params = types.MappingProxyType(
    {
        "population_size": population_size,
        "p_niche_invasion": 1 / (population_size * 1000),
        "p_island_migration": 0.01,
        "tournament_size": 2,
        "num_islands": 1,
        "num_generations": population_size,
    }
)
nonecological_base_params = types.MappingProxyType(
    {
        **base_params,
        **{
            "num_niches": 1,
        },
    }
)
ecological_base_params = types.MappingProxyType(
    {
        **base_params,
        **{
            "num_niches": 4,
        },
    }
)


def specify_experimental_treatments() -> pd.DataFrame:
    records = []

    evolutionary_dynamic_name = "Selection Pressure"
    for (
        (dynamic_name, dynamic_base_params, apply_dynamic),
        dynamic_active,
        (factor_name, apply_factor),
        factor_active,
        mut_distn,
    ) in it.product(
        (
            (
                "Selection Pressure",
                nonecological_base_params,
                apply_selection_pressure_dynamic,
            ),
            (
                "Selection Drift",
                nonecological_base_params,
                apply_selection_drift_dynamic,
            ),
            ("Niche Count", ecological_base_params, apply_niche_count_dynamic),
            (
                "Niche Stability",
                ecological_base_params,
                lambda x: apply_niche_stability_dynamic(x, population_size),
            ),
        ),
        (True, False),
        (
            ("Population Structure", apply_population_structure_factor),
            ("Tree Subsampling", apply_tree_subsampling_factor),
            ("Tree Reconstruction", apply_tree_reconstruction_factor),
            ("Ecology", apply_ecology_factor),
        ),
        (True, False),
        ("np.random.standard_normal", "np.random.exponential"),
    ):

        if (dynamic_name, factor_name) in (
            ("Niche Count", "Ecology"),
            ("Niche Stability", "Ecology"),
            ("Selection Pressure", "Selection Pressure"),
        ):
            continue

        params = dynamic_base_params
        if dynamic_active:
            params = apply_dynamic(params)
        if factor_active:
            params = apply_factor(params)

        record = {
            **{
                "Evolutionary Dynamic": dynamic_name,
                "Evolutionary Dynamic Active": dynamic_active,
                "Nuissance Factor": factor_name,
                "Nuissance Factor Active": factor_active,
                "mut_distn": mut_distn,
            },
            **params,
        }
        records.append(record)

    return pd.DataFrame.from_records(records)
