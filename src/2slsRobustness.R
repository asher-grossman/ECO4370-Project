
library(tidyverse)
library(fixest)
library(modelsummary)

df <- read_csv("resources/processed/industry_panel_clean.csv")

#--------------------------------------------------------------------------------------------------------------
# 1. 
# isolate first stage to check f-stat
# F > 10 => strong IV
first_stage <- feols(tariff_rate ~ lobbying_index:post_treatment |
                     industry_name + date,
                     data = df,
                     cluster = ~industry_name)

#--------------------------------------------------------------------------------------------------------------
# 2.

# check if lobbying predicts unemployment
# if stat sig, confirms relevance
reduced_form <- feols(unemployment_rate ~ lobbying_index:post_treatment | 
                      industry_name + date,
                      data = df,
                      cluster = ~industry_name)

#--------------------------------------------------------------------------------------------------------------
# 3. 

# full 2sls model (re-estimate for ease)
iv_model <- feols(unemployment_rate ~ 1 | industry_name + date |
                  tariff_rate ~ lobbying_index:post_treatment, 
                  data = df,
                  cluster = ~industry_name) 

#--------------------------------------------------------------------------------------------------------------
# 4. 

# standard errors 2sls are unreliable if the instrument is weak
# AR test to get valid conf. intervals
iv_stats <- fitstat(iv_model, type = c("ivf", "ivwald"))

#--------------------------------------------------------------------------------------------------------------
# 5. 

print(summary(first_stage))
print(paste("First Stage F-stage:", iv_stats$ivf1))

print(summary(reduced_form))

# Diagnostic table
modelsummary(
  list("First Stage" = first_stage, "Reduced Form" = reduced_form, "2SLS" = iv_model),
  stars = TRUE,
  gof_map = c("nobs", "r.squared", "stat_f"),
  title = "IV Causal Diagnostics",
  output = "output/tables/iv_diagnostics.tex"
  )
