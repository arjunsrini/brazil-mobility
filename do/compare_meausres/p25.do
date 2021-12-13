/* 

p25 over time
Date: March 2021
Author: Arjun Srinivasan

*/ 

clear
clear mata
clear matrix
set maxvar 10000

cd "$wd"

// run mobility programs
run $mob_programs
run $stex

//load education data
use "$pnadF"

// get weighted ranks
gen_wt_ranks med_bin, gen(mother_ed_rank) weight(wt) by(cohort)
gen_wt_ranks fed_bin, gen(father_ed_rank) weight(wt) by(cohort)
// gen_wt_ranks ed_bin, gen(father_ed_rank) weight(wt) by(cohort)

gen sed_bin = ed_bin if sex==0
gen ded_bin = ed_bin if sex==1

gen_wt_ranks sed_bin, gen(son_ed_rank) weight(wt) by(cohort)
gen_wt_ranks ded_bin, gen(daughter_ed_rank) weight(wt) by(cohort)

// setup output file
cap erase $out_p25
append_to_file using $out_p25, s(type,bc,lb,ub,mu,number_moments)

forval coh = 1910(10)1980 {
	bound_param if cohort == `coh', s(25) t(25) xvar(father_ed_rank) yvar(son_ed_rank) maxmom(1)
	append_to_file using $out_p25, s(`parent'-`child',`coh',`r(mu_lb)',`r(mu_ub)',p25,`r(num_moms)')
}
