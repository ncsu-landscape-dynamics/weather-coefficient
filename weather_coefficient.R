## Read in libraries
library(rgdal)
library(raster)
library(ncdf4)
library(sp)
library(stringr)
#library(googledrive)

weather_coefficient <- function(directory, output_directory, start, end, time_step, study_area = "states", states_of_interest= c('California'), 
                                reference_area = NULL, pest, lethal_temperature = 'NO', lethal_month = "01", future_scenarios = TRUE, lethal_min = 'YES',
                                prcp_index = 'NO', prcp_method = "reclass",  prcp_a0 = 0, prcp_a1 = 0, prcp_a2 = 0, prcp_a3 = 0, 
                                prcp_matrix = 0, prcp_x1mod = 0, prcp_x2mod = 0, prcp_x3mod = 0, lethal_temperature_value = NULL,
                                temp_index = 'YES', temp_method = "polynomial", temp_a0 = 0, temp_a1 = 0, temp_a2 = 0, temp_a3 = 0, 
                                temp_matrix = 0, temp_x1mod = 0, temp_x2mod = 0, temp_x3mod = 0) {
  
  ## create time range
  time_range <- seq(start, end, 1)
  if(future_scenarios == 'YES'){
    number_of_years <- length(time_range)
  }
  
  ## read in list of daymet files to choose from later 
  if(prcp_index == 'YES'){
    precip_files <- list.files(directory,pattern='prcp', full.names = FALSE)
    prcp <- stack() # Create raster stack for the area of interest and years of interest from Daymet data
    if(future_scenarios == 'NO'){
      dates <- substr(precip_files,16,19) # Assumes daymet data is saved in the exact naming format that it is downloaded as
      precip_files <- precip_files[dates %in% time_range]
    }
    total_years <- length(precip_files) # number of years to clip
  } 
  
  if(temp_index == 'YES'){
    tmax_files <- list.files(directory,pattern='tmax', full.names = FALSE)
    tmin_files <- list.files(directory,pattern='tmin', full.names = FALSE)
    if(future_scenarios == 'NO'){
      dates <- substr(tmax_files,16,19) # Assumes daymet data is saved in the exact naming format that it is downloaded as
      tmin_files <- tmin_files[dates %in% time_range]
      tmax_files <- tmax_files[dates %in% time_range]
    }
    total_years <- length(tmin_files) # number of years to clip
    ## Create raster stacks for the area of interest and years of interest from Daymet data
    tmin_s <- stack()
    tmax_s <- stack()
    tavg_s <- stack()
  }
  
  if(lethal_temperature == 'YES') {
    lethal_temp_stack = stack()
  }
  
  ## reference shapefile used to clip, project, and resample 
  if (study_area == "states"){
    states <- readOGR("C:/Users/Chris/Desktop/states/us_states_lccproj.shp") # link to your local copy
    reference_area <- states[states@data$STATE_NAME %in% states_of_interest,]
    rm(states)
  } else if (study_area == "raster"){
    reference_area <- reference_area
  }
  
  for (i in 1:total_years) {
    ## Precipitation 
    if(prcp_index == 'YES'){
      precip <- stack(paste(directory,"/",precip_files[[i]], sep = ""), varname = "prcp")
      precip <- crop(precip, reference_area)
      if (i>1 && compareCRS(precip,prcp) == FALSE) { precip@crs <- crs(prcp) }
      prcp <- stack(prcp, precip)
      rm(precip)
    }

    ## Temperature
    if(temp_index == 'YES'){
      tmin <- stack(paste(directory, "/", tmin_files[[i]], sep =""), varname = "tmin")
      tmin <- crop(tmin, reference_area)
      if (i>1 && compareCRS(tmin,tmin_s) == FALSE) { tmin@crs <- crs(tmin_s) }
      tmax <- stack(paste(directory, "/", tmax_files[[i]], sep = ""), varname = "tmax")
      tmax <- crop(tmax, reference_area)
      if (i>1 && compareCRS(tmax,tmax_s) == FALSE) { tmax@crs <- crs(tmax_s) }
      tavg <- tmax
      for (j in 1:nlayers(tmax)){
        tavg[[j]] <- overlay(tmax[[j]], tmin[[j]], fun = function(r1, r2){return((r1+r2)/2)})
        print(j)
      }
      tmin_s <- stack(tmin, tmin_s)
      tmax_s <- stack(tmax, tmax_s)
      tavg_s <- stack(tavg, tavg_s)
      if (lethal_temperature == 'YES') {
        lethal_index <- which(str_sub(names(tmin), 7,8) == lethal_month)
        lethal_rast <- tavg[[lethal_index]]
        if(lethal_min == 'YES') {
          lethal_temp <- stackApply(lethal_rast, indices = rep(1,nlayers(lethal_rast)), fun=min)
        } else {
          lethal_temp <- stackApply(lethal_rast, indices = rep(1,nlayers(lethal_rast)), fun=max)
        } 
        lethal_temp_stack <- stack(lethal_temp_stack, lethal_temp)
      }
    }
    print(i)
  }
  
  if(temp_index == 'YES'){
    names(tavg_s) <- names(tmin_s)
  }
  
  ## create indices based on timestep
  if(prcp_index =='YES'){
    if(time_step == "daily"){
      indices <- format(as.Date(names(prcp), format = "X%Y.%m.%d"), format = "%d")
      indices <- as.numeric(indices)
      indices_weather_ranking <- rep(1,365)
      new_ind <- indices_weather_ranking
      for (i in 2:total_years){
        new_ind <- new_ind+1
        indices_weather_ranking <- c(indices_weather_ranking, new_ind)
      }
    } else if(time_step == "weekly"){
      indices <- rep(seq(1,((nlayers(prcp)/7)+1),1),7)
      indices <- indices[1:nlayers(prcp)]
      indices <- indices[order(indices)]
      indices_weather_ranking <- rep(1,53)
      new_ind <- indices_weather_ranking
      for (i in 2:total_years){
        new_ind <- new_ind+1
        indices_weather_ranking <- c(indices_weather_ranking, new_ind)
      }
    } else if(time_step == "monthly"){
      indices <- format(as.Date(names(prcp), format = "X%Y.%m.%d"), format = "%Y%m")
      indices <- as.numeric(as.factor(indices))
      indices_weather_ranking <- rep(1,12)
      new_ind <- indices_weather_ranking
      for (i in 2:total_years){
        new_ind <- new_ind+1
        indices_weather_ranking <- c(indices_weather_ranking, new_ind)
      }
    }
  } else if(prcp_index =='NO'){
    if(time_step == "daily"){
      indices <- format(as.Date(names(tavg_s), format = "X%Y.%m.%d"), format = "%d")
      indices <- as.numeric(indices)
      indices_weather_ranking <- rep(1,365)
      new_ind <- indices_weather_ranking
      for (i in 2:total_years){
        new_ind <- new_ind+1
        indices_weather_ranking <- c(indices_weather_ranking, new_ind)
      }
    } else if(time_step == "weekly"){
      indices <- rep(seq(1,((nlayers(tavg_s)/7)+1),1),7)
      indices <- indices[1:nlayers(tavg_s)]
      indices <- indices[order(indices)]
      indices_weather_ranking <- rep(1,53)
      new_ind <- indices_weather_ranking
      for (i in 2:total_years){
        new_ind <- new_ind+1
        indices_weather_ranking <- c(indices_weather_ranking, new_ind)
      }
    } else if(time_step == "monthly"){
      indices <- format(as.Date(names(tavg_s), format = "X%Y.%m.%d"), format = "%Y%m")
      indices <- as.numeric(as.factor(indices))
      indices_weather_ranking <- rep(1,12)
      new_ind <- indices_weather_ranking
      for (i in 2:total_years){
        new_ind <- new_ind+1
        indices_weather_ranking <- c(indices_weather_ranking, new_ind)
      }
    }
  }
  
  ## Create temperature and/or precipitation indices if method is reclass
  if (prcp_index == 'YES' && prcp_method == "reclass"){
    prcp_coeff <- reclassify(prcp,prcp_matrix)
    prcp_coeff <- stackApply(prcp_coeff, indices, fun=mean)
  }
  
  if (temp_index == 'YES' && temp_method == "reclass"){
    temp_coeff <- reclassify(tavg_s,temp_matrix)
    temp_coeff <- stackApply(temp_coeff, indices, fun=mean)
  }
  
  ## create temperature and/or precipitation indices from daymet data based on time-step and variables of interest
  if (prcp_index == 'YES' && prcp_method == "polynomial"){
    prcp_coeff <- stackApply(prcp, indices, fun=mean)
    prcp_coeff <- prcp_a0 + (prcp_a1 * (prcp_coef  + prcp_x1mod)) + (prcp_a2 * (prcp_coef + prcp_x2mod)**2) + (prcp_a3 * (prcp_coef + prcp_x3mod)**3)
    prcp_coeff[prcp_coeff < 0] <- 0 # restrain lower limit to 0
    prcp_coeff[prcp_coeff > 1] <- 1 # restrain upper limit to 1
  }
  
  if (temp_index == 'YES' && temp_method == "polynomial"){
    temp_coeff <- stackApply(tavg_s, indices, fun=mean)
    temp_coeff <- temp_a0 + (temp_a1 * (temp_coeff + temp_x1mod)) + (temp_a2 * (temp_coeff + temp_x2mod)**2) + (temp_a3 * (temp_coeff + temp_x3mod)**3)
    temp_coeff[temp_coeff < 0] <- 0 # restrain lower limit to 0
    temp_coeff[temp_coeff > 1] <- 1 # restrain upper limit to 1
  }
  
  if(future_scenarios == 'YES'){
    if(prcp_index == 'YES') {
      prcp_coeff_ranking <- stackApply(prcp_coeff, indices = indices_weather_ranking, fun = mean)
    }
    if(temp_index == 'YES') {
      temp_coeff_ranking <- stackApply(temp_coeff, indices = indices_weather_ranking, fun = mean)
    }
    if(lethal_temperature == 'YES') {
      lethal_temp_matrix <- c(-Inf, lethal_temperature_value, 1, 
                              lethal_temperature_value, Inf, 2)
      lethal_temp_matrix <- matrix(lethal_temp_matrix, ncol=3, byrow=TRUE)
      lethal_temp_area <- reclassify(lethal_temp_stack, lethal_temp_matrix)
    }
    
    first_year <- as.numeric(substr(precip_files[[1]],16,19))
    last_year <- as.numeric(substr(precip_files[[total_years]],16,19))
    weather_ranking <- data.frame(year = seq(first_year,last_year,1),index = seq(1,total_years,1), lethal_temp_area = rep(0,total_years), avg_temp_coeff = rep(0,total_years), avg_prcp_coeff = rep(0,total_years))
    for (i in 1:total_years) {
      cta <- lethal_temp_area[[i]]
      weather_ranking$lethal_temp_area[i] <- sum(cta[cta == 1])/ncell(cta)
      weather_ranking$avg_temp_coeff[i] <- mean(getValues(temp_coeff_ranking[[i]]), na.rm = TRUE)
      weather_ranking$avg_prcp_coeff[i] <- mean(getValues(prcp_coeff_ranking[[i]]), na.rm = TRUE)
    }
    if(prcp_index== 'YES' && temp_index == 'YES'){
      weather_ranking$total_coeff_score <- weather_ranking$avg_temp_coeff*weather_ranking$avg_prcp_coeff-(weather_ranking$lethal_temp_area*0.5)
    } else if(prcp_index== 'YES' && temp_index == 'NO'){
      weather_ranking$total_coeff_score <- weather_ranking$avg_prcp_coeff - weather_ranking$lethal_temp_area*0.5
    } else if(prcp_index== 'No' && temp_index == 'YES'){
      weather_ranking$total_coeff_score <- weather_ranking$avg_temp_coeff - weather_ranking$lethal_temp_area*0.5
    } else if(prcp_index== 'NO' && temp_index == 'NO'){
      weather_ranking$total_coeff_score <- 0-weather_ranking$lethal_temp_area
    }
    weather_ranking <- weather_ranking[order(weather_ranking$total_coeff_score, decreasing = TRUE),]
    weather_ranking$rank <- seq(1,nrow(weather_ranking),1)
    high_spread <- round(nrow(weather_ranking)*0.33)
    average_spread <- high_spread+round(nrow(weather_ranking)*0.33)
    low_spread <- nrow(weather_ranking)
    high_spread_indices <- sample(1:high_spread, length(time_range), replace = FALSE)
    average_spread_indices <- sample((high_spread+1):average_spread, length(time_range), replace = FALSE)
    low_spread_indices <- sample((average_spread+1):low_spread, length(time_range), replace = FALSE)
    high_spread_indices <- weather_ranking$index[high_spread_indices]
    average_spread_indices <- weather_ranking$index[average_spread_indices]
    low_spread_indices <- weather_ranking$index[low_spread_indices]
    high_spread_coeff_indices <- c()
    average_spread_coeff_indices <- c()
    low_spread_coeff_indices <- c()
    for(i in 1:length(time_range)){
      if(time_step == "daily"){
        high_spread_coeff_indices <- c(high_spread_coeff_indices,seq(1+365*(high_spread_indices[i]-1),365+365*(high_spread_indices[i]-1)))
        average_spread_coeff_indices <- c(average_spread_coeff_indices,seq(1+365*(average_spread_indices[i]-1),365+365*(average_spread_indices[i]-1)))
        low_spread_coeff_indices <- c(low_spread_coeff_indices,seq(1+365*(low_spread_indices[i]-1),365+365*(low_spread_indices[i]-1)))
      } else if(time_step == "weekly"){
        high_spread_coeff_indices <- c(high_spread_coeff_indices,seq(1+52*(high_spread_indices[i]-1),52+52*(high_spread_indices[i]-1)))
        average_spread_coeff_indices <- c(average_spread_coeff_indices,seq(1+52*(average_spread_indices[i]-1),52+52*(average_spread_indices[i]-1)))
        low_spread_coeff_indices <- c(low_spread_coeff_indices,seq(1+52*(low_spread_indices[i]-1),52+52*(low_spread_indices[i]-1)))
      } else if(time_step == "monthly"){
        high_spread_coeff_indices <- c(high_spread_coeff_indices,seq(1+12*(high_spread_indices[i]-1),12+12*(high_spread_indices[i]-1)))
        average_spread_coeff_indices <- c(average_spread_coeff_indices,seq(1+12*(average_spread_indices[i]-1),12+12*(average_spread_indices[i]-1)))
        low_spread_coeff_indices <- c(low_spread_coeff_indices,seq(1+12*(low_spread_indices[i]-1),12+12*(low_spread_indices[i]-1)))
      }
    }
    high_spread_temp_coeff <- temp_coeff[[high_spread_coeff_indices]]
    average_spread_temp_coeff <- temp_coeff[[average_spread_coeff_indices]]
    low_spread_temp_coeff <- temp_coeff[[low_spread_coeff_indices]]
    
    high_spread_prcp_coeff <- prcp_coeff[[high_spread_coeff_indices]]
    average_spread_prcp_coeff <- prcp_coeff[[average_spread_coeff_indices]]
    low_spread_prcp_coeff <- prcp_coeff[[low_spread_coeff_indices]]
    
    high_spread_lethal_temp <- lethal_temp_stack[[high_spread_indices]]
    average_spread_lethal_temp <- lethal_temp_stack[[average_spread_indices]]
    low_spread_lethal_temp <- lethal_temp_stack[[low_spread_indices]]
  }
  
  ## create directory for writing files
  dir.create(output_directory)
  
  ## Write outputs as raster format to output directory
  if(future_scenarios == 'YES'){
    data <- list(weather_ranking)
    if(prcp_index == 'YES'){
      writeRaster(x=prcp_coeff, filename = paste(output_directory, "/prcp_coeff_", first_year, "_", last_year, "_", pest, ".tif", sep = ""), overwrite=TRUE, format = 'GTiff')
      writeRaster(x=high_spread_prcp_coeff, filename = paste(output_directory, "/high_spread_prcp_coeff_", start, "_", end, "_", pest, ".tif", sep = ""), overwrite=TRUE, format = 'GTiff')
      writeRaster(x=average_spread_prcp_coeff, filename = paste(output_directory, "/average_spread_prcp_coeff_", start, "_", end, "_", pest, ".tif", sep = ""), overwrite=TRUE, format = 'GTiff')
      writeRaster(x=low_spread_prcp_coeff, filename = paste(output_directory, "/low_spread_prcp_coeff_", start, "_", end, "_", pest, ".tif", sep = ""), overwrite=TRUE, format = 'GTiff')
      data <- c(data, average_spread_prcp_coeff, low_spread_prcp_coeff, high_spread_prcp_coeff, prcp_coeff)
    }
    if(temp_index == 'YES'){
      writeRaster(x=temp_coeff, filename = paste(output_directory, "/temp_coeff_", first_year, "_", last_year, "_", pest, ".tif", sep = ""), overwrite=TRUE, format = 'GTiff')
      writeRaster(x=high_spread_temp_coeff, filename = paste(output_directory, "/high_spread_temp_coeff_", start, "_", end, "_", pest, ".tif", sep = ""), overwrite=TRUE, format = 'GTiff')
      writeRaster(x=average_spread_temp_coeff, filename = paste(output_directory, "/average_spread_temp_coeff_", start, "_", end, "_", pest, ".tif", sep = ""), overwrite=TRUE, format = 'GTiff')
      writeRaster(x=low_spread_temp_coeff, filename = paste(output_directory, "/low_spread_temp_coeff_", start, "_", end, "_", pest, ".tif", sep = ""), overwrite=TRUE, format = 'GTiff')
      data <- c(data, average_spread_temp_coeff, low_spread_temp_coeff, high_spread_temp_coeff, temp_coeff)
      }
    if(lethal_temperature == 'YES'){
      writeRaster(x=lethal_temp_stack, filename = paste(output_directory, "/lethal_temp_", first_year, "_", last_year, "_", pest, ".tif", sep = ""), overwrite=TRUE, format = 'GTiff')
      writeRaster(x=high_spread_lethal_temp, filename = paste(output_directory, "/high_spread_lethal_temp_", start, "_", end, "_", pest, ".tif", sep = ""), overwrite=TRUE, format = 'GTiff')
      writeRaster(x=average_spread_lethal_temp, filename = paste(output_directory, "/average_spread_lethal_temp_", start, "_", end, "_", pest, ".tif", sep = ""), overwrite=TRUE, format = 'GTiff')
      writeRaster(x=low_spread_lethal_temp, filename = paste(output_directory, "/low_spread_lethal_temp_", start, "_", end, "_", pest, ".tif", sep = ""), overwrite=TRUE, format = 'GTiff')
      data <- c(data, average_spread_lethal_temp, low_spread_lethal_temp, high_spread_lethal_temp, lethal_temp)
    }
    
  } else if(future_scenarios == 'NO'){
    data <- c()
    if(prcp_index == 'YES'){
      writeRaster(x=prcp_coeff, filename = paste(output_directory, "/prcp_coeff_", start, "_", end, "_", pest, ".tif", sep = ""), overwrite=TRUE, format = 'GTiff')
      data <- c(data, prcp_coeff)
    }
    if(temp_index == 'YES'){
      writeRaster(x=temp_coeff, filename = paste(output_directory, "/temp_coeff_", start, "_", end, "_", pest, ".tif", sep = ""), overwrite=TRUE, format = 'GTiff')
      data <- c(data, temp_coeff)
    }
    if(lethal_temperature == 'YES'){
      writeRaster(x=lethal_temp_stack, filename = paste(output_directory, "/lethal_temp_", start, "_", end, "_", pest, ".tif", sep = ""), overwrite=TRUE, format = 'GTiff')
      data <- c(data, lethal_temp_stack)
    }
  }

  return(data)
}
