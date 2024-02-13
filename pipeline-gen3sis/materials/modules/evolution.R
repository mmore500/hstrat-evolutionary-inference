# mutate the traits of a species and return the new traits matrix
# adapted from https://cran.r-project.org/web/packages/gen3sis/vignettes/create_config.html
apply_evolution <- function(species, cluster_indices, landscape, config) {
 trait_evolutionary_power <- 0.001
 traits <- species[["traits"]]
 cells <- rownames(traits)
 #homogenize trait based on abundance
 for(cluster_index in unique(cluster_indices)){
   cells_cluster <- cells[which(cluster_indices == cluster_index)]
   mean_abd <- mean(species$abundance[cells_cluster])
   weight_abd <- species$abundance[cells_cluster]/mean_abd
   traits[cells_cluster, "temp"] <- mean(traits[cells_cluster, "temp"]*weight_abd)
 }
 #mutations
 mutation_deltas <-rnorm(length(traits[, "temp"]), mean=0, sd=trait_evolutionary_power)
 traits[, "temp"] <- traits[, "temp"] + mutation_deltas
 return(traits)
}
