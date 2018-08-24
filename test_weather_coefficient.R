## Testing weather coefficient creation function
source("weather_coefficient.R")

start <-  2014
end <- 2017
time_step <- "monthly"
directory <- "G:/DaymetUS"
output_directory <- "G:/DaymetUS/test"
study_area = "states"
states_of_interest <- c('Maryland')
lethal_temperature <- 'YES' # YES or NO
lethal_month ="01" # set to between "01" and "12"
lethal_min = 'YES' # YES or NO
lethal_temperature_value = -12
future_scenarios = 'YES' # True or false
pest <- "SLF"
prcp_index = 'YES' # YES or NO
prcp_method = "reclass" # either reclass or polynomial
prcp_a0 = 0
prcp_a1 = 0 
prcp_a2 = 0 
prcp_a3 = 0 
prcp_x1mod = 0
prcp_x2mod = 0
prcp_x3mod = 0
prcp_thresh = 2.5
prcp_mat <- c(0, prcp_thresh, 0,  prcp_thresh, Inf, 1)
prcp_matrix <- matrix(prcp_mat, ncol=3, byrow=TRUE)
temp_index = 'YES'  # YES or NO
temp_method = "reclass"  # either reclass or polynomial
temp_a0 = -0.066
temp_a1 = 0.056
temp_a2 = -0.0036
temp_a3 = -0.0003
temp_x1mod = 0
temp_x2mod = -15
temp_x3mod = -15
temp_thresh = 0
temp_mat <- c(-Inf, -12, 0, 
        -12, -11,0.05,
        -11, -10,0.1,
        -10,-9,0.15,
        -9,-8,0.2,
        -8,-7,0.25,
        -7,-6,0.3,
        -6,-5,0.35,
        -5,-4,0.4,
        -4,-3,0.45,
        -3,-2,0.5,
        -2,-1,0.55,
        -1,0,0.6,
        0,1,0.65,
        1,2,0.7,
        2,3,0.75,
        3,4,0.8,
        4,5,0.85,
        5,6,0.9,
        6,7,0.95,
        7,8,1,
        8, 30, 1, 
        30, 31, 1,
        31, 32, .8,
        32, 33, .6,
        33, 34, .4,
        34, 35, .2,
        35, Inf, 0)
temp_matrix <- matrix(temp_mat, ncol=3, byrow=TRUE)


weather_coefficient(directory = directory, output_directory = output_directory, start = start, end = end, time_step = time_step, 
                    study_area = study_area, states_of_interest = states_of_interest, lethal_temperature = lethal_temperature,
                    lethal_min = lethal_min, lethal_month = lethal_month, lethal_temperature_value = lethal_temperature_value, future_scenarios = future_scenarios,
                    pest = pest, prcp_index = prcp_index, prcp_method = prcp_method,  prcp_a0 = prcp_a0, prcp_a1 = prcp_a1, prcp_a2 = prcp_a2, prcp_a3 = prcp_a3, 
                    prcp_matrix = prcp_matrix, prcp_x1mod = prcp_x1mod, prcp_x2mod = prcp_x2mod, prcp_x3mod = prcp_x3mod,
                    temp_index = temp_index, temp_method = temp_method, temp_a0 = temp_a0, temp_a1 = temp_a1, temp_a2 = temp_a2, temp_a3 = temp_a3, 
                    temp_matrix = temp_matrix, temp_x1mod = temp_x1mod, temp_x2mod = temp_x2mod, temp_x3mod = temp_x3mod)

