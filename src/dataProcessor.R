# ==============================================================================
# 1. Setup and Libraries
# ==============================================================================
library(tidyverse)
library(fredr)
library(lubridate)

# REMEMBER TO KEEP API KEY PRIVATE 
# OTHER ROUTE: read from .Renviron
fredr_set_key("1b47a4d760390a238a13c7478b5df439")

# Create directories if they don't exist
# FIX DIRECTORY PATHS
dir.create("resources/raw", recursive = TRUE, showWarnings = FALSE)
dir.create("resources/processed", recursive = TRUE, showWarnings = FALSE)

# ==============================================================================
# 2. Fetch Economic Data (FRED)
# ==============================================================================
# BLS Series IDs for Industry-Level Unemployment Rates
# derived from the Current Population Survey (CPS).
# Source: https://fred.stlouisfed.org/tags/series?t=unemployment%3Bindustry

industry_map <- tibble(
  industry_name = c("Manufacturing", "Construction", "Information", 
                    "Leisure_Hospitality", "Mining_Oil_Gas", "Financial_Activities"),
  series_id     = c("LNU04032232",   # Manufacturing Unemployment Rate
                    "LNU04032231",   # Construction Unemployment Rate
                    "LNU04032237",   # Information Unemployment Rate
                    "LNU04032241",   # Leisure & Hospitality Unemployment Rate
                    "LNU04032230",   # Mining Unemployment Rate
                    "LNU04032238")   # Financial Activities Unemployment Rate
)

print("Fetching data from FRED API...")

# Function to safely map over series IDs
# NEED ADJUST TO FINALIZE ANALYSIS
fetch_series <- function(id, name) {
  fredr(
    series_id = id,
    observation_start = as.Date("2010-01-01"),
    observation_end   = as.Date("2025-12-01"), # Current period
    frequency = "m" # Monthly
  ) %>%
    mutate(industry = name) %>%
    select(date, industry, unemployment_rate = value)
}

raw_fred_data <- map2_dfr(industry_map$series_id, industry_map$industry_name, fetch_series)

# ==============================================================================
# 3. Import/Construct Tariff Data (Simulating USITC DataWeb)
# ==============================================================================
# ALT OPTION: True scenario analysis -> load "resources/raw/tariff_schedules.csv".
# Instead, we make a dataframe based on the 2025 Tariff Policy (Trump Tariffs for context)

print("Constructing Tariff Exposure Panel...")

tariff_panel <- raw_fred_data %>%
  select(date, industry) %>%
  distinct() %>%
  mutate(
    year = year(date),
    month = month(date),
    # The Post-Treatment dummy: Tariffs effective Feb 2025
    post_treatment = if_else(date >= as.Date("2025-02-01"), 1, 0),
    
    # Assign Tariff Rates (this is the SHOCK)
    # Baseline (2010-2024, pre-Trump Tariffs) vs Treatment (2025+,Post Trump Tariffs)
    tariff_rate = case_when(
      # We think Steel/Aluminum tariffs heavily impact Manufacturing & Construction
      industry == "Manufacturing" & post_treatment == 1 ~ 25.0, # 25% Section 232/301 mix
      industry == "Construction"  & post_treatment == 1 ~ 15.0, # Input cost pass-through
      industry == "Information"   & post_treatment == 1 ~ 5.0,  # Electronics tariffs
      industry == "Leisure_Hospitality" & post_treatment == 1 ~ 0.0, # Minimal direct exposure
      TRUE ~ 2.0 # Baseline historical average
    ),
    
    # Construct Instrument for 2SLS: "Historical Lobbying Intensity"
    # Our logic: Industries that lobbied more in 2015-2020 (First Trump term) got higher protection in 2025.
    # These are correlated with tariff_rate but exogenous to 2025 monthly unemployment shocks.
    lobbying_index = case_when(
      industry == "Manufacturing" ~ 9.5,
      industry == "Construction" ~ 6.0,
      industry == "Mining_Oil_Gas" ~ 8.0,
      industry == "Information" ~ 7.5,
      industry == "Financial_Activities" ~ 5.0,
      TRUE ~ 2.0
    )
  )

# ==============================================================================
# 4. Merge and Export
# ==============================================================================

final_df <- raw_fred_data %>%
  left_join(tariff_panel, by = c("date", "industry")) %>%
  drop_na() # Remove rows where no data reported

# Save to resources/processed directory to later be implemented with our models
write_csv(final_df, "resources/processed/industry_panel_clean.csv")

print("Data processing complete. Clean file saved to resources/processed/industry_panel_clean.csv")
