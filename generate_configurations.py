import itertools as it

import pandas as pd


population_size = 32768

base_params = {
    "population_size": population_size,
    "p_niche_invasion": 1 / (population_size * 1000),
    "p_island_migration": 0.01,
    "tournament_size": 2,
    "num_islands": 1,
}

nonecological_base_params = {
    **base_params,
    **{
        "num_niches": 1,
    }
}
ecological_base_params = {
    **base_params,
    **{
        "num_niches": 4,
    }
}

def apply_selection_pressure_dynamic(params):
    return {
        **params,
        **{
            "tournament_size": 8,
        }
    }

def apply_niche_stability_dynamic(params):
    return {
        **params,
        **{
            "p_niche_invasion": 1 / (population_size * 10),
        }
    }

def apply_niche_count_dynamic(params):
    return {
        **params,
        **{
            "num_niches": 8,
        }
    }

def apply_population_structure_factor(params):
    return {
        **params,
        **{
            "num_islands": 1024,
        }
    }

def apply_tree_subsampling_factor(params):
    return params

def apply_tree_reconstruction_factor(params):
    return params

def apply_ecology_factor(params):
    return {
        **params,
        **{
            "num_niches": 4,
        }
    }

def apply_selection_pressure_factor(params):
    return {
        **params,
        **{
            "tournament_size": 8,
        }
    }


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
            apply_selection_pressure_dynamic
        ),
        (
            "Niche Count",
            ecological_base_params,
            apply_niche_count_dynamic
        ),
        (
            "Niche Stability",
            ecological_base_params,
            apply_niche_stability_dynamic
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
            "Evolutionary Dynamic" : dynamic_name,
            "Evolutionary Dynamic Active" : dynamic_active,
            "Nuissance Factor" : factor_name,
            "Nuissance Factor Active" : factor_active,
            "mut_distn" : mut_distn,
        },
        **params,
    }
    records.append(record)

df = pd.DataFrame.from_records(records)

print(df)

df_unique = df[
    set(df.columns) - {
        "Evolutionary Dynamic",
        "Evolutionary Dynamic Active",
        "Nuissance Factor",
        "Nuissance Factor Active",
    }
].drop_duplicates().reset_index(drop=True)

print(df_unique)
