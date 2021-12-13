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
use "$pnad14"
