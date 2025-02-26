
*******************************************************
**** 6a. NH Correction: run algorithm from 1984 onward + age
*******************************************************

* 0) document average age in our final dataset
use "$dataroot/cex_micro_1955_2019_final_age", clear
collapse (mean) avg_age_all [aw=avg_hh_count], by(ref)
scatter avg_age_all ref_yr, xtitle("Year") ytitle("Average age of the U.S. population")  graphregion(color(white)) xlabel(1955(5)2019) ylabel(29(1)41)
graph export "$resrootfig/FigE17.pdf", as(pdf) replace 

* i) load data and collapse by year-category & percentile
use "$dataroot/cex_micro_1955_2019_final_age", clear

* ii) generate aggregate expenditures and expenditure shares by decile
* => already done in initial file

* iii) compute Laspeyres inflation at each percentile (we wuse geometric laspeyres)
bysort ref_yr inc_d age_d: egen double laspeyres_t_tp1=sum(expn_shr_t*log(annual_gross_infl_tplus1_t))
replace laspeyres_t_tp1=exp(laspeyres_t_tp1)
* keep only data we need
keep ref_yr tot_expn laspeyres_t_tp1 inc_d age_d avg_hh_count avg_age_ad avg_hh avg_age_all fam_size_adj avg_age_all_memb avg_age_adult pct_asian_or_pacific_islander pct_black pct_multi_race_or_other pct_native_american pct_white pct_associate_or_professional_de pct_bachelor_s_degree pct_doctorate_degree pct_high_school_graduate pct_master_s_degree pct_never_attended pct_some_college_nd pct_some_graduate_school_nd pct_some_high_school_nd pct_some_or_completed_elementary pct_some_or_completed_middle_sch
duplicates drop

* iv) define variables we need for the algorithm
egen id=group(inc_decile age_decile)
tsset id ref_yr 
gen y=log(tot_expn)
gen Ly=L.y
gen p=log(laspeyres_t_tp1) 

* v) provide reduced-form evidence on the relationship between price changes and income
* Fig 10a
binscatter p avg_age_all if ref_yr<1984, nq(100) absorb(ref_yr) xtitle("Average age of household members") ytitle("Log Geometric index (annual)") line(qfit)
graph export "$resrootfig/FigE16ii.pdf", as(pdf) replace 

binscatter p avg_age_all if ref_yr>1984, nq(100) absorb(ref_yr) xtitle("Average age of household members") ytitle("Log Geometric index (annual)") line(qfit)
graph export "$resrootfig/FigE16iii.pdf", as(pdf) replace 

binscatter p avg_age_all, nq(100) absorb(ref_yr) xtitle("Average age of household members") ytitle("Log Geometric index (annual)") line(qfit)
graph export "$resrootfig/FigE16i.pdf", as(pdf) replace 


* focus on post 1984 data
drop if ref_yr<1984

* for the analysis we need to use p from the previous year
gen temp=L.p if ref_yr>1984
replace temp=0 if ref_yr==1984
drop p 
gen p=temp 
drop temp

* we can decide to work with average age of adults or all hh members
gen double avg_age=log(avg_age_all)
* for age, we keep the levels and think of our approach as working with the log of the exponential of age
* we will also need to use the lagged age in the regressions 
gen double Lavg_age = L.avg_age 

* vi) initiate loop for 1985

* get real income for all households in the quarter
gen double Lq=.
gen double Lqu=.
gen double Lq_noGam=.
gen double q=.
gen double qu=.
gen double q_noGam=.
gen double Lam=.
gen double Gam=. 
replace Lq  = Ly if ref_yr==1985
replace Lqu = Ly if ref_yr==1985
replace Lq_noGam = Ly if ref_yr==1985
replace q = y if ref_yr==1984 
replace qu = y if ref_yr==1984 
replace q_noGam = y if ref_yr==1984 

