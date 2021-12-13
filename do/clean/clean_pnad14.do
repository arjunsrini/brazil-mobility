/* 

clean_pnad14.do

	Cleans PNAD 2014 .dta dataset produced by db datazoom_pnad 

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

// load raw pnad2014 data
use "$raw_pnad14"

// rename varaibles
rename (v0101 uf v0102 v0103 v0301) (year state ctrl_num serial_num num_asos_w_hh_num)
rename (v0302 v3031 v3032 v3033 v8005 v0404) (sex b_day b_month b_year age race)
rename (v0606 v6007 v6070 v0608) (any_school ed_level schl_elm_length schl_prev_series )
rename (v0609 v0610 v0611) (ed_level_comp ed_level_series ed_level_series_comp)
rename (v32012 v32013 v32014) (father_ed father_ed_comp father_ed_begin)
rename (v32026 v32027 v32028) (mother_ed mother_ed_comp mother_ed_begin)
rename (v0501 v0502 v5030) (born_this_municipality born_this_state born_other_state)
rename (v9531 v9532 v9534 v9535 v9537 v9058) (inc_cash_yn inc_cash inc_goods_yn inc_goods inc_benefits hrs_worked)

// add education value labels
local yn_24_txt `" 2 "Yes" 4 "No" "'
local yn_13_txt `" 1 "Yes" 3 "No" "'
la define yn_24_label `yn_24_txt'
la define yn_13_label `yn_13_txt'

la values any_school yn_24_label
la values schl_prev_series yn_24_label
la values ed_level_comp yn_13_label
la values ed_level_series_comp yn_13_label
la values born_this_state yn_24_label
la values born_this_municipality yn_13_label

local ed_series_txt `" 1 "First" 2 "Second" 3 "Third" 4 "Fourth" 5 "Fifth" 6 "Sixth" 7 "Seventh" 8 "Eigth" 0 "Ninth" "'
la define ed_series_label `ed_series_txt'
la values ed_level_series ed_series_label

local ind_ed_txt `" 1 "Elementary (Primary)" 2 "1st Cycle / Ginásio (Lower high school)" 3 "2nd Cycle / Technical High Schoool (Scientific, Classic, etc)" 4 "1st Degree / Elementary + Middle School" 5 "2nd Degree / High School" 6 "Supplementary Elementary School, youth and adults" 7 "Supplementary High School, youth and adults" 8 "BA" 9 "MS/PhD" 10 "Literacy, youth and adults" 11 "Nursery" 12 "Literacy, CA" 13 "Nursery, kindergarten, etc." "'
la define ed_level_label `ind_ed_txt'
la values ed_level ed_level_label

local parent_ed_ltxt `" 1 "Pre-K/Kindergarten" 2 "Literacy class, CA" 3 "Literacy, youth and adults" 4 "Primary" 5 "1st Grade" 6 "2nd Grade" 7 "Elementary School" 8 "High School" 9 "BA" 10 "MS/PhD" 11 "Do not know" 12 "None" "'
la define parent_ed_label `parent_ed_ltxt'
la values father_ed parent_ed_label
la values mother_ed parent_ed_label

local genlab `" 1 "Yes" 2 "No" 3 "Don't know""'
la define yndn_label `genlab' 
la values father_ed_comp yndn_label
la values father_ed_begin yndn_label
la values mother_ed_comp yndn_label
la values mother_ed_begin yndn_label

// add demographic value labels
local sex_label_txt `" 0 "Male" 1 "Female" "'
replace sex = 0 if sex==2
replace sex = 1 if sex==4
la define sex_label `sex_label_txt'
la values sex sex_label

replace race = 4 if race==8
local race_label_txt `" 2 "White" 4 "Black" 6 "Asian" 8 "Mulatto" 0 "Indigenous" "'
la define race_label `race_label_txt'
la values race race_label

// state of birth
destring state, replace
replace born_other_state = . if born_other_state==0
replace state = . if state==0
gen birth_st = born_other_state
replace birth_st = state if born_this_state==2
replace birth_st = 1 if birth_st==0
replace birth_st = . if birth_st==1
// replace birth_st = missing(birth_st) if birth_st==0

// keep those born in brazil, in state (not federal district)
drop if birth_st==98
replace birth_st = missing(birth_st) if birth_st==53
replace birth_st = . if birth_st==0|birth_st==1
egen birth_st_id = group(birth_st)

gen birth_region = int(birth_st/10)

// local birthstlbl `" 1 "Pre-K/Kindergarten" 2 "Literacy class, CA" 3 "Literacy, youth and adults" 4 "Primary" 5 "1st Grade" 6 "2nd Grade" 7 "Elementary School" 8 "High School" 9 "BA" 10 "MS/PhD" 11 "Do not know" 12 "None" "'
// la define state_label `birthstlbl'
// la values birth_st state_label

// drop unused variables
drop v*

/****************************/
/*  Generate education bins */
/****************************/

