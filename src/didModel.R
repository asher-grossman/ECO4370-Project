# ==============================================================================
# 1. Setup
# ==============================================================================
library(tidyverse)
library(fixest)       # Online posts described as best for high-dimensional fixed effects
library(modelsummary) # Used for professional replicability -> high quality tables
library(ggplot2)

# Create output directories
# FIX DIRECTORY PATHS
dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)

# use CLEAN (PROCESSED) data
# aka data that has been ran through dataProcess 
df <- read_csv("resources/processed/industry_panel_clean.csv")

# ==============================================================================
# 2. Descriptive Checks
# ==============================================================================
# Here, we check the treatment variation
print("Summary of Tariff Rates by Post-Treatment Status:")
table(df$post_treatment, df$tariff_rate)

# ==============================================================================
# 3. Generalized DiD Estimation (Two-Way Fixed Effects)
# ==============================================================================
# Model (in layman's terms): Unemployment ~ Tariff Exposure | Industry FE + Date FE
# We use tariff_rate as a continuous treatment variable

did_model <- feols(unemployment_rate ~ tariff_rate | 
                   industry + date, 
                   data = df, 
                   cluster = ~industry) # Cluster SEs by industry

print(summary(did_model))

# Export Regression Table
modelsummary(
  list("DiD (TWFE)" = did_model),
  stars = TRUE,
  gof_map = c("nobs", "r.squared", "within.r.squared"),
  title = "Impact of 2025 Tariffs on Unemployment Rate",
  output = "output/tables/did_results.tex" # tex was easiest, can be html or pdf if preferred
)

options("modelsummary_format_numeric_latex" = "plain") # Avoid scientific notation in LaTeX output
# ==============================================================================
# 4. Event Study (Testing Parallel Trends)
# ==============================================================================
# We define "time_to_treatment" relative to Feb 2025.
df <- df %>%
  mutate(
    # Create a numeric date for ordering
    date_num = as.numeric(date),
    # Time relative to Feb 1, 2025 (in months)
    time_to_treat = interval(as.Date("2025-02-01"), date) / months(1)
  )

# Run the event -> We observe the interactions between tariff rate and time dummies
# Reference period: -1 (January 2025, one month before tariffs)
# Delay ^^ because tariffs take time to affect (observed effect is not immediate)
event_study <- feols(unemployment_rate ~ i(time_to_treat, tariff_rate, ref = -1) | 
                     industry + date,
                     data = df,
                     cluster = ~industry)

# Plot
p <- iplot(event_study, 
           main = "Event Study: Effect of Tariff Exposure on Unemployment",
           xlab = "Months Relative to Feb 2025",
           ylab = "Coefficient Estimate (95% CI)")

# Save plot as image (.png, .jpeg. whatever people prefer)
png("output/figures/event_study_plot.png", width = 800, height = 600)
iplot(event_study, 
      main = "Event Study: Effect of Tariff Exposure on Unemployment",
      xlab = "Months Relative to Feb 2025",
      ylab = "Coefficient Estimate")
dev.off()

print("DiD Analysis Complete. Results saved to output/.")