* variable for regression coefficients
foreach k of numlist 1(1)8 {
gen double beta`k'=.
}

* compute the power log function of real income
foreach k of numlist 1(1)2 {
	gen double Lq`k' = .
}
foreach k of numlist 1(1)2 {
	replace Lq`k' = (Lq)^`k' if ref_yr==1985
}
* compute the power log function of (exponential) age 
foreach k of numlist 1(1)2 {
	gen double La`k' = .
}
foreach k of numlist 1(1)2 {
	replace La`k' = (Lavg_age)^`k' if ref_yr==1985
}
* compute the interactions
foreach y of numlist 1(1)2 {
foreach k of numlist 1(1)2 {
	gen double Lint_q`y'_a`k' = .
}
}
foreach y of numlist 1(1)2 {
foreach k of numlist 1(1)2 {
	replace Lint_q`y'_a`k' = (Lq)^`y'*(Lavg_age)^`k' if ref_yr==1985
}
}

* regress price index on real income & age & interactions at household level
reg p Lq1 Lq2 La1 La2 Lint* if ref_yr==1985 [aw=avg_hh], r
* save coefficients
matrix b_t2 = e(b)
foreach k of numlist 1(1)8 {
	replace beta`k' = b_t2[1,`k']
}

* generate lambda: 
replace Lam = beta1 + beta2*2*Lq + beta5*La1 + beta6*La2 + beta7*2*Lq*La1 + beta8*2*Lq*La2 if ref_yr==1985

* generate gamma:
replace Gam = beta3 + beta4*2*La1 + beta5*Lq + beta6*Lq*2*La1 + beta7*Lq2 + beta8*Lq2*2*La1 if ref_yr==1985

* now compute real consumption at time t, accounting for lambda and gamma 
replace q  = Lq + (y-Ly-p-Gam*(avg_age-Lavg_age))/(1+Lam)  if ref_y==1985
replace qu = Lqu + (y-Ly-p)                                if ref_yr==1985 // also compute uncorrected
replace q_noGam = Lq_noGam + (y-Ly-p)/(1+Lam)              if ref_yr==1985 // also compute without Gamma correction

* update variables we need for the next period: 
replace Lq  = L.q  if ref_y==1986
replace Lqu = L.qu if ref_y==1986 // also compute uncorrected
replace Lq_noGam = L.q_noGam if ref_y==1986 // also compute uncorrected

* vii) now loop over all years

foreach t of numlist 1986(1)2019 {
	
	* compute the power log function of real income
	foreach k of numlist 1(1)2 {
		replace Lq`k' = (Lq)^`k' if ref_yr==`t'
	}

	* compute the power log function of (exponential) age 
	foreach k of numlist 1(1)2 {
		replace La`k' = (Lavg_age)^`k' if ref_yr==`t'
	}
	
	* compute the interactions
	foreach y of numlist 1(1)2 {
		foreach k of numlist 1(1)2 {
			replace Lint_q`y'_a`k' = (Lq)^`y'*(Lavg_age)^`k' if ref_yr==`t'
		}
	}
	
	* regress price index on real income & age & interactions at household level
	reg p Lq1 Lq2 La1 La2 Lint* if ref_yr==`t' [aw=avg_hh], r
	* save coefficients
	matrix b_t2 = e(b)
	foreach k of numlist 1(1)8 {
		replace beta`k' = beta`k'+b_t2[1,`k'] if ref_yr>=`t'
	}
		
	* generate lambda: 
	replace Lam = beta1 + beta2*2*Lq + beta5*La1 + beta6*La2 + beta7*2*Lq*La1 + beta8*2*Lq*La2 if ref_yr==`t'

	* generate gamma:
	replace Gam = beta3 + beta4*2*La1 + beta5*Lq + beta6*Lq*2*La1 + beta7*Lq2 + beta8*Lq2*2*La1 if ref_yr==`t'
	
	* now compute real consumption at time t, accounting for lambda and gamma 
	replace q  = Lq + (y-Ly-p-Gam*(avg_age-Lavg_age))/(1+Lam)  if ref_yr==`t'
	replace qu = Lqu + (y-Ly-p)                                if ref_yr==`t' // also compute uncorrected
	replace q_noGam = Lq_noGam + (y-Ly-p)/(1+Lam)              if ref_yr==`t' // also compute without Gamma correction
	
	* update variables we need for the next period: 
	replace Lq  = L.q  if ref_y==`t'+1
	replace Lqu = L.qu if ref_y==`t'+1 // also compute uncorrected
	replace Lq_noGam = L.q_noGam if ref_y==`t'+1 // also compute uncorrectedrrected
	
}