gen ed_bin = 1 if any_school==4
replace ed_bin = 2 if (ed_level==10 | ed_level==11 | ed_level==12 | ed_level==13)
replace ed_bin = 3 if (ed_level==1 | ed_level==2 | ed_level==4 | ed_level==6)
replace ed_bin = 4 if (ed_level==3 | ed_level==5 | ed_level==7)
replace ed_bin = 5 if (ed_level==8 | ed_level==9)

gen fed_bin = 1 if father_ed==12
replace fed_bin = 2 if (father_ed==1 | father_ed==2 | father_ed==3 | father_ed ==4)
replace fed_bin = 3 if (father_ed==5 | father_ed==7)
replace fed_bin = 4 if (father_ed==6 | father_ed==8)
replace fed_bin = 5 if (father_ed==9 | father_ed==10)

gen med_bin = 1 if mother_ed==12
replace med_bin = 2 if (mother_ed==1 | mother_ed==2 | mother_ed==3 | mother_ed ==4)
replace med_bin = 3 if (mother_ed==5 | mother_ed==7)
replace med_bin = 4 if (mother_ed==6 | mother_ed==8)
replace med_bin = 5 if (mother_ed==9 | mother_ed==10)

local ed_bin_txt `" 1 "No Education" 2 "Literacy, Nursery, Kindergarten" 3 "Some Elementary/Primary/Middle School" 4 "Some High School" 5 "Some College/BA, Masters/PhD" "'
la define ed_bin_label `ed_bin_txt'
la value ed_bin ed_bin_label
la value fed_bin ed_bin_label
la value med_bin ed_bin_label

// /****************************/
// /*  Generate education bins */
// /****************************/
//
// gen ed_bin = 1 if any_school==4
// replace ed_bin = 2 if (ed_level==10 | ed_level==11 | ed_level==12 | ed_level==13 | ed_level==1 | ed_level==2 | ed_level==4 | ed_level==6)
// replace ed_bin = 3 if (ed_level==3 | ed_level==5 | ed_level==7)
// replace ed_bin = 4 if (ed_level==8 | ed_level==9)
//
// gen fed_bin = 1 if father_ed==12
// replace fed_bin = 2 if (father_ed==1 | father_ed==2 | father_ed==3 | father_ed ==4 | father_ed==5 | father_ed==7)
// replace fed_bin = 3 if (father_ed==6 | father_ed==8)
// replace fed_bin = 4 if (father_ed==9 | father_ed==10)
//
// gen med_bin = 1 if mother_ed==12
// replace med_bin = 2 if (mother_ed==1 | mother_ed==2 | mother_ed==3 | mother_ed ==4 | mother_ed==5 | mother_ed==7)
// replace med_bin = 3 if (mother_ed==6 | mother_ed==8)
// replace med_bin = 4 if (mother_ed==9 | mother_ed==10)
//
// local ed_bin_txt `" 1 "No Education" 2 "Some Elementary/Primary/Middle School" 3 "Some High School" 4 "Some College/BA, Masters/PhD" "'
// la define ed_bin_label `ed_bin_txt'
// la value ed_bin ed_bin_label
// la value fed_bin ed_bin_label
// la value med_bin ed_bin_label

/*********************/
/*  Generate cohorts */
/*********************/

// fix birth year variable (based on age)
replace b_year = 2014 - b_year if (b_year < 110)

// validate my fix to the birth year variable
// 	if dif_b_byear is always 0 or 1, then the b_year variable
//  has been fixed appropriately
gen nb_year = 2014 - age
gen dif_b_year = b_year - nb_year

// keep those of age at least 23
keep if b_year<=1990 | age>=23

// cohort variable
egen cohort = cut(b_year), at(1930(10)1990)
egen cohort2 = cut(b_year), at(1950(20)1990)

// self-weighted weight
gen wt = 1

// save data
// compress
save "$pnad14", replace

// clear
