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
        - Self-built CSV of general tariff rates
        - ^ Constructed based on goverment published articles/briefs
## Repo Structure:  
    ECO4370-Project/
    ├── README.md                     # Project overview and instructions
    ├── .gitignore                    # Files to ignore
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
