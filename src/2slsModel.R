
# ==============================================================================
# 1. Setup
# ==============================================================================
library(tidyverse)
library(fixest)
library(modelsummary)
library(ggplot2)

df <- read_csv("resources/processed/industry_panel_clean.csv")

# ==============================================================================
# 2. Instrumental Variable Estimation
# ==============================================================================
# OLS (Biased)
ols_model <- feols(unemployment_rate ~ tariff_rate | industry + date, 
                   data = df, 
                   vcov = "HC1")

# 2SLS (Corrected)
# Instrument: Lobbying Index * Post_Treatment
iv_model <- feols(unemployment_rate ~ 1 | industry + date | 
                    tariff_rate ~ lobbying_index:post_treatment,
                  data = df,
                  vcov = "HC1")

# ==============================================================================
# 3. Visualization (Coefficient Comparison)
# ==============================================================================
# Step 3a: Manually extract estimates
res_ols <- broom::tidy(ols_model, conf.int = TRUE) %>% 
  filter(term == "tariff_rate") %>% 
  mutate(model = "OLS (Biased)")

res_iv  <- broom::tidy(iv_model, conf.int = TRUE) %>% 
  filter(term == "fit_tariff_rate") %>% # 2SLS calls the predicted value 'fit_...'
  mutate(model = "2SLS (Corrected)", term = "tariff_rate")

plot_data <- bind_rows(res_ols, res_iv)

# Step 3b: Plot using standard ggplot
p_compare <- ggplot(plot_data, aes(x = model, y = estimate, color = model)) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black") +
  geom_pointrange(aes(ymin = conf.low, ymax = conf.high), size = 1.2) +
  labs(
    title = "Bias Correction: OLS vs. 2SLS",
    subtitle = "Comparing the estimated impact of tariffs on unemployment",
    x = "Model Type",
    y = "Coefficient Estimate (95% CI)"
  ) +
  theme_minimal() +
  guides(color = "none") # Remove legend since x-axis labels are sufficient

# Save Plot
ggsave("output/figures/ols_vs_2sls_compare.png", plot = p_compare, width = 8, height = 5)
print(p_compare)

# ==============================================================================
# 4. Tables for Screenshot
# ==============================================================================
results_table_view <- modelsummary(
  list("OLS" = ols_model, "2SLS" = iv_model),
  stars = TRUE,
  gof_map = c("nobs", "r.squared", "stat_f"),
  coef_map = c("tariff_rate" = "Tariff Rate", 
               "fit_tariff_rate" = "Tariff Rate"),
  output = "data.frame"
)

# First Stage Diagnostics
first_stage <- summary(iv_model, stage = 1)
first_stage_table <- broom::tidy(first_stage) 

View(results_table_view)
View(first_stage_table)
