/* 

merge_pnads.do

	Merges cleaned PNAD 1996 and 2014 data

Author: Arjun Srinivasan
Date: 	2021-02-28
	
*/

clear
set more off

// change to project directory
cd "$wd"

/*****************************/
/*  Get variables and labels */
/*****************************/

// load raw pnad2014 data
use "$pnad14"

// append 1996 data
append using "$pnad96"

// keep cohorts
drop if missing(cohort)

// save
save "$pnadF", replace
