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
gen_wt_ranks med_bin, gen(mother_ed_rank) weight(wt) by(cohort)
gen_wt_ranks fed_bin, gen(father_ed_rank) weight(wt) by(cohort)
// gen_wt_ranks ed_bin, gen(father_ed_rank) weight(wt) by(cohort)

gen sed_bin = ed_bin if sex==0
gen ded_bin = ed_bin if sex==1

gen_wt_ranks sed_bin, gen(son_ed_rank) weight(wt) by(cohort)
gen_wt_ranks ded_bin, gen(daughter_ed_rank) weight(wt) by(cohort)

// setup output file
cap erase $out_bh_time
append_to_file using $out_bh_time, s(type,bc,lb,ub,mu,number_moments)

// preserve
// collapse (mean) son_ed_rank, by(father_ed_rank cohort)

// local c0 son
// local c1 daughter
// preserve 

//mother 
foreach parent in father {
	foreach child in son daughter {
// 		preserve
		/* bound */
		forval coh = 1910(10)1980 {
			bound_param if cohort == `coh', s(0) t(50) xvar(`parent'_ed_rank) yvar(`child'_ed_rank) maxmom(1)
			append_to_file using $out_bh_time, s(`parent'-`child',`coh',`r(mu_lb)',`r(mu_ub)',mu0-50,`r(num_moms)')
			bound_param if cohort == `coh', s(50) t(100) xvar(`parent'_ed_rank) yvar(`child'_ed_rank) maxmom(1)
			append_to_file using $out_bh_time, s(`parent'-`child',`coh',`r(mu_lb)',`r(mu_ub)',mu50-100,`r(num_moms)')
		}
// 		restore
	}
}
