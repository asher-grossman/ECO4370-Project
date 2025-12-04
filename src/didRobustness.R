library(tidyverse)
library(fixest)
library(modelsummary)

# load data
df <- read_csv("resources/processed/industry_panel_clean.csv")

#--------------------------------------------------------------------------------------------------------------
# 1. Event Time Variable

# center treatment period at February 2025
df <- df |>
mutate(
  date = as.Date(date),
  # months relative to treatment
  time_to_treatment = interval(as.Date("2025-02-01"), date) |> 
  months(1)
  )

#--------------------------------------------------------------------------------------------------------------
# 2. Estimate Dynamic Effects (event study)

# interact tariff_exposure with time dummies
# ref = -1 means we normalize the month before tariffs to zero
# if coefficients -2, -3, -4 are significant, our causal assumption is VIOLATED

event_study_model <- feols(unemployment ~ i(time_to_treatment, tariff_rate, ref = -1) |
                           industry_name + date,
                           data = df,
                           cluster = ~industry_name)

#--------------------------------------------------------------------------------------------------------------
# 3. Placebo Test (Falsification)
# pretend treatment happened 2020
# if return is significant, the model picks up noise/confounders
df_placebo <- df |>
filter(date  < as.Date("2024-01-01")) |>
mutate(
  fake_post = if_else(date >= as.Date("2020-01-01"), 1, 0),
  fake_tariff_rate = tariff_rate # base rate
  )

placebo_model <- feols(unemployment_rate ~ fake_tariff_rate:fake_post | 
                       industry_name + date,
                       data = df_placebo,
                       cluster = ~industry_name)

#--------------------------------------------------------------------------------------------------------------
# 4. Outputs / Print

print(summary(event_study_model))

print(summary(placebo_model))

png("output/figures/causal_validation_event_study.png", width = 800, height = 600)
iplot(event_study_model,
      main = "Causal Validation: Parallel Trends Test:",
      xlab = "Months Relative to Feb 2025",
      sub = "Coefficients prior to t=0 should be close to zero")
dev.off()