* viii) generate variables 
gen double Lambda_rescaled = Lam/(1+Lam)
gen double annual_growth_naive = y-Ly-p 
gen double annual_growth_q = q-Lq
gen double annual_bias_percent = (annual_growth_naive - annual_growth_q)/annual_growth_naive

* xi) save file 
save "$resrootdata/temp_historical_age.dta", replace


*********************************************************************************
**** 3a. NH Correction: run algorithm with 1984 as base, for years prior to 1984
*********************************************************************************

* i) load data and collapse by year-category & percentile
use "$dataroot/cex_micro_1955_2019_final_age", clear

drop if ref_yr>1984

* reverse the order of time & invert price change (everything else in the code below is similar)
gen ref_yr_original = ref_yr
replace ref_yr = 1955+(1984-ref_yr)

* ii) generate aggregate expenditures and expenditure shares by decile
* => already done in initial file

* iii) compute Laspeyres inflation at each percentile (we focus on basic laspeyres for now)
bysort ref_yr  inc_decile age_decile: egen double laspeyres_t_tp1=sum(expn_shr_t*log(annual_gross_infl_tplus1_t))
replace laspeyres_t_tp1=exp(laspeyres_t_tp1)
* keep only data we need
keep ref_yr tot_expn laspeyres_t_tp1 inc_decile age_decile ref_yr_original  avg_age_ad avg_hh avg_age_all fam_size_adj avg_age_all_memb avg_age_adult pct_asian_or_pacific_islander pct_black pct_multi_race_or_other pct_native_american pct_white pct_associate_or_professional_de pct_bachelor_s_degree pct_doctorate_degree pct_high_school_graduate pct_master_s_degree pct_never_attended pct_some_college_nd pct_some_graduate_school_nd pct_some_high_school_nd pct_some_or_completed_elementary pct_some_or_completed_middle_sch
duplicates drop

* iv) define variables we need for the algorithm, reversing the order of time
egen id=group(inc_decile age_decile)
tsset id ref_yr 
gen y=log(tot_expn)
gen Ly=L.y
gen p=log(laspeyres_t_tp1) 

* for the analysis we need to use p from the previous year
replace p = -p // we reverse time 
replace p = 0 if ref_yr==1955 // need to set prices at 0 at the beginning by symmetry relative to previous code with forward time

*gen temp=L.p if ref_yr>1984
*replace temp=0 if ref_yr==1984
*drop p 
*gen p=temp 
*drop temp

* we can decide to work with average age of adults or all hh members
gen double avg_age=log(avg_age_all)
* for age, we keep the levels and think of our approach as working with the log of the exponential of age
* we will also need to use the lagged age in the regressions 
gen double Lavg_age = L.avg_age 

* vi) initiate loop for 1956

* get real income for all households in the quarter
gen double Lq=.
gen double Lqu=.
gen double Lq_noGam=.
gen double q=.
gen double qu=.
gen double q_noGam=.
gen double Lam=.
gen double Gam=. 
replace Lq  = Ly if ref_yr==1956
replace Lqu = Ly if ref_yr==1956
replace Lq_noGam = Ly if ref_yr==1956
replace q = y if ref_yr==1955
replace qu = y if ref_yr==1955 
replace q_noGam = y if ref_yr==1955


* variable for regression coefficients
foreach k of numlist 1(1)8 {
gen double beta`k'=.
}

* compute the power log function of real income
foreach k of numlist 1(1)2 {
	gen double Lq`k' = .
}
foreach k of numlist 1(1)2 {
	replace Lq`k' = (Lq)^`k' if ref_yr==1956
}
* compute the power log function of (exponential) age 
foreach k of numlist 1(1)2 {
	gen double La`k' = .
}
foreach k of numlist 1(1)2 {
	replace La`k' = (Lavg_age)^`k' if ref_yr==1956
}
* compute the interactions
foreach y of numlist 1(1)2 {
foreach k of numlist 1(1)2 {
	gen double Lint_q`y'_a`k' = .
}
}
foreach y of numlist 1(1)2 {
foreach k of numlist 1(1)2 {
	replace Lint_q`y'_a`k' = (Lq)^`y'*(Lavg_age)^`k' if ref_yr==1956
}
}

* regress price index on real income & age & interactions at household level
reg p Lq1 Lq2 La1 La2 Lint* if ref_yr==1956 [aw=avg_hh], r
* save coefficients
matrix b_t2 = e(b)
foreach k of numlist 1(1)8 {
	replace beta`k' = b_t2[1,`k']
}

