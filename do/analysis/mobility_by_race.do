/* 
Analyze bottom-half mobility over time, by race
Date: March 2021
Author: Arjun Srinivasan

*/ 

clear
clear mata
set maxvar 10000

cd "$wd"

// run mobility programs
run $mob_programs
run $stex

//load education data
use "$pnadF"

// keep sons
// keep if sex==0

egen cohort2 = cut(b_year), at(1930(5)1990)

// get weighted ranks
gen_wt_ranks fed_bin, gen(father_ed_rank) weight(wt) by(cohort2)
// gen_wt_ranks ed_bin, gen(son_ed_rank) weight(wt) by(cohort)

gen sed_bin = ed_bin if sex==0
gen ded_bin = ed_bin if sex==1

gen_wt_ranks sed_bin, gen(son_ed_rank) weight(wt) by(cohort2)
// gen_wt_ranks ded_bin, gen(daughter_ed_rank) weight(wt) by(cohort)

// setup output file
cap erase $out_bh_race
append_to_file using $out_bh_race, s(Race, bc, lb, ub, mu, number_moments)

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
	forval coh = 1950(5)1980 {
		bound_param if cohort2 == `coh' & race == `race', s(0) t(50) xvar(father_ed_rank) yvar(son_ed_rank) maxmom(1)
		append_to_file using $out_bh_race, s(`t`race'',`coh',`r(mu_lb)',`r(mu_ub)',mu0-50,`r(num_moms)')
		bound_param if cohort2 == `coh' & race == `race', s(50) t(100) xvar(father_ed_rank) yvar(son_ed_rank) maxmom(1)
		append_to_file using $out_bh_race, s(`t`race'',`coh',`r(mu_lb)',`r(mu_ub)',mu50-100,`r(num_moms)')
	}
}
