import pandas as pd

from ._specify_experimental_treatments import specify_experimental_treatments

num_replicates = 50


def specify_template_phylogeny_generation_replicates() -> pd.DataFrame:

    df_treatments = specify_experimental_treatments()

    # filter out duplicate configurations
    df_unique = (
        df_treatments[
            set(df_treatments.columns)
            - {
                "Evolutionary Dynamic",
                "Evolutionary Dynamic Active",
                "Nuissance Factor",
                "Nuissance Factor Active",
            }
        ]
        .drop_duplicates()
        .reset_index(drop=True)
    )

    df_unique["treatment"] = df_unique.index

    # replicate configurations
    df_replicates = pd.concat(
        [
            df_unique.assign(replicate=replicate)
            for replicate in range(num_replicates)
        ],
        ignore_index=True,
    )

    return df_replicates
