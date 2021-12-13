# brazil-mobility

Arjun Srinivasan, March 2021

Replication code for "[Intergenerational Educational Mobility in Brazil](https://arjunsrini.me/#brazilmobility)"

## Data

This project uses the 1996 and 2014 PNAD (National Household Sample Survey) surveys. These datasets are publicly available and can be [downloaded](https://www.ibge.gov.br/en/statistics/social/population/18079-brazil-volume-pnad1.html?=&t=downloads) from the Brazilian Institute of Geography and Statistics' website. The Department of Economics at PUC-Rio has developed a Stata package, [Data Zoom](http://www.econ.puc-rio.br/datazoom/english/index.html), that reads these text files into a tabular format.

## Build

1. Dowload the raw dataset text files.
2. Read the datasets into Stata using Data Zoom.
3. Set the file paths in `do/config.do`. Run `do/config.do`.
4. Run `.do` files in `do/clean` directory.
5. Run `.do` files in `do/analysis` directory.
6. Run `.do` files in `do/compare_meausres` directory.
7. Run all chunks in `r/plot.Rmd` in order.

## Packages (`pkgs`)

This paper relies on [Development Data Lab](https://www.devdatalab.org/) packages including [stata-tex](https://github.com/paulnov/stata-tex) and mobility programs (`mobility_programs.do`, from [this repo](https://github.com/devdatalab/paper-anr-mobility-india)) written for "[Intergenerational Mobility in India: New Methods and Estimates Across Time, Space, and Communities](http://paulnovosad.com/pdf/anr-india-mobility.pdf)", by Asher, Novosad Rafkin (2021).