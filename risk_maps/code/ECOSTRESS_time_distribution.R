library(lubridate)
library(purrr)

files <- list.files(here::here("risk_maps",
                                   "data", 
                                   "processed_data", 
                                   "ECOSTRESS", 
                                   "air_temperature"))

get_time <- function(file){
  date <- substr(file, 14, 23)
  hhmmss <- str_extract(file, regex('[0-9]{2}:{1}[0-9]{2}:{1}[0-9]{2}'))
  dt <- ymd_hms(paste(date, hhmmss), tz = "America/Los_Angeles")
  return(dt)
}

dt <- lapply(files, get_time) %>% purrr::reduce(c)

ggplot(data.frame(hour = hour(dt) + minute(dt)/60, 
                  month = month(dt) + day(dt)/30, 
                  year = year(dt))) + 
  geom_point(aes(x = hour, y = month))

