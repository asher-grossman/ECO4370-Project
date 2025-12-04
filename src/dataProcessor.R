# ==============================================================================
# 1. Setup and Libraries

library(tidyverse)
library(fredr)
library(lubridate)

# REMEMBER TO KEEP API KEY PRIVATE 
# Alternate ROUTE: read from .Renviron
fredr_set_key("1b47a4d760390a238a13c7478b5df439")

# create directories if they don't exist
if(!dir.exists("resources/raw")) dir.create("resources/raw", recursive = TRUE)
if(!dir.exists("resources/processed")) dir.create("resources/processed", recursive = TRUE)

# ==============================================================================
# 2. Industry Mapping & Data Fetch 

# Source: https://fred.stlouisfed.org/tags/series?t=unemployment%3Bindustry

industry_map <- tibble(
  industry_name = c("Manufacturing", "Construction", "Information", 
                    "Leisure_Hospitality", "Mining_Oil_Gas", "Financial_Activities"),
  series_id     = c("LNU04032232",   # Manufacturing Unemployment 
                    "LNU04032231",   # Construction Unemployment
                    "LNU04032237",   # Information Unemployment
                    "LNU04032241",   # Leisure & Hospitality Unemployment
                    "LNU04032230",   # Mining Unemployment
                    "LNU04032238")   # Financial Activities Unemployment
)

#Fetch data from FRED (source linked above)
fetch_series <- function(id, name) {
  tryCatch({
    fredr(
      series_id = id,
      observation_start = as.Date("2010-01-01"),
      observation_end   = as.Date("2025-12-01"), #current date
      frequency = "m" # monthly
    ) |>
      mutate(industry_name = name) |>
      select(date, industry_name, unemployment_rate = value)
  }, error = function(e) {
    message(paste("Error fetching", name, ":", e$message))
    return(NULL)
  })
}


raw_fred_data <- map2_dfr(industry_map$series_id, industry_map$industry_name, fetch_series)

# verify data is correctly fetch
if(nrow(raw_fred_data) == 0) stop("No data fetched from FRED.")

# save to new directory
write_csv(raw_fred_data, "resources/raw/industry_panel_raw.csv")

# optional head view of data
# head(raw_fred_data)

# ==============================================================================
# 3. Import Tariff Schedule

# we built tariff schedule csv manually based on public info
# for replicability, check if csv exists, else stop script
if(!file.exists("resources/raw/trump_tariff_schedule_2025.csv")) {
  print("Warning: Tariff CSV not found. Generating mock data instead.")
  print("Do not use mock data for actual analysis!!!")
  mock_schedule <- tibble(
    industry_name = c("Manufacturing", "Construction", "Information", 
                      "Leisure_Hospitality", "Mining_Oil_Gas", "Financial_Activities"),
    base_tariff_rate = c(2.0, 1.5, 0.5, 0.0, 1.0, 0.0),
    trump_tariff_add_on = c(25.0, 15.0, 5.0, 0.0, 10.0, 0.0),
    effective_date = as.Date("2025-02-01")
    )
  write_csv(mock_schedule, "resources/raw/trump_tariff_schedule_2025.csv")
}

tariff_schedule <- read_csv("resources/raw/trump_tariff_schedule_2025.csv",
                            show_col_types = FALSE) |>
mutate(effective_date = as.Date(effective_date))

# Join policy data to economic data
final_df <- raw_fred_data |>
left_join(tariff_schedule, by = "industry_name") |>
mutate(
  post_treatment = if_else(date >= effective_date, 1, 0),

  # dynamic tariff rate
  tariff_rate = if_else(post_treatment == 1,
                        base_tariff_rate + trump_tariff_add_on,
                        base_tariff_rate),

  # lobbying instrument
  lobbying_index = case_when(
    industry_name == "Manufacturing" ~ 9.5,
    industry_name == "Construction" ~ 6.0,
    industry_name == "Mining_Oil_Gas" ~ 8.0,
    industry_name == "Information" ~ 7.5,
    industry_name == "Financial_Activities" ~ 5.0,
    TRUE ~ 2.0
  ) 
) |>
select(date, industry = industry_name, unemployment_rate,
       tariff_rate, post_treatment, lobbying_index) %>%
drop_na()

# ==============================================================================
# 4. Export

# Save to resources/processed directory
write_csv(final_df, "resources/processed/industry_panel_clean.csv")

