/* 
Income distribution by father ed rank
Date: March 2021
Author: Arjun Srinivasan

*/ 

clear
clear matrix
clear mata
set maxvar 10000

cd "$wd"

// run mobility programs
run $mob_programs
run $stex

//load education data
use "$pnadF"


twoway (histogram ed_bin if race==2, width(1) color(green)) ///
       (histogram ed_bin if race==4, width(1) ///
	   fcolor(none) lcolor(black)), legend(order(1 "White" 2 "Black" ))
