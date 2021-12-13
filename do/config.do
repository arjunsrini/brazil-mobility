/* 

config.do

	Set path variables

Author: Arjun Srinivasan
Date: 	2021-02-21
	
*/

global wd "C:\Users\arjun\Dropbox\01 - Dartmouth\2020-21\ECON 64\paper\"

// original 'raw' datasets 
global raw_pnad96 "data/pnad1996pes.dta"
global raw_pnad14 "data/pnad2014pes.dta"

// cleaned data
global pnad14 "data/pnad14-clean.dta"
global pnad96 "data/pnad96-clean.dta"
global pnadF "data/pnad-full.dta"

// output
global out "output/"
global out_prelim "output/prelim_estimates.csv"
global out_prelim_race "output/prelim_estimates_by_race.csv"

// output csvs
global out_bh_time "output/bh_over_time.csv"
global out_bh_race "output/bh_by_race.csv"
global out_bh_st "output/bh_by_state.csv"
global out_p25 "output/p25.csv"
global out_rr_grad "output/rank-gradient.csv"
global out_bh_race_finer "output/bh_by_race_finer.csv"

// packages
global mob_programs "pkgs/mobility_programs.do"
global stex "pkgs/stata-tex.do"
