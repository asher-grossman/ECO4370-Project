# ==============================================================================
# 1. Setup
# ==============================================================================
library(tidyverse)
library(fixest)
library(modelsummary)

# Load data that has been cleaned by src/dataProcess.R
df <- read_csv("resources/processed/industry_panel_clean.csv")

# ==============================================================================
# 2. Instrumental Variable Estimation (2SLS)
# ==============================================================================
# Structural equation: Unemployment ~ Tariff Rate
# First Stage: Tariff Rate ~ Lobbying Index (Instrument)
# Fixed Effects: Industry and Date included in both stages

# fixest syntax for IV: y ~ controls | FEs | Endogenous ~ Instrument

### FIX MISSPECIFICATION IN IV MODEL
iv_model <- feols(unemployment_rate ~ 1 | industry + date | 
                  tariff_rate ~ lobbying_index,
                  data = df,
                  cluster = ~industry)

# ==============================================================================
# 3. Diagnostics and Comparison
# ==============================================================================
# Run OLS again for comparison
# Running a basic OLS can demonstrate how endogeneity affects models (bias)
ols_model <- feols(unemployment_rate ~ tariff_rate | industry + date, 
                   data = df, cluster = ~industry)

# BASIC GUIDELINES FOR OLS vs. 2SLS COMPARISON
# If OLS < IV, it suggests tariffs were targeted at resilient industries (downward bias).
# If OLS > IV, it suggests tariffs were targeted at struggling industries (upward bias).

results_table <- modelsummary(
  list("OLS" = ols_model, "2SLS (IV)" = iv_model),
  stars = c('*' = .1, '**' = .05, '***' = .01),
  gof_map = c("nobs", "r.squared", "stat_f"), # stat_f checks first stage F-stat
  title = "OLS vs 2SLS Estimates of Tariff Impact",
  output = "output/tables/iv_comparison.tex"
)

# Print first stage diagnostics (Weak Instrument Test)
print("First Stage Diagnostics:")
summary(iv_model, stage = 1)

# end of model statement
print("2SLS Analysis Complete. Results saved to output/.")
