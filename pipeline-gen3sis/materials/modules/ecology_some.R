apply_ecology <- function(abundance, traits, landscape, config) {
 abundance_scale = 10
 abundance_threshold = 1
 #abundance treashold
 survive <- abundance>=abundance_threshold
 abundance[!survive] <- 0
 abundance <- (( 1-abs( traits[, "temp"] - landscape[, "temp"]))*abundance_scale)*as.numeric(survive)
 #abundance thhreashold
 abundance[abundance<abundance_threshold] <- 0
 k <- ((landscape[,"area"]*(landscape[,"arid"]+0.1)*(landscape[,"temp"]+0.1))*abundance_scale^2)
 total_ab <- sum(abundance)
 subtract <- total_ab-k
 if (subtract > 0) {
   # print(paste("should:", k, "is:", total_ab, "DIFF:", round(subtract,0) ))
   while (total_ab>k){
     alive <- abundance>0
     loose <- sample(1:length(abundance[alive]),1)
     abundance[alive][loose] <- abundance[alive][loose]-1
     total_ab <- sum(abundance)
   }
   #set negative abundances to zero
   abundance[!alive] <- 0
 }
 return(abundance)
}
