# https://cran.r-project.org/web/packages/gen3sis/vignettes/create_config.html
# Version: 1.0
# Author:
# Date:
# Landscape:
# Publications:
# Description:

# SETTINGS ####################################################################
# set the random seed for the simulation.
random_seed = as.integer(Sys.getenv('RNG_SEED'))
# set the starting time step or leave NA to use the earliest/highest time-step.
start_time = 30
# set the end time step or leave as NA to use the latest/lowest time-step (0).
end_time = NA
# maximum total number of species in the simulation before it is aborted.
max_number_of_species = 25000
# maximum number of species within one cell before the simulation is aborted.
max_number_of_coexisting_species = 2500
# a list of traits to include with each species.
# a "dispersal" trait is implicitly added in any case.
trait_names = c("temp", "dispersal")
# ranges to scale the input environments with:
# not listed variable:         no scaling takes place
# listed, set to NA:           env. variable will be scaled from [min, max] to [0, 1]
# listed with a given range r: env. variable will be scaled from [r1, r2] to [0, 1]
environmental_ranges = list("temp" = c(-45, 55), "area"=c(2361.5, 12923.4),
   "arid"=c(1,0.5))


# OBSERVER ####################################################################
end_of_timestep_observer = function(data, vars, config){
 # the list of all species can be found in data$all_species.
 # the current landscape can be found in data$landscape.
}

# INITIALIZATION ##############################################################
# the initial abundance of a newly colonized cell, both during setup and later when colonizing a cell during the dispersal
initial_abundance = 1

# adapted from https://github.com/project-gen3sis/Simulations/blob/8ce6b88a6cd388f4cb4d963bb807ef91633385c6/config/SouthAmerica/config_southamerica.R#L77
#defines the initial species traits and ranges
#place species within rectangle, our case entire globe
create_ancestor_species <- function(landscape, config) {
  range <- c(-95, -24, -68, 13)
  co <- landscape$coordinates
  selection <- co[, "x"] >= range[1] &
    co[, "x"] <= range[2] &
    co[, "y"] >= range[3] &
    co[, "y"] <= range[4]

  new_species <- list()
  for(i in 1:10){
    initial_cells <- rownames(co)[selection]
    initial_cells <- sample(initial_cells, 1)
    new_species[[i]] <- create_species(initial_cells, config)
    #set local adaptation to max optimal temp equals local temp
    new_species[[i]]$traits[ , "temp"] <- landscape$environment[initial_cells,"temp"]
    new_species[[i]]$traits[ , "dispersal"] <- 1
    #plot_species_presence(landscape, species=new_species[[i]])
  }

  return(new_species)
}


# DIVERGENCE ##################################################################
divergence_threshold = 2
get_divergence_factor <- function(species, cluster_indices, landscape, config) {
 return(1)
 }
