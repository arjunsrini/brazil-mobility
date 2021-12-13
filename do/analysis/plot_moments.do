/* 

Plot father-son moments
Date: February 2021
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

// get weighted ranks
gen_wt_ranks fed_bin, gen(father_ed_rank) weight(wt) by(cohort)
gen_wt_ranks ed_bin, gen(son_ed_rank) weight(wt) by(cohort)

// setup output file
// cap erase $out_prelim
// append_to_file using $out_prelim, s(year,bc,lb, ub,mu,number_moments)

// preserve
collapse (mean) son_ed_rank, by(father_ed_rank cohort)

plot_moms if cohort==1960, yvar(son_ed_rank) xvar(father_ed_rank) xtitle("Father Ed Ranks") ytitle("Son Ed Ranks") name(NonLin)
