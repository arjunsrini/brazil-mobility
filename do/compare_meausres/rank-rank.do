/* 

Rank-rank gradient over time
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
// gen_wt_ranks med_bin, gen(mother_ed_rank) weight(wt) by(cohort)
gen_wt_ranks fed_bin, gen(father_ed_rank) weight(wt) by(cohort)
// gen_wt_ranks ed_bin, gen(father_ed_rank) weight(wt) by(cohort)

gen sed_bin = ed_bin if sex==0
gen ded_bin = ed_bin if sex==1

gen_wt_ranks sed_bin, gen(son_ed_rank) weight(wt) by(cohort)
// gen_wt_ranks ded_bin, gen(daughter_ed_rank) weight(wt) by(cohort)

// setup output file
cap erase $out_rr_grad
append_to_file using $out_rr_grad, s(bc,coef,se)

forval coh = 1910(10)1980 {
	reg son_ed_rank father_ed_rank if cohort==`coh'
	local bet = _b[father_ed_rank]
	local se = _se[father_ed_rank]
	append_to_file using $out_rr_grad, s(`coh',`bet',`se')
}
