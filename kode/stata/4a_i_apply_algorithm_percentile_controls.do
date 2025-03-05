
***************************************
**** 4a i NH Correction: run algorithm 
***************************************

* i) load data and collapse by year-category & percentile
use "$dataroot/Forbrugs_Data.dta", clear

* ii) generate aggregate expenditures and expenditure shares by decile
* => already done in initial file

* iii) compute Laspeyres inflation at each percentile (we focus on basic laspeyres for now)
bysort ref_yr indkomstgruppe: egen double laspeyres_t_tp1=sum(expn_shr_t*log(inflation_t_tplus1))
replace laspeyres_t_tp1=exp(laspeyres_t_tp1)
* keep only data we need
*keep ref_yr tot_expn laspeyres_t_tp1 inc decile quintile fam_size_adj avg_age_all_memb avg_age_adult pct_asian_or_pacific_islander pct_black pct_multi_race_or_other pct_native_american pct_white pct_associate_or_professional_de pct_bachelor_s_degree pct_doctorate_degree pct_high_school_graduate pct_master_s_degree pct_never_attended pct_some_college_nd pct_some_graduate_school_nd pct_some_high_school_nd pct_some_or_completed_elementary pct_some_or_completed_middle_sch
keep ref_yr tot_expn laspeyres_t_tp1 indkomstgruppe 
duplicates drop

* iv) define variables we need for the algorithm
tsset indkomstgruppe ref_yr 
gen y=log(tot_expn)
gen Ly=L.y
gen p=log(laspeyres_t_tp1) 

* for the analysis we need to use p from the previous year
gen temp=L.p if ref_yr>2007
replace temp=0 if ref_yr==2007
drop p 
gen p=temp 
drop temp

* vi) initiate loop for 1985

* get real income for all households in the quarter
gen double Lq=.
gen double Lqu=.
gen double q=.
gen double qu=.
gen double Lam=.
replace Lq  = Ly if ref_yr==2008
replace Lqu = Ly if ref_yr==2008
replace q = y if ref_yr==2007 
replace qu = y if ref_yr==2007 
* variable for regression coefficients
gen double beta1=.
gen double beta2=.

* compute the power log function of real income
foreach k of numlist 1(1)2 {
	gen double Lq`k' = .
}
foreach k of numlist 1(1)2 {
	replace Lq`k' = (Lq)^`k' if ref_yr==2008
}

* note: all controls are added as linear terms below, except for age, where we take a quadratic term
foreach k of numlist 1(1)4 {
	gen double avg_age_adult_p`k'=(avg_age_adult)^`k'
}

* regress price index on real income at household level (here with a polynomial of order 2)
reg p Lq1 Lq2 avg_age_adult_p* pct_asian_or_pacific_islander pct_black pct_multi_race_or_other pct_native_american pct_white pct_bachelor_s_degree pct_high_school_graduate if ref_yr==1985, r
* save coefficients
matrix b_t2 = e(b)
replace beta1 = b_t2[1,1]
replace beta2 = b_t2[1,2]

* generate lambda: 
replace Lam = beta1 + beta2*2*Lq if ref_yr==2008

* now compute real consumption at time t, accounting for lambda
replace q  = Lq + (y-Ly-p)/(1+Lam)  if ref_y==2008
replace qu = Lqu + (y-Ly-p)         if ref_yr==2008 // also compute uncorrected

* update variables we need for the next period: 
replace Lq  = L.q  if ref_y==2009
replace Lqu = L.qu if ref_y==2009 // also compute uncorrected

* vii) now loop over all years

foreach t of numlist 2009(1)2023 {
	
	* compute the power log function of real income
	foreach k of numlist 1(1)2 {
	replace Lq`k' = (Lq)^`k' if ref_yr==`t'
	}
	
	* regress price index on real income at household level
	reg p Lq1 Lq2 avg_age_adult_p* pct_asian_or_pacific_islander pct_black pct_multi_race_or_other pct_native_american pct_white pct_bachelor_s_degree pct_high_school_graduate if ref_yr==`t', r
	* save coefficients
	matrix b_t2 = e(b)
	replace beta1 = beta1+b_t2[1,1] if ref_yr>=`t'
	replace beta2 = beta2+b_t2[1,2] if ref_yr>=`t'

	* generate lambda: 
	replace Lam = beta1 + beta2*2*Lq if ref_yr>=`t'

	* now compute real consumption at time t, accounting for lambda
	replace q  = Lq + (y-Ly-p)/(1+Lam)  if ref_yr==`t'
	replace qu = Lqu + (y-Ly-p)         if ref_yr==`t' // also compute uncorrected

	* update variables we need for the next period: 
	replace Lq  = L.q  if ref_y==`t'+1
	replace Lqu = L.qu if ref_y==`t'+1 // also compute uncorrected
	
}

* viii) generate variables 
gen double Lambda_rescaled = Lam/(1+Lam)
gen double annual_growth_naive = y-Ly-p 
gen double annual_growth_q = q-Lq
gen double annual_bias_percent = (annual_growth_naive - annual_growth_q)/annual_growth_naive

* xi) save file 
save "$resrootdata/nh_percentiles_controls.dta", replace

