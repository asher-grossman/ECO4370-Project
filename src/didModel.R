

# ==============================================================================
# Setup
library(tidyverse)
library(fixest)       
library(modelsummary) 
library(ggplot2)
library(lubridate)

dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)

df <- read_csv("resources/processed/industry_panel_clean.csv")

# ==============================================================================
# Generalized DiD Estimation (Two-Way Fixed Effects)

# Model: Unemployment ~ Tariff Exposure | Industry FE + Date FE
did_model <- feols(unemployment_rate ~ tariff_rate | 
                     industry + date, 
                   data = df, 
                   cluster = ~industry) 

# ==============================================================================
# Event Study (Testing Parallel Trends)

# Create robust numerical time variable
# Feb 2025 = 0, Jan 2025 = -1, Mar 2025 = 1
df <- df %>%
  mutate(
    date = as.Date(date),
    time_to_treat = (year(date) - 2025) * 12 + (month(date) - 2)
  )

# Run Model with Robust Standard Errors (HC1)
event_study <- feols(unemployment_rate ~ i(time_to_treat, tariff_rate, ref = -1) | 
                       industry + date,
                     data = df,
                     vcov = "HC1") 

# Manually Extract Data for Plotting (The "Unbreakable" Method)
# We pull coefficients and confidence intervals directly into a dataframe
es_results <- broom::tidy(event_study, conf.int = TRUE) %>%
  filter(str_detect(term, "time_to_treat")) %>%
  mutate(
    # Extract the numeric time from the term name (e.g., "time_to_treat::-2:tariff_rate")
    time = as.numeric(str_extract(term, "-?\\d+"))
  )

# Add the reference point (t=-1) manually so it shows up on the graph
ref_point <- tibble(term = "ref", estimate = 0, std.error = 0, 
                    conf.low = 0, conf.high = 0, time = -1)
plot_data <- bind_rows(es_results, ref_point)

# Plot
p_event <- ggplot(plot_data, aes(x = time, y = estimate)) +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red") +
  geom_hline(yintercept = 0, color = "black") +
  geom_pointrange(aes(ymin = conf.low, ymax = conf.high), color = "blue") +
  labs(
    title = "Event Study: Tariff Impact Timing",
    subtitle = "Check for Pre-Trends (Left of Red Line) vs. Treatment Effect (Right)",
    x = "Months Relative to Feb 2025",
    y = "Effect on Unemployment Rate (95% CI)"
  ) +
  theme_minimal()

# Save Plot
ggsave("output/figures/did_event_study.png", plot = p_event, width = 8, height = 6)
print(p_event)

# ==============================================================================
# 4. Tables for Screenshot

did_table_view <- modelsummary(
  list("DiD Baseline" = did_model),
  stars = TRUE,
  gof_map = c("nobs", "r.squared", "within.r.squared"),
  coef_map = c("tariff_rate" = "Tariff Exposure"),
  output = "data.frame" 
)

View(did_table_view)
