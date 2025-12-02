# ECO 4370 Final Project
## Overview
    - What is the net affect of the Trump Administration's 2025 Tariffs?
    Follow-ups:
      - Which industries seem to be affected most?
      - Do tariffs on trade rivals have amplified or diminshed effects?

## Data Sources
    - FRED Unemployment Data as 'series ID' & (Sector Name):
        - 'LNU04032232' (Manufacturing)
        - 'LNU04032231' (Construction)
        - 'LNU04032237' (Information)
        - 'LNU04032241' (Leisure & Hospitality)
        - 'LNU04032230' (Mining)
        - 'LNU04032238' (Financial Activities)
    - USITC (Trump Admin):
        - **** NEED TO BUILD Tariff SCHEDULE IN CSV (OR FIX HTS SCEDULE)
    
    - LIST OUT ALL SOURCES AND LINKS WITH BRIEF BULLET FOR DESCRIPTION/LOCATION

## Repo Structure (remove Rproj?):  
    ECO4370-Project/
    ├── README.md                     # Project overview and instructions
    ├── .gitignore                    # Files to ignore
    ├── ECO4370-Project.Rproj         # RStudio Project file
    ├── src/                          # R Files
    │   ├── dataProcessor.R           # ETL: Fetch FRED data, clean, and merge
    │   ├── didModel.R                # Difference-in-Differences Analysis
    │   └── 2slsModel.R               # Instrumental Variables Analysis
    ├── resources/                    # Data 
    │   ├── raw/                      # Original datasets (immutable)
    │   │   └── tariff_schedules.csv  # Gathered from Trump admin postings
    │   └── processed/                # Cleaned data ready for use
    │       └── industry_panel_clean.csv
    └── output/                       # Files generated from 'src' files
        ├── tables/                   # LaTeX/HTML regression tables
        └── figures/                  # Plots (in PNG/PDF)

## Results / Findings
    - PLACEHOLDER 
     ** Add general results/conclusions abstract
     ** State major drawbacks/violations

## Citations? 
    - Maybe add this to Data Sources section or just after it
    - INCLUDE REFERENCES FOR CODE/ML papers

## Steps to replicate
    - Write out logic process
    - What order to run files/gather data
    - Any major references that are required for exact replication
    - INCLUDE SEED SETTINGS AND R VERSION / PACKAGES
      - NOTE DATES FOR DATA SETS AND 2025 GOVERNMENT SHUTDOWN 
