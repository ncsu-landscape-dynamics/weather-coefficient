# weather-coefficient

## Overview
weather coefficient converts raw weather data from Daymet to weather coefficients used in the [PoPS model](https://github.com/ncsu-landscape-dynamics/PoPS).

## Parameters
Parameter - **Meaning and/or (Options)**
* start - **First year that you want to have weather coefficients for**
* end - **Last year that you want to have weather coefficients for**
* time_step - **("daily", "weekly", "monthly")**
* directory - **Local directory with Daymet files**
* output_directory - **Output directory you want the function to write the weather coefficient files to**
* study_area - **Use raster for predefined areas and states if you want your data for whole states ("states" or "raster")**
* states_of_interest - **only used if study_area = "states" (eg: "California")**
* states_file - **only used if study_area = "states". This is the location of your states shapefile. Needs to be in same projection as Daymet data (Lambert Conformal Conic)**
* reference_area - **only used if study_area = "raster". This should be the boundary of your study area and in same projection as Daymet data (Lambert Conformal Conic)**
* lethal_temperature - **(YES or NO)**
* lethal_month - **(between "01" and "12")**
* lethal_min - **Does your specie experience mortality below a certain temperature ("YES" or "NO")**
* lethal_temperature_value - **The value that your species experiences mortality**
* future_scenarios - **('YES', 'NO')**
* pest - **The name of the pest or pathogen the weather coefficients are to be used for. Naming purposes only. (eg: "SOD")**
* prcp_index - **Does precipitation affect the survival and reproduction of your pest/pathogen ('YES' or 'NO')**
* prcp_method - **Method used to convert raw data to precipitation coefficients ('reclass' or 'polynomial')**
* temp_index - **Does temperature affect the survival and reproduction of your pest/pathogen ('YES' or 'NO')**
* temp_method - **Method used to convert raw data to temperature coefficients ('reclass' or 'polynomial')**
* temp_matrix - **Matrix used to reclassify temperatures only used if temp_method = 'reclass'**
* prcp_matrix - **Matrix used to reclassify temperatures only used if temp_method = 'reclass'**

```R
## Example prcp_matrix creation, also works for temp_matrix. matrix must to nx3 col1 = from, col2 = to, col3 = reclass value
prcp_thresh = 2.5
prcp_mat <- c(0, prcp_thresh, 0,  prcp_thresh, Inf, 1)
prcp_matrix <- matrix(prcp_mat, ncol=3, byrow=TRUE)
     [,1] [,2] [,3]
[1,]  0.0  2.5    0
[2,]  2.5  Inf    1
```
```R
## Example of polynomial , works for both temp and prcp polynomials. 
temp_a0 = -0.066
temp_a1 = 0.056
temp_a2 = -0.0036
temp_a3 = -0.0003
temp_x1mod = 0
temp_x2mod = -15
temp_x3mod = -15
temp_thresh = 0
temp = seq(0,30, 1)
temp_coeff = temp_a0 + temp_a1*(temp + temp_x1mod) + temp_a2*((temp + temp_x2mod)^2) + temp_a3*((temp + temp_x3mod)^3)
plot(temp, temp_coeff)
```
![picture](https://github.com/ncsu-landscape-dynamics/weather-coefficient/blob/Release/temp_coeff_plot_example.jpeg)

* prcp_a0 - **only used if prcp_method = 'polynomial'**
* prcp_a1 - **only used if prcp_method = 'polynomial'**
* prcp_a2 - **only used if prcp_method = 'polynomial'**
* prcp_a3 - **only used if prcp_method = 'polynomial'**
* prcp_x1mod - **only used if prcp_method = 'polynomial'**
* prcp_x2mod - **only used if prcp_method = 'polynomial'**
* prcp_x3mod - **only used if prcp_method = 'polynomial'**


* temp_a0 - **only used if temp_method = 'polynomial'**
* temp_a1 - **only used if temp_method = 'polynomial'**
* temp_a2 - **only used if temp_method = 'polynomial'**
* temp_a3 - **only used if temp_method = 'polynomial'**
* temp_x1mod - **only used if temp_method = 'polynomial'**
* temp_x2mod - **only used if temp_method = 'polynomial'**
* temp_x3mod - **only used if temp_method = 'polynomial'**

## Authors

* Chris Jones
* Devon Gaydos (Oregon_test)