* generate lambda: 
replace Lam = beta1 + beta2*2*Lq + beta5*La1 + beta6*La2 + beta7*2*Lq*La1 + beta8*2*Lq*La2 if ref_yr==1956

* generate gamma:
replace Gam = beta3 + beta4*2*La1 + beta5*Lq + beta6*Lq*2*La1 + beta7*Lq2 + beta8*Lq2*2*La1 if ref_yr==1956

* now compute real consumption at time t, accounting for lambda and gamma 
replace q  = Lq + (y-Ly-p-Gam*(avg_age-Lavg_age))/(1+Lam)  if ref_yr==1956
replace qu = Lqu + (y-Ly-p)                                if ref_yr==1956 // also compute uncorrected
replace q_noGam = Lq_noGam + (y-Ly-p)/(1+Lam)              if ref_yr==1956 // also compute without Gamma correction

* update variables we need for the next period: 
replace Lq  = L.q  if ref_yr==1957
replace Lqu = L.qu if ref_yr==1957 // also compute uncorrected
replace Lq_noGam = L.q_noGam if ref_yr==1957 // also compute uncorrected

* vii) now loop over all years

foreach t of numlist 1957(1)1984 {
	
	* compute the power log function of real income
	foreach k of numlist 1(1)2 {
		replace Lq`k' = (Lq)^`k' if ref_yr==`t'
	}

	* compute the power log function of (exponential) age 
	foreach k of numlist 1(1)2 {
		replace La`k' = (Lavg_age)^`k' if ref_yr==`t'
	}
	
	* compute the interactions
	foreach y of numlist 1(1)2 {
		foreach k of numlist 1(1)2 {
			replace Lint_q`y'_a`k' = (Lq)^`y'*(Lavg_age)^`k' if ref_yr==`t'
		}
	}
	
	* regress price index on real income & age & interactions at household level
	reg p Lq1 Lq2 La1 La2 Lint* if ref_yr==`t' [aw=avg_hh], r
	* save coefficients
	matrix b_t2 = e(b)
	foreach k of numlist 1(1)8 {
		replace beta`k' = beta`k'+b_t2[1,`k'] if ref_yr>=`t'
	}
		
	* generate lambda: 
	replace Lam = beta1 + beta2*2*Lq + beta5*La1 + beta6*La2 + beta7*2*Lq*La1 + beta8*2*Lq*La2 if ref_yr==`t'

	* generate gamma:
	replace Gam = beta3 + beta4*2*La1 + beta5*Lq + beta6*Lq*2*La1 + beta7*Lq2 + beta8*Lq2*2*La1 if ref_yr==`t'
	
	* now compute real consumption at time t, accounting for lambda and gamma 
	replace q  = Lq + (y-Ly-p-Gam*(avg_age-Lavg_age))/(1+Lam)  if ref_yr==`t'
	replace qu = Lqu + (y-Ly-p)                                if ref_yr==`t' // also compute uncorrected
	replace q_noGam = Lq_noGam + (y-Ly-p)/(1+Lam)              if ref_yr==`t' // also compute without Gamma correction
	
	* update variables we need for the next period: 
	replace Lq  = L.q  if ref_yr==`t'+1
	replace Lqu = L.qu if ref_yr==`t'+1 // also compute uncorrected
	replace Lq_noGam = L.q_noGam if ref_yr==`t'+1 // also compute uncorrected
}


* viii) generate variables 
gen double Lambda_rescaled = Lam/(1+Lam)
gen double annual_growth_naive = y-Ly-p 
gen double annual_growth_q = q-Lq
gen double annual_bias_percent = (annual_growth_naive - annual_growth_q)/annual_growth_naive

drop ref_yr 
rename ref_yr_o ref_yr 
drop if ref_yr==1984
drop Lq Ly

* xi) bring post 1984 data and save file 
append using "$resrootdata/temp_historical_age.dta"
save "$resrootdata/nh_percentiles_1955_2019_age.dta", replace
