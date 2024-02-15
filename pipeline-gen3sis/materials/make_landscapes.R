# Load the required packages
library(gen3sis)
library(raster)

set.seed(1)

# Set the working directory to the downloaded data
temperature_brick <- brick("Simulations/input_rasters/SouthAmerica/temperature_rasters.grd")
aridity_brick <- brick("Simulations/input_rasters/SouthAmerica/aridity_rasters.grd")
area_brick <- brick("Simulations/input_rasters/SouthAmerica/area_rasters.grd")

# Modify bricks to replicate the first time step across all time steps
set_all_timesteps_to_first <- function(brick) {
  first_layer <- brick[[1]]  # Extract the first layer
  replicated_layers <- replicate(nlayers(brick), first_layer)
  return(brick(stack(replicated_layers)))
}

# Apply the modification to each brick
temperature_brick <- set_all_timesteps_to_first(temperature_brick)
aridity_brick <- set_all_timesteps_to_first(aridity_brick)
area_brick <- set_all_timesteps_to_first(area_brick)

# Function to generate coordinates for a single strip
generate_strip_coords <- function(raster, strip_length) {
  nrows <- nrow(raster)
  ncols <- ncol(raster)

  # Random starting point
  start_row <- sample(1:nrows, 1)
  start_col <- sample(1:ncols, 1)

  # Random orientation (angle in radians)
  angle <- runif(1, 0, 2 * pi)

  # Calculate row and column offsets based on angle
  row_offsets <- round(sin(angle) * (0:(strip_length - 1)))
  col_offsets <- round(cos(angle) * (0:(strip_length - 1)))

  # Calculate the row and column indices for the strip
  strip_rows <- start_row + row_offsets
  strip_cols <- start_col + col_offsets

  # Ensure the indices are within the raster extent
  valid_indices <- strip_rows > 0 & strip_rows <= nrows & strip_cols > 0 & strip_cols <= ncols
  strip_rows <- strip_rows[valid_indices]
  strip_cols <- strip_cols[valid_indices]

  return(list(rows = strip_rows, cols = strip_cols))
}

# Function to apply strips to a raster brick
apply_strips_to_brick <- function(brick, strips) {
  for (strip in strips) {
    # Convert row and column indices to cell numbers
    strip_cells <- cellFromRowCol(brick, strip$rows, strip$cols)
    # Set the values of these cells to NA
    brick[strip_cells] <- NA
  }
  return(brick)
}

# Generate 30 strips coordinates
strips <- lapply(1:30, function(x) generate_strip_coords(temperature_brick, 20))

# Apply the same strips to each brick
temperature_brick <- apply_strips_to_brick(temperature_brick, strips)
aridity_brick <- apply_strips_to_brick(aridity_brick, strips)
area_brick <- apply_strips_to_brick(area_brick, strips)

# Plot the results
par(mfrow = c(1, 3))

pdf('landscapes/temperature.pdf')
plot(temperature_brick, main = "Temperature Brick")
dev.off()

pdf('landscapes/aridity.pdf')
plot(aridity_brick, main = "Aridity Brick")
dev.off()

pdf('landscapes/area.pdf')
plot(area_brick, main = "Area Brick")
dev.off()

# Create a list of landscapes
landscapes_list <- list(temp = NULL, arid = NULL, area = NULL)
for (i in 1:nlayers(temperature_brick)) {
  landscapes_list$temp <- c(landscapes_list$temp, temperature_brick[[i]])
  landscapes_list$arid <- c(landscapes_list$arid, aridity_brick[[i]])
  landscapes_list$area <- c(landscapes_list$area, area_brick[[i]])
}

# Null cost function
cost_function_null <- function(source, habitable_src, dest, habitable_dest) {
  return(1 / 1000)
}

# Water as barrier cost function
cost_function_water <- function(source, habitable_src, dest, habitable_dest) {
  if (!all(habitable_src, habitable_dest)) {
    return(50 / 1000)
  } else {
    return(1 / 1000)
  }
}

# Create input landscapes with water ignored
create_input_landscape(landscapes = landscapes_list, cost_function = cost_function_null,
                       directions = 8, output_directory = "landscapes/waterignore",
                       timesteps = paste0(seq(65, 0, by = -1), "Ma"),
                       crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs",
                       calculate_full_distance_matrices = FALSE)

# Create input landscapes with water as barrier
create_input_landscape(landscapes = landscapes_list, cost_function = cost_function_water,
                       directions = 8, output_directory = "landscapes/waterbarrier",
                       timesteps = paste0(seq(65, 0, by = -1), "Ma"),
                       crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs",
                       calculate_full_distance_matrices = FALSE)
