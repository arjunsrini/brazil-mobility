/* 

clean_pnad96.do

	Cleans PNAD 1996 .dta dataset produced by db datazoom_pnad 

Author: Arjun Srinivasan
Date: 	2021-02-21
	
*/

clear
set more off

// change to project directory
cd "$wd"

/*****************************/
/*  Get variables and labels */
/*****************************/

// load raw pnad1996 data
use "$raw_pnad96"

// rename varaibles
rename (v0101 uf v0102 v0103 v0301) (year state ctrl_num serial_num num_asos_w_hh_num)
rename (v0302 v3031 v3032 v3033 v8005 v0404) (sex b_day b_month b_year age race)
rename (v0606 v0607) (any_school ed_level)
rename (v1217) (father_ed)
rename (v1219) (mother_ed)
rename (v0501 v0502 v5030) (born_this_municipality born_this_state born_other_state)

// add education value labels
local yn_24_txt `" 2 "Yes" 4 "No" "'
local yn_13_txt `" 1 "Yes" 3 "No" "'
la define yn_24_label `yn_24_txt'
la define yn_13_label `yn_13_txt'

// replace as missing then label
replace any_school = missing(any_school) if any_school==9
la values any_school yn_24_label

// replace as missing then label
replace ed_level = missing(ed_level) if ed_level==0
local ind_ed_txt `" 1 "Elementary (Primary)" 2 "1st Cycle / Ginásio (Lower high school)" 3 "2nd Cycle / Technical High Schoool (Scientific, Classic, etc)" 4 "1st Degree / Elementary School" 5 "2nd Degree / Middle + High School" 6 "BA / Some College" 7 "MS/PhD" 8 "Literacy, for adults" 9 "Preschool or day care" "'
la define ed_level_label_96 `ind_ed_txt'
la values ed_level ed_level_label_96

// replace as missing then label
replace father_ed = missing(father_ed) if father_ed==99
replace mother_ed = missing(mother_ed) if mother_ed==99
local parent_ed_ltxt `" 1 "No school" 2 "Some Primary School (<4th Grade)" 3 "Primary School(4th Grade)" 4 "Some Middle School (> 5th Grade)" 5 "Middle School(8th Grade)" 6 "Some High School (> 9th Grade)" 7 "High School (11th Grade)" 8 "Some College/BA" 9 "BA" 10 "MS/PhD" 11 "Do not know" "'
la define parent_ed_label_96 `parent_ed_ltxt'
la values father_ed parent_ed_label_96
la values mother_ed parent_ed_label_96

// add demographic value labels
local sex_label_txt `" 0 "Male" 1 "Female" "'
replace sex = 0 if sex==2
replace sex = 1 if sex==4
la define sex_label `sex_label_txt'
la values sex sex_label

// replace as missing and add label
replace race = missing(race) if race==9
replace race = 4 if race==8
local race_label_txt `" 2 "White" 4 "Black" 6 "Asian" 8 "Mulatto" 0 "Indigenous" "'
la define race_label `race_label_txt'
la values race race_label

// state of birth
destring state, replace
gen birth_st = born_other_state
replace birth_st = state if born_this_state==2
replace birth_st = missing(birth_st) if birth_st==99|birth_st==53
replace birth_st = . if birth_st<1
// keep those born in brazil
// set federal distring to missing
drop if birth_st==98
egen birth_st_id = group(birth_st)

gen birth_region = int(birth_st/10)

// drop unused variables
drop v*

/****************************/
/*  Generate education bins */
/****************************/

gen ed_bin = 1 if (any_school==4 | ed_level==9)
replace ed_bin = 2 if (ed_level==8)
replace ed_bin = 3 if (ed_level==1 | ed_level==2 | ed_level==4)
replace ed_bin = 4 if (ed_level==3 | ed_level==5)
replace ed_bin = 5 if (ed_level==6 | ed_level==7)

gen fed_bin = 1 if father_ed==1
replace fed_bin = 2 if (father_ed==2)
replace fed_bin = 3 if (father_ed==3 | father_ed==4 | father_ed==5)
replace fed_bin = 4 if (father_ed==6 | father_ed==7)
replace fed_bin = 5 if (father_ed==8 | father_ed==9 | father_ed==10)

gen med_bin = 1 if mother_ed==1
replace med_bin = 2 if (mother_ed==2)
replace med_bin = 3 if (mother_ed==3 | mother_ed==4 | mother_ed==5)
replace med_bin = 4 if (mother_ed==6 | mother_ed==7)
replace med_bin = 5 if (mother_ed==8 | mother_ed==9 | mother_ed==10)

local ed_bin_txt `" 1 "No Education" 2 "Literacy, Nursery, Kindergarten" 3 "Some Elementary/Primary/Middle School" 4 "Some High School" 5 "Some College/BA, Masters/PhD" "'
la define ed_bin_label `ed_bin_txt'
la value ed_bin ed_bin_label
la value fed_bin ed_bin_label
la value med_bin ed_bin_label

// /****************************/
// /*  Generate education bins */
// /****************************/
//
// gen ed_bin = 1 if (any_school==4 | ed_level==9)
// replace ed_bin = 2 if (ed_level==8 | ed_level==1 | ed_level==2 | ed_level==4)
// replace ed_bin = 3 if (ed_level==3 | ed_level==5)
// replace ed_bin = 4 if (ed_level==6 | ed_level==7)
//
// gen fed_bin = 1 if father_ed==1
// replace fed_bin = 2 if (father_ed==2 | father_ed==3 | father_ed==4 | father_ed==5)
// replace fed_bin = 3 if (father_ed==6 | father_ed==7)
// replace fed_bin = 4 if (father_ed==8 | father_ed==9 | father_ed==10)
//
// gen med_bin = 1 if mother_ed==1
// replace med_bin = 2 if (mother_ed==2 | mother_ed==3 | mother_ed==4 | mother_ed==5)
// replace med_bin = 3 if (mother_ed==6 | mother_ed==7)
// replace med_bin = 4 if (mother_ed==8 | mother_ed==9 | mother_ed==10)
//
// local ed_bin_txt `" 1 "No Education" 2 "Some Elementary/Primary/Middle School" 3 "Some High School" 4 "Some College/BA, Masters/PhD" "'
// la define ed_bin_label `ed_bin_txt'
// la value ed_bin ed_bin_label
// la value fed_bin ed_bin_label
// la value med_bin ed_bin_label

/*********************/
/*  Generate cohorts */
/*********************/

// replace as missing
replace b_year = missing(b_year) if age==999
replace age = missing(age) if age==999

// fix birth year variable
// replace b_year = 2014 - b_year if (b_year < 110)
replace b_year = 1000 + b_year if b_year>100
replace b_year = 1996 - age if b_year<100

// validate my fix to the birth year variable
// 	if dif_b_byear is always 0 or 1, then the b_year variable
//  has been fixed appropriately
gen nb_year = 1996 - age
gen dif_b_year = b_year - nb_year

// keep those of age at least 23
keep if age>=23 | b_year<=1972
// keep if b_year<=1972

// cohort variable
egen cohort = cut(b_year), at(1910(10)1970)

// self-weighted weight
gen wt = 1

// save data
// compress
save "$pnad96", replace

// clear
