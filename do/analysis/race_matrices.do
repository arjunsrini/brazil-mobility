/* 

Transition matrices, by race
Date: March 2021
Author: Arjun Srinivasan

*/ 

clear
clear mata
set maxvar 10000

cd "$wd"

//load education data
use "$pnadF"

// keep sons
// keep if sex==0
drop cohort2
egen cohort2 = cut(b_year), at(1930(5)1990)

gen sed_bin = ed_bin if sex==0
// gen ded_bin = ed_bin if sex==1

// /* prepare titling */
local t2 White
local t4 Black
local t6 Asian
local t8 Mixed-Race
local t0 Indigenous

// preserve
replace race = 4 if race==8

/* extract bounds, looping over race */
foreach race in 2 4 {
	display "Race: `t`race''"
	forval coh = 1950(5)1980 {
		display "Cohort: `coh'"
		tab fed_bin ed_bin if cohort2==`coh' & race==`race'
	}
}
