/* 
Analyze bottom-half mobility over time
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

// get weighted ranks
// egen cht = cut(b_year), at(1950(5)1990)
// gen_wt_ranks med_bin, gen(mother_ed_rank) weight(wt) by(cohort)
gen_wt_ranks fed_bin, gen(father_ed_rank) weight(wt) by(cohort)
// gen_wt_ranks ed_bin, gen(father_ed_rank) weight(wt) by(cohort)

gen sed_bin = ed_bin if sex==0
// gen ded_bin = ed_bin if sex==1

gen_wt_ranks sed_bin, gen(son_ed_rank) weight(wt) by(cohort)
// gen_wt_ranks ded_bin, gen(daughter_ed_rank) weight(wt) by(cohort)

// setup output file
cap erase $out_bh_st
append_to_file using $out_bh_st, s(type,state,bc,lb,ub,mu,number_moments)

// preserve
collapse (mean) son_ed_rank, by(father_ed_rank birth_region cohort)

// local c0 son
// local c1 daughter
// preserve 

//mother 
// foreach parent in father {
// 	foreach child in son {
// 		foreach i in 11 12 13 14 15 16 17 21 22 23 24 25 26 27 28 29 31 32 33 35 41 42 43 50 51 52 {
// 			forval coh = 1950(10)1970 {
// 				capture bound_param if cohort == `coh' & birth_st==`i', s(0) t(50) xvar(`parent'_ed_rank) yvar(`child'_ed_rank) maxmom(1)
// 				capture append_to_file using $out_bh_st, s(`parent'-`child',`i',`coh',`r(mu_lb)',`r(mu_ub)',mu0-50,`r(num_moms)')
// 			}
// 		}
// 	}
// }

foreach parent in father {
	foreach child in son {
		foreach i in 1 2 3 4 5 {
			forval coh = 1950(10)1980 {
				capture bound_param if cohort == `coh' & birth_region==`i', s(0) t(50) xvar(`parent'_ed_rank) yvar(`child'_ed_rank) maxmom(1)
				capture append_to_file using $out_bh_st, s(`parent'-`child',`i',`coh',`r(mu_lb)',`r(mu_ub)',mu0-50,`r(num_moms)')
			}
		}
	}
}
