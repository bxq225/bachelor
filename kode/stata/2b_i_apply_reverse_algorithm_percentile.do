
****************************************************************
**** 2b i. NH Correction: run algorithm with final period as base
****************************************************************

* i) load data and collapse by year-category & percentile
use "$dataroot/Forbrugs_Data.dta", clear

* reverse the order of time & invert price change (everything else in the code below is similar)
gen ref_yr_original = ref_yr
replace ref_yr = 2008+(2022-ref_yr)

* ii) generate aggregate expenditures and expenditure shares by decile
* => already done in initial file

* iii) compute Laspeyres inflation at each percentile (we focus on basic laspeyres for now)
bysort ref_yr indkomstgruppe: egen double laspeyres_t_tp1=sum(expn_shr_t*log(inflation_t_tplus1))
replace laspeyres_t_tp1=exp(laspeyres_t_tp1)
* keep only data we need
keep ref_yr tot_expn laspeyres_t_tp1 indkomstgruppe ref_yr_original 
duplicates drop

* iv) define variables we need for the algorithm, reversing the order of time
tsset indkomstgruppe ref_yr 
gen y=log(tot_expn)
gen Ly=L.y
gen p=log(laspeyres_t_tp1) 

* for the analysis we need to use p from the previous year
replace p = -p // we reverse time 
replace p = 0 if ref_yr==2008 // need to set prices at 0 at the beginning by symmetry relative to previous code with forward time

*gen temp=L.p if ref_yr>2008
*replace temp=0 if ref_yr==2008
*drop p 
*gen p=temp 
*drop temp

* vi) initiate loop for 2009

* get real income for all households in the quarter
gen double Lq=.
gen double Lqu=.
gen double q=.
gen double qu=.
gen double Lam=.
replace Lq  = Ly if ref_yr==2009
replace Lqu = Ly if ref_yr==2009
replace q = y if ref_yr==2008 
replace qu = y if ref_yr==2008 
* variable for regression coefficients
gen double beta1=.
gen double beta2=.

* compute the power log function of real income
foreach k of numlist 1(1)2 {
	gen double Lq`k' = .
}
foreach k of numlist 1(1)2 {
	replace Lq`k' = (Lq)^`k' if ref_yr==2009
}

* regress price index on real income at household level
reg p Lq1 Lq2 if ref_yr==2009, r
* save coefficients
matrix b_t2 = e(b)
replace beta1 = b_t2[1,1]
replace beta2 = b_t2[1,2]

* generate lambda: 
replace Lam = beta1 + beta2*2*Lq if ref_yr==2009

* now compute real consumption at time t, accounting for lambda
replace q  = Lq + (y-Ly-p)/(1+Lam)  if ref_yr==2009
replace qu = Lqu + (y-Ly-p)         if ref_yr==2009 // also compute uncorrected

* update variables we need for the next period: 
replace Lq  = L.q  if ref_yr==2009
replace Lqu = L.qu if ref_yr==2009 // also compute uncorrected

* vii) now loop over all years

foreach t of numlist 2009(1)2022 {
	
	* compute the power log function of real income
	foreach k of numlist 1(1)2 {
	replace Lq`k' = (Lq)^`k' if ref_yr==`t'
	}
	
	* regress price index on real income at household level
	reg p Lq1 Lq2 if ref_yr==`t', r
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
	replace Lq  = L.q  if ref_yr==`t'+1
	replace Lqu = L.qu if ref_yr==`t'+1 // also compute uncorrected
	
}

* viii) generate variables 
gen double Lambda_rescaled = Lam/(1+Lam)
gen double annual_growth_naive = y-Ly-p 
gen double annual_growth_q = q-Lq
gen double annual_bias_percent = (annual_growth_naive - annual_growth_q)/annual_growth_naive

* xi) save file 
save "$resrootdata/nh_percentiles_reverse.dta", replace

