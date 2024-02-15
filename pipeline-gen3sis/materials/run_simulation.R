library(gen3sis)
print(paste("gen3sis version:", packageVersion("gen3sis")))

print("run_simulation.R")

# Retrieve the value of the TREATMENT environment variable
RNG_SEED <- Sys.getenv("RNG_SEED")
if (RNG_SEED == "") { stop("Environment var RNG_SEED not found.") }
print(paste("RNG_SEED", as.character(RNG_SEED)))

GEN3SIS_TREATMENT <- Sys.getenv("TREATMENT")
if (GEN3SIS_TREATMENT == "") {
    stop("Environment var TREATMENT not found.") }
print(paste("GEN3SIS_TREATMENT", GEN3SIS_TREATMENT))

sim <- run_simulation(
    config = file.path("configs", paste0(GEN3SIS_TREATMENT, ".R")),
    landscape = file.path("landscapes", GEN3SIS_TREATMENT),
    output_directory = paste0(
        "data/treatment=",
        as.character(GEN3SIS_TREATMENT),
        "+seed=",
        as.character(RNG_SEED)
    ),
    call_observer = 1,
    verbose = 1
)
