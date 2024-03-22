get_dispersal_values <- function(n, species, landscape, config) {
 values <- rweibull(n, shape = 1.5, scale = 133)
 return(values)
}
