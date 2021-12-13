/* 
Ed mobility estimates for Brazil
Date: February 2021
Author: Arjun Srinivasan

Based off of: 
File: 'prep_ed_mob_comparisons.do'
Date: August 2018
Author: Charlie Rafkin
*/ 

clear
clear mata
set maxvar 10000

cd "$wd"

// run mobility programs
run $mob_programs
run $stex

//load education data
use "$pnad14"

// get weighted ranks
gen_wt_ranks fed_bin, gen(father_ed_rank) weight(wt) by(cohort)
gen_wt_ranks ed_bin, gen(son_ed_rank) weight(wt) by(cohort)

// setup output file
cap erase $out_prelim
append_to_file using $out_prelim, s(year,bc,lb, ub,mu,number_moments)

// preserve
collapse (mean) son_ed_rank, by(father_ed_rank cohort)

/* bound */
forval coh = 1930(10)1960 {
	bound_param if cohort == `coh', s(0) t(50) xvar(father_ed_rank) yvar(son_ed_rank) maxmom(1)
	append_to_file using $out_prelim, s(2014,`coh',`r(mu_lb)',`r(mu_ub)',mu0-50,`r(num_moms)')
}

/* PNAD 1996 */

clear
use "$pnad96"

// get weighted ranks
gen_wt_ranks fed_bin, gen(father_ed_rank) weight(wt) by(cohort)
gen_wt_ranks ed_bin, gen(son_ed_rank) weight(wt) by(cohort)

// setup output file
// cap erase $out_prelim
// append_to_file using $out_prelim, s(lb, ub, bc, mu, country, race,number_moments)

// preserve
collapse (mean) son_ed_rank, by(father_ed_rank cohort)

/* bound */
forval coh = 1930(10)1960 {
	bound_param if cohort == `coh', s(0) t(50) xvar(father_ed_rank) yvar(son_ed_rank) maxmom(1)
	append_to_file using $out_prelim, s(1996,`coh',`r(mu_lb)',`r(mu_ub)',mu0-50,`r(num_moms)')
}
