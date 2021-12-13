// This is a modified version of mobility_programs.do
// See ANR's version here: https://github.com/devdatalab/paper-anr-mobility-india/blob/master/mobility_programs.do

qui {

  /**************************************************************************************/
  /* program gen_wt_ranks : Generates midpoint ranks for a given variable               */
  /* - sample use: gen_ed_ranks, gen(ed_rank) .... or gen(ed_rank_agecut)               */
  /* - sample use: gen_ed_ranks son_ed [if], gen(son_ed_rank) weight(weight) by(decade) */
  /**************************************************************************************/
  cap prog drop gen_wt_ranks
  prog def gen_wt_ranks
  {
    syntax varname [if], [GENerate(name) by(varname)] Weight(varname)
//     cap drop __rank __min_rank __max_rank __by __number_of_people
  
    if mi("`weight'") {
      tempvar weight
      gen `weight' = 1
    }
    
    if mi("`by'") {
      gen __by = 1
      local by __by
    }
    sort `by'

    tokenize `varlist'
    
    /* add an if clause when varname is missing */
    if !mi("`if'") {
      local if `if' & !mi(`1')
    }
    else {
      local if if !mi(`1')
    }

    /* generate the total number of weights == size of total population */
    by `by': egen __number_of_people = total(`weight') `if'
  
    /* sort according to variable of interest (e.g. education) */
    sort `by' `1' `weight'
    
    /* obtain a rolling sum of weights,  */
    by `by': gen __rank = sum(`weight') `if'
    
    /* within each variable group, obtain the minimum and maximum ranks */
    by `by' `1': egen __min_rank = min(__rank) `if'
    by `by' `1': egen __max_rank = max(__rank) `if'
    
    /* replace the rank as the mean of those rolling sums, and divide by the number of people */
    gen `generate' = 100 * (__min_rank + __max_rank) / (2 * __number_of_people) `if'
    
    /* drop clutter */        
    cap drop __rank __min_rank __max_rank __number_of_people __by 
	drop __number_of_people
	drop __rank
	drop __min_rank
	drop __max_rank
// 	drop __by
  
  }
  end
  /* *********** END program gen_wt_ranks ***************************************** */

  /**********************************************************************************/
  /* program is_monotonic : reports whether parent/child distribution is monotonic   */
  // sample usage: is_monotonic, x(father_ed_rank) y(son_ed_rank) weight(weight)
  // return value: `r(is_monotonic)' is 1 if monotonic, 0 if not
  /**********************************************************************************/
  cap prog drop is_monotonic
  prog def is_monotonic, rclass
    {
      syntax [if], x(varname) y(varname) [weight(varname) preserve_ranks]
      
      /* manage weights */
      if !mi("`weight'") {
        local wt_string [aw=`weight']
        local wt_passthru weight(`weight')
      }
      else {
        local wt_string
        local wt_passthru
      }
      
      /* create integer groups for X variable */
      sort `x'
      qui egen __xgroup  = group(`x') `if'
      
      sum __xgroup, meanonly
      local n = `r(max)' - 1
      local is_mono 1

      forval x_current = 1/`n' {
        
        local x_next = `x_current' + 1
        
        /* calculate diff from this point to next */
        qui sum `y' `wt_string' if __xgroup == `x_current'
        local y_current = `r(mean)'
        
        qui sum `y' `wt_string' if __xgroup == `x_next'
        local y_next = `r(mean)'
        
        local diff = `y_next' - `y_current'

        /* report whether monotonic or not */
        if `diff' < 0 {
          return local is_monotonic 0
          continue, break 
        }
        else {
          return local is_monotonic 1
        }
      }
      cap drop __xgroup
    }
  end
  /* *********** END program is_monotonic ***************************************** */
  
  /**********************************************************************************/
  /* program bound_param : generate analytical bounds on mu or p */ 
  /* s: lower bound */
  /* t: upper bound */
  /* if s = t, then this returns the bounds on p_s = p_t  */

  /* sample use:
  // calculate p25
  bound_param [aw pw] [if], xvar(father_ed_rank) yvar(son_ed_rank_decade) s(25) t(25) [by(birth_cohort)]
  
  // calculate mu50
  bound_param [aw pw] [if], xvar(father_ed_rank) yvar(son_ed_rank_decade) s(0) t(50) [by(birth_cohort)]
  */
  
  /***********************************************************************************/
  capture prog drop bound_param 
  prog def bound_param, rclass
    
    syntax [aweight pweight] [if], xvar(string) yvar(string) [s(real 0) t(real 50) maxmom(real 100) minmom(real 0) append(string) str(string) forcemono QUIet verbose] 

    preserve

    qui {

      /* keep if if */
      if !mi("`if'") {
        keep `if'
        local ifstring "`if'"
      }

      /* only use "noi" if verbose is specified */
      if !mi("`verbose'") {
        local noi noisily
      }
      
      /* require non-missing xvar and yvar */
      count if mi(`xvar') | mi(`yvar')
      if `r(N)' > 0  & ("`verbose'" != "") {
        `noi' disp "Warning: ignoring `r(N)' rows that are missing `xvar' or `yvar'."
      }
      keep if !mi(`xvar') & !mi(`yvar')

      /* fail with an error message if there's no data left */
      qui count
      if `r(N)' < 2 {
        disp as error "bound_param: Only `r(N)' observations left in sample; cannot bound anything."
        error 456
      }
      
      // Create convenient weight local
      if ("`weight'" != "") {
        local wt [`weight'`exp']
        local longweight = "weight(" + substr("`exp'", 2, .) + ")"
      }

      /* if not monotonic */
      is_monotonic, x(`xvar') y(`yvar') `longweight'
      if `r(is_monotonic)' == 0 {

        /* combine bins to force monotonicity if requested */
        if !mi("`forcemono'") {
          `noi' make_monotonic, x(`xvar') y(`yvar') `longweight' preserve_ranks
          make_monotonic, x(`xvar') y(`yvar') `longweight' preserve_ranks
        }

        /* otherwise fail */
        else {
          display as error "ERROR: bound_param cannot estimate mu with non-monotonic moments"
          local FAILED 1
        }
      }
      
      /* sort by the x variable */
      sort `xvar'
      
      /* collapse on xvar [does nothing if data is already collapsed] */
      collapse (mean) `yvar' `wt' , by(`xvar')
      
      /* rename variables for convenience */
      ren `yvar' y_moment
      ren `xvar' x_moment

      /************************************************/
      /* STEP 1: get moments/cuts  */
      /************************************************/

      /* obtain the cuts from the midpoints */
      sort x_moment
      gen xcuts = x_moment[1] * 2 if _n == 1
      local n = _N
      
      forv i = 2/`n' {
        replace xcuts = (x_moment - xcuts[_n-1]) * 2 + xcuts[_n-1] if _n == `i' 
      }
      replace xcuts = 100 if _n == _N 
      
      /**************************************************/
      /* STEP 2: CONVERT PARAMETERS TO LOCALS */
      /**************************************************/
      /* obtain important parameters and put into locals */
      forv i = 1/`n' {
        
        local y_moment_next_`i' = y_moment[`i'+1]
        local y_moment_prior_`i' = y_moment[`i'-1]
        local y_moment_`i' = y_moment[`i']
        local x_moment_`i' = x_moment[`i']
        local min_bin_`i' = xcuts[`i'-1]
        local max_bin_`i' = xcuts[`i']
        
        local min_bin_1 = 0 
        local max_bin_`n' = 100 
        local y_moment_prior_1 = `minmom' 
        local y_moment_next_`n' = `maxmom' 
        
        /* get the star for each bin */
        local star_bin_`i' = (`y_moment_next_`i'' * `max_bin_`i'' - (`max_bin_`i'' - `min_bin_`i'') * `y_moment_`i'' - `min_bin_`i'' * `y_moment_prior_`i'' ) / ( `y_moment_next_`i'' - `y_moment_prior_`i'' )
        
        /* close loop over bins */
        
      }
      
      /* determine the bin that s and t are in */
      forv i = 1/`n' {
        
        if `min_bin_`i'' <= `t' & `max_bin_`i'' >= `t' { 
          local bin_t = `i'
        }
        
        if `min_bin_`i'' <= `s' & `max_bin_`i'' >= `s' { 
          local bin_s = `i'
        }
        
      }    
      
      /* make everything easier to reference by dropping the end index */
      foreach variable in min_bin max_bin y_moment_prior y_moment_next y_moment x_moment star_bin {
        local `variable'_t = ``variable'_`bin_t''
        local `variable'_s = ``variable'_`bin_s''
      }
      
      /***************************/
      /* STEP 3: GET THE BOUNDS  */
      /***************************/
      
      /* get the analytical lower bound */
      if (`t' < `star_bin_t') local analytical_lower_bound_t = `y_moment_prior_t' 
      if (`t' >= `star_bin_t') local analytical_lower_bound_t = 1/(`t' - `min_bin_t') * ( (`max_bin_t' - `min_bin_t') * `y_moment_t' - (`max_bin_t' - `t') * `y_moment_next_t' )
      
      /* get the analytical upper bound */
      if (`s' < `star_bin_s') local analytical_upper_bound_s = 1/(`max_bin_s' - `s') * ((`max_bin_s' - `min_bin_s' )* `y_moment_s' - (`s' - `min_bin_s') * `y_moment_prior_s' )
      if (`s' >= `star_bin_s') local analytical_upper_bound_s = `y_moment_next_s'
      
      /* if the t value is not in the same bin as s, average the determined value of the moments in prior bins, plus the analytical
      lower bound times the proportion of mu_0^t it constitutes */
      if `bin_t' != `bin_s' {
        
        local bin_t_minus_1 = `bin_t' - 1
        local bin_s_plus_1 = `bin_s' + 1
        
        /* add the determined portion, mu_prime, only if there is a full bin in between s and t  */      
        if `bin_t' - `bin_s' >= 2 {
          local mu_prime = 0 
          /* obtain the weighted value of the moments between s and t  */  
          forv i = `bin_s_plus_1'/`bin_t_minus_1' {
            local bin_size_`i' = `max_bin_`i'' - `min_bin_`i''         
            local wt =  `bin_size_`i'' / (`t' - `s') * `y_moment_`i'' 
            local mu_prime = `mu_prime' + `wt'
          }
        }      
        else {
          local mu_prime = 0
        }
        di "`mu_prime'" 
        /* put this together with the determined portion of the parameter */  
        local lb_mu_s_t = `mu_prime' + (`t' - max(`max_bin_`bin_t_minus_1'',`s') ) / (`t' - `s') * `analytical_lower_bound_t' + (`max_bin_s' - `s') / (`t' - `s') * `y_moment_s' * (`bin_s' != `bin_t') 
        local ub_mu_s_t = `mu_prime' + (`t' - `max_bin_`bin_t_minus_1'' ) / (`t' - `s') * `y_moment_t' * (`bin_s' != `bin_t') + (min(`max_bin_s',`t') - `s') / (`t' - `s') * `analytical_upper_bound_s' 
      }
      
      /* if the t IS in the same interval as s, the bounds are simpler to compute: just take the analytical lower bound of t, or the analytical upper bound of s */
      if `bin_t' == `bin_s' {
        local lb_mu_s_t = `analytical_lower_bound_t'
        local ub_mu_s_t = `analytical_upper_bound_s'
      }
      
      /* return the locals that are desired */
      if "`FAILED'" != "1" {
        return local t = `t'
        return local s = `s'
        return local mu_lower_bound = `lb_mu_s_t'
        return local mu_upper_bound = `ub_mu_s_t'                     
        return local mu_lb = `lb_mu_s_t'
        return local mu_ub = `ub_mu_s_t'                     
        return local star_bin_s = `star_bin_s'
        return local star_bin_t = `star_bin_t'    
        return local num_moms = _N
      }
    }

    if "`FAILED'" != "1" {
      local rd_lb_mu_s_t: di %6.3f `lb_mu_s_t'
      local rd_ub_mu_s_t: di %6.3f `ub_mu_s_t'

      if mi("`quiet'") {      
        di `" Mean `yvar' in(`s', `t') is in [`rd_lb_mu_s_t', `rd_ub_mu_s_t'] "'   
      }
      
      if !mi("`append'") {
        append_to_file using `append', s(`str',`rd_lb_mu_s_t', `rd_ub_mu_s_t')
      }
    }
    else {
      return local t = `t'
      return local s = `s'
      return local mu_lower_bound = .
      return local mu_upper_bound = .
      return local mu_lb = .
      return local mu_ub = .
      return local star_bin_s = .
      return local star_bin_t = .
      return local num_moms = _N
    }
    /* close program */
    restore
  end
  /* *********** END program bound_param ***************************************** */
  
  /************************************************************************/
  /* program bound_mobility : generate analytical bounds on mobility CEFs */ 
  /* s: low end of parent rank interval (defaults to 0 for bottom half mobility) */
  /* t: high end of parent rank interval (defaults to 50 for bottom half mobility) */
  /* if s = t, then this returns the bounds on p_s = p_t  */

  /* sample use:
  // calculate p25
  bound_mobility [aw pw] [if], xvar(father_ed_rank) yvar(son_ed_rank_decade) s(25) t(25) [by(birth_cohort)]
  
  // calculate mu50
  bound_mobility [aw pw] [if], xvar(father_ed_rank) yvar(son_ed_rank_decade) s(0) t(50) [by(birth_cohort)]
  */
  
  /***********************************************************************************/
  capture prog drop bound_mobility 
  prog def bound_mobility, rclass
    
    syntax [aweight pweight] [if], xvar(string) yvar(string) [s(real 0) t(real 50) append(string) str(string) forcemono QUIet verbose] 

    preserve

    qui {

      /* keep if if */
      if !mi("`if'") {
        keep `if'
        local ifstring "`if'"
      }

      /* only use "noi" if verbose is specified */
      if !mi("`verbose'") {
        local noi noisily
      }
      
      /* require non-missing xvar and yvar */
      count if mi(`xvar') | mi(`yvar')
      if `r(N)' > 0  & ("`verbose'" != "") {
        `noi' disp "Warning: ignoring `r(N)' rows that are missing `xvar' or `yvar'."
      }
      keep if !mi(`xvar') & !mi(`yvar')

      /* fail with an error message if there's no data left */
      qui count
      if `r(N)' < 2 {
        disp as error "bound_mobility: Only `r(N)' observations left in sample; cannot bound anything."
        error 456
      }
      
      // Create convenient weight local
      if ("`weight'" != "") {
        local wt [`weight'`exp']
        local longweight = "weight(" + substr("`exp'", 2, .) + ")"
      }

      /* if not monotonic */
      is_monotonic, x(`xvar') y(`yvar') `longweight'
      if `r(is_monotonic)' == 0 {

        /* combine bins to force monotonicity if requested */
        if !mi("`forcemono'") {
          `noi' make_monotonic, x(`xvar') y(`yvar') `longweight' preserve_ranks
          make_monotonic, x(`xvar') y(`yvar') `longweight' preserve_ranks
        }

        /* otherwise fail */
        else {
          display as error "ERROR: bound_mobility cannot estimate mu with non-monotonic moments"
          local FAILED 1
        }
      }
      
      /* sort by the x variable */
      sort `xvar'
      
      /* collapse on xvar [does nothing if data is already collapsed] */
      collapse (mean) `yvar' `wt' , by(`xvar')
      
      /* rename variables for convenience */
      ren `yvar' y_moment
      ren `xvar' x_moment

      /************************************************/
      /* STEP 1: get moments/cuts  */
      /************************************************/

      /* obtain the cuts from the midpoints */
      sort x_moment
      gen xcuts = x_moment[1] * 2 if _n == 1
      local n = _N
      
      forv i = 2/`n' {
        replace xcuts = (x_moment - xcuts[_n-1]) * 2 + xcuts[_n-1] if _n == `i' 
      }
      replace xcuts = 100 if _n == _N 
      
      /**************************************************/
      /* STEP 2: CONVERT PARAMETERS TO LOCALS */
      /**************************************************/
      /* obtain important parameters and put into locals */
      forv i = 1/`n' {
        
        local y_moment_next_`i' = y_moment[`i'+1]
        local y_moment_prior_`i' = y_moment[`i'-1]
        local y_moment_`i' = y_moment[`i']
        local x_moment_`i' = x_moment[`i']
        local min_bin_`i' = xcuts[`i'-1]
        local max_bin_`i' = xcuts[`i']
        
        local min_bin_1 = 0 
        local max_bin_`n' = 100 
        local y_moment_prior_1 = 0
        local y_moment_next_`n' = 1
        
        /* get the star for each bin */
        local star_bin_`i' = (`y_moment_next_`i'' * `max_bin_`i'' - (`max_bin_`i'' - `min_bin_`i'') * `y_moment_`i'' - `min_bin_`i'' * `y_moment_prior_`i'' ) / ( `y_moment_next_`i'' - `y_moment_prior_`i'' )
        
        /* close loop over bins */
        
      }
      
      /* determine the bin that s and t are in */
      forv i = 1/`n' {
        
        if `min_bin_`i'' <= `t' & `max_bin_`i'' >= `t' { 
          local bin_t = `i'
        }
        
        if `min_bin_`i'' <= `s' & `max_bin_`i'' >= `s' { 
          local bin_s = `i'
        }
        
      }    
      
      /* make everything easier to reference by dropping the end index */
      foreach variable in min_bin max_bin y_moment_prior y_moment_next y_moment x_moment star_bin {
        local `variable'_t = ``variable'_`bin_t''
        local `variable'_s = ``variable'_`bin_s''
      }
      
      /***************************/
      /* STEP 3: GET THE BOUNDS  */
      /***************************/
      
      /* get the analytical lower bound */
      if (`t' < `star_bin_t') local analytical_lower_bound_t = `y_moment_prior_t' 
      if (`t' >= `star_bin_t') local analytical_lower_bound_t = 1/(`t' - `min_bin_t') * ( (`max_bin_t' - `min_bin_t') * `y_moment_t' - (`max_bin_t' - `t') * `y_moment_next_t' )
      
      /* get the analytical upper bound */
      if (`s' < `star_bin_s') local analytical_upper_bound_s = 1/(`max_bin_s' - `s') * ((`max_bin_s' - `min_bin_s' )* `y_moment_s' - (`s' - `min_bin_s') * `y_moment_prior_s' )
      if (`s' >= `star_bin_s') local analytical_upper_bound_s = `y_moment_next_s'
      
      /* if the t value is not in the same bin as s, average the determined value of the moments in prior bins, plus the analytical
      lower bound times the proportion of mu_0^t it constitutes */
      if `bin_t' != `bin_s' {
        
        local bin_t_minus_1 = `bin_t' - 1
        local bin_s_plus_1 = `bin_s' + 1
        
        /* add the determined portion, mu_prime, only if there is a full bin in between s and t  */      
        if `bin_t' - `bin_s' >= 2 {
          local mu_prime = 0 
          /* obtain the weighted value of the moments between s and t  */  
          forv i = `bin_s_plus_1'/`bin_t_minus_1' {
            local bin_size_`i' = `max_bin_`i'' - `min_bin_`i''         
            local wt =  `bin_size_`i'' / (`t' - `s') * `y_moment_`i'' 
            local mu_prime = `mu_prime' + `wt'
          }
        }      
        else {
          local mu_prime = 0
        }
        di "`mu_prime'" 
        /* put this together with the determined portion of the parameter */  
        local lb_mu_s_t = `mu_prime' + (`t' - max(`max_bin_`bin_t_minus_1'',`s') ) / (`t' - `s') * `analytical_lower_bound_t' + (`max_bin_s' - `s') / (`t' - `s') * `y_moment_s' * (`bin_s' != `bin_t') 
        local ub_mu_s_t = `mu_prime' + (`t' - `max_bin_`bin_t_minus_1'' ) / (`t' - `s') * `y_moment_t' * (`bin_s' != `bin_t') + (min(`max_bin_s',`t') - `s') / (`t' - `s') * `analytical_upper_bound_s' 
      }
      
      /* if the t IS in the same interval as s, the bounds are simpler to compute: just take the analytical lower bound of t, or the analytical upper bound of s */
      if `bin_t' == `bin_s' {
        local lb_mu_s_t = `analytical_lower_bound_t'
        local ub_mu_s_t = `analytical_upper_bound_s'
      }
      
      /* return the locals that are desired */
      if "`FAILED'" != "1" {
        return local t = `t'
        return local s = `s'
        return local mu_lower_bound = `lb_mu_s_t'
        return local mu_upper_bound = `ub_mu_s_t'                     
        return local mu_lb = `lb_mu_s_t'
        return local mu_ub = `ub_mu_s_t'                     
        return local star_bin_s = `star_bin_s'
        return local star_bin_t = `star_bin_t'    
        return local num_moms = _N
      }
    }

    if "`FAILED'" != "1" {
      local rd_lb_mu_s_t: di %6.3f `lb_mu_s_t'
      local rd_ub_mu_s_t: di %6.3f `ub_mu_s_t'

      if mi("`quiet'") {      
        di `" Mean `yvar' in(`s', `t') is in [`rd_lb_mu_s_t', `rd_ub_mu_s_t'] "'   
      }
      
      if !mi("`append'") {
        append_to_file using `append', s(`str',`rd_lb_mu_s_t', `rd_ub_mu_s_t')
      }
    }
    else {
      return local t = `t'
      return local s = `s'
      return local mu_lower_bound = .
      return local mu_upper_bound = .
      return local mu_lb = .
      return local mu_ub = .
      return local star_bin_s = .
      return local star_bin_t = .
      return local num_moms = _N
    }
    /* close program */
    restore
  end
  /* *********** END program bound_mobility ***************************************** */

  /**********************************************************************************/
  /* program calc_transition_matrix : Insert description here */
  /***********************************************************************************/
  cap prog drop calc_transition_matrix
  prog def calc_transition_matrix, rclass
    {
      syntax, PARENTvar(varname) CHILDvar(varname) [Weight(varname) subgroup(string) graphname(string)]
      
      /* preserve -- since we do lots of reshapes/collapses */
      preserve

      /* create a short "if subgroup" string */
      if !mi("`subgroup'") {
        local ifsubgroup `"if `subgroup'"'
      }
      
      /* manage weights -- create a weight if one doesn't already exist */
      if mi("`weight'") {
        gen __weight = 1
      }
      else {
        ren `weight' __weight
      }
	  	  
      /* generate father and son midpoint ranks in the national distribution */
      gen_wt_ranks `parentvar', gen(__parent_rank) weight(__weight)
      gen_wt_ranks `childvar', gen(__child_rank) weight(__weight)

      /* keep only the variables we use -- this lets us create arbitrary variables */
      keep __parent_rank __child_rank __weight `subgroup'
      
      /* rename vars to clean names since nothing else now exists */
      rename __* *

      if !mi("`graphname'") {
        binscatter child_rank parent_rank `ifsubgroup', linetype(none) ylabel(0(20)100, grid)
        graphout `graphname'
      }
      
      /********************************/
      /* check and force monotonicity */
      /********************************/
      
      /* if not monotonic, combine X groups until monotonic */
      di "Checking distribution for monotonicity..."
      is_monotonic `ifsubgroup', x(parent_rank) y(child_rank) weight(weight)
      if `r(is_monotonic)' == 0 {
        make_monotonic `ifsubgroup', x(parent_rank) y(child_rank) weight(weight)
      }
      else {
        di "Already monotonic, no changes made."
      }
      
      /**********************************/
      /* interpolate child distribution */
      /**********************************/
      qui {
        /* generate cumulative son transition probabilities IN NATIONAL DISTRIBUTION -- not in subgroup */
        cumul child_rank [aw=weight], gen(son_ed_cumul) equal

        /* restrict to subgroup here, now that all ranks are referenced in national distribution */
        if !mi("`subgroup'") keep if `subgroup'
        
        /* collapse to one obs per parent-child rank -- i.e. raw transition matrix */
        collapse (sum) weight, by(parent_rank son_ed_cumul)
        
        /* fill in the data with zeroes */
        fillin parent_rank son_ed_cumul
        replace weight = 0 if mi(weight)
        
        /* create a weight within each row */
        bys parent_rank: egen father_total_weight = total(weight)
        gen row_weight = weight / father_total_weight
        
        /* show all transition probabilities */
        table parent_rank son_ed_cumul, c(mean row_weight)
        
        /* generate cumulative transition matrix values */
        /* note this is cumulative sum, not egen */
        sort parent_rank son_ed_cumul
        bys parent_rank: gen t = sum(row_weight)
        // table parent_rank son_ed_cumul, c(mean t)
        
        /* create integer father and son groups */
        sort parent_rank
        group parent_rank
        
        sort son_ed_cumul
        group son_ed_cumul
        
        /* we already have datapoints at 100, 100 for each group, create one at 0,0 */
        expand 2 if sgroup == 1, gen(new)
        replace sgroup = 0 if new
        replace t = 0 if new
        replace son_ed_cumul = 0 if new
        replace weight = . if new
        replace row_weight = . if new
        drop new
        
        /* create x values for linear interpolation */
        /* add 100 rows, with indicator "new" for interpolated values */
        count
        local n = `r(N)'
        local new_n = `r(N)' + 100
        set obs `new_n'
        gen new = _n > `n'
        gen row = _n - `n' if _n > `n'
        replace son_ed_cumul = row / 100 if new == 1
        
        /* get sum of father weight, so we know how many fathers in each group */
        sum parent_rank [aw=weight]
        local sum_weight = `r(sum_w)'
        
        sum pgroup
        forval i = 1/`r(max)' {
          
          /* store wide father education variable */
          sum parent_rank [aw=weight] if pgroup == `i'
          gen parent_rank_`i' = `r(mean)' if new == 1
          
          /* store wide father weight */
          gen father_weight_`i' = `r(sum_w)' / `sum_weight' if new == 1
          
          /* linearly interpolate son data so we have one obs per year */
          replace pgroup = `i' if new == 1
          ipolate t son_ed_cumul if pgroup == `i', gen(son_inter_`i')
          
          /* restore pgroup to missing for new obs -- was just temporary for interpolation */
          replace pgroup = . if new == 1
        }
        
        /* keep only interpolated data */
        drop if !mi(t)

        /* reshape to get father-son rank data with exact son ranks  */
        keep parent_rank_* father_weight_* son_inter_* son_ed_cumul 
        
        reshape long parent_rank_ father_weight_ son_inter_, j(pgroup) i(son_ed_cumul)
        label var pgroup ""
        label values pgroup
        
        sort son_ed_cumul pgroup
        group son_ed_cumul
        
        /* clean up names */
        rename *_ *

        /* GENERATE CHILD PDF FROM CDF */
        
        /* flip time series so we can compare son CDF at next point in son distribution */
        sort pgroup sgroup
        xtset pgroup sgroup
        
        /* interpolated son PDF is just diff in interpolated son cdf */
        gen son_ed_pdf = son_inter - L.son_inter
        replace son_ed_pdf = son_inter if float(son_ed_cumul) == float(.01)
        
        /* adjust so x value is each midpoint of each percentile bin (instead of the boundaries as in the CDF) */
        gen child_rank = son_ed_cumul - .005
        
        /* create joint father-son weight -- since son data are uniform, need these weights to show where sons end up */
        gen combined_weight = son_ed_pdf * father_weight
        
        /* rescale ranks to go from 0 to 100 */
        replace child_rank = child_rank * 100

        /* keep only the joint rank data and weights */
        keep parent_rank child_rank combined_weight
      }  
      qui save $tmp/parent_child_clean, replace
      
      /*******************/
      /* get some bounds */
      /*******************/
      use $tmp/parent_child_clean, clear
      
      /* calculate mu50 */
      bound_param [aw=combined_weight], xvar(parent_rank) yvar(child_rank)

      return local lb_mu_0_50 = `r(mu_lower_bound)'
      return local ub_mu_0_50 = `r(mu_upper_bound)'
      
      /* loop over decade cohorts and generate all transition matrices */
      bound_t_clean [aw=combined_weight], xvar(parent_rank) yvar(child_rank)

      /* store return values */
      matrix T_min = r(T_min)
      matrix T_mid = r(T_mid)
      matrix T_max = r(T_max)
      
      // /* TEMPORARY: calculate probability of going from bottom 20% to top 80% */
      // bound_20_to_80_clean [aw=combined_weight], xvar(parent_rank) yvar(child_rank) 
      // 
      // /* store return values */
      // return local lb_p_20_to_80 = `r(lb_p_20_to_80)'
      // return local ub_p_20_to_80 = `r(ub_p_20_to_80)'
      
      /* set stored return values */
      return matrix T_min = T_min
      return matrix T_mid = T_mid
      return matrix T_max = T_max
      
      restore
    }
  end
  /* *********** END program calc_transition_matrix ***************************************** */  
  
  /**********************************************************************************/
  /* program plot_moms : easily plot moments in one line */
  /***********************************************************************************/
  cap prog drop plot_moms
  prog def plot_moms
  syntax [if], xvar(string) yvar(string) xtitle(passthru) ytitle(passthru) name(string) [ylabel(passthru) xlabel(passthru)]
  
  {
    scatter `yvar' `xvar' `if', `xtitle' `ytitle' `xlabel' `ylabel' xscale(range(0 100)) yscale(range(0 100)) ylabel(0[10]100)

    gr export output/moments/`name'.pdf, replace as(pdf)
    
  }
  end
  /* *********** END program plot_moms ***************************************** */  
  
}

