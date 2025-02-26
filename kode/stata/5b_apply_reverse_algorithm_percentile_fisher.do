
****************************************************************
**** 5b. NH Correction: run algorithm with final period as base & Fisher price index
****************************************************************

* i) load data and collapse by year-category & percentile
use "$dataroot/cex_micro_1984_2019_final_fisher", clear

* reverse the order of time & invert price change (everything else in the code below is similar)
gen ref_yr_original = ref_yr
replace ref_yr = 1984+(2019-ref_yr)

* ii) generate aggregate expenditures and expenditure shares by decile
* => already done in initial file

* iii) compute Laspeyres inflation at each percentile (we focus on basic laspeyres for now)
bysort ref_yr inc_percentile: egen double laspeyres_t_tp1=sum(expn_shr_t*log(annual_gross_infl_tplus1_t))
replace laspeyres_t_tp1=exp(laspeyres_t_tp1)

* compute the "reverse geometric" price index, which we will need to implement the second order algorithm 
bysort ref_yr inc_percentile: egen double reverse_laspeyres_t_tm1=sum(expn_shr_t*log(annual_gross_infl_t_tminus1^(-1)))
replace reverse_laspeyres_t_tm1=exp(reverse_laspeyres_t_tm1)

* to compute Fisher later, we also need to compute basic paasche and basic laspeyres: 
bysort ref_yr inc_percentile: egen double paasche_tm1_t=sum(expn_shr_t*(annual_gross_infl_t_tminus1)^(-1))
replace paasche_tm1_t=(paasche_tm1_t)^(-1)
bysort ref_yr inc_percentile: egen double laspeyres_t_tp1_basic=sum(expn_shr_t*annual_gross_infl_tplus1_t)

* keep only data we need
keep ref_yr tot_expn laspeyres_t_tp1 inc decile quintile ref_yr_original avg_age_all laspeyres_t_tp1_basic paasche_tm1_t reverse_laspeyres_t_tm1
duplicates drop

* iv) define variables we need for the algorithm, reversing the order of time
tsset inc_percentile ref_yr 
gen y=log(tot_expn)
gen Ly=L.y
gen p=log(laspeyres_t_tp1) 
gen double paasche_t_tp1 = L.paasche_tm1_t
gen double fischer_t_tp1 = sqrt(paasche_t_tp1*laspeyres_t_tp1_basic)

* for the analysis we need to use p from the previous year
replace p = log(fischer_t_tp1)
replace p = -p // we reverse time 
replace p = 0 if ref_yr==1984 // need to set prices at 0 at the beginning by symmetry relative to previous code with forward time
* for the reverse geometric used for the laspeyres algorithm we already have the correct period, just change the naming convention to be consistent with the definition of p 
rename reverse_laspeyres_t_tm1 reverse_laspeyres_tp1_t
replace reverse_laspeyres_tp1_t=0 if ref_yr==1984

*gen temp=L.p if ref_yr>1984
*replace temp=0 if ref_yr==1984
*drop p 
*gen p=temp 
*drop temp

* vi) initiate loop for 1985

* get real income for all households in the quarter
gen double Lq=.
gen double Lqu=.
gen double q=.
gen double qu=.
gen double Lam=.
replace Lq  = Ly if ref_yr==1985
replace Lqu = Ly if ref_yr==1985
replace q = y if ref_yr==1984 
replace qu = y if ref_yr==1984 
* variable for regression coefficients
gen double beta1=.
gen double beta2=.

* compute the power log function of real income
foreach k of numlist 1(1)2 {
	gen double Lq`k' = .
}
foreach k of numlist 1(1)2 {
	replace Lq`k' = (Lq)^`k' if ref_yr==1985
}

* regress price index on real income at household level
reg p Lq1 Lq2 if ref_yr==1985, r
* save coefficients
matrix b_t2 = e(b)
replace beta1 = b_t2[1,1]
replace beta2 = b_t2[1,2]

* generate lambda: 
replace Lam = beta1 + beta2*2*Lq if ref_yr==1985

* now compute real consumption at time t, accounting for lambda
replace q  = Lq + (y-Ly-p)/(1+Lam)  if ref_yr==1985
replace qu = Lqu + (y-Ly-p)         if ref_yr==1985 // also compute uncorrected

* update variables we need for the next period: 
replace Lq  = L.q  if ref_yr==1986
replace Lqu = L.qu if ref_yr==1986 // also compute uncorrected

* vii) now loop over all years

foreach t of numlist 1986(1)2019 {
	
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
save "$resrootdata/nh_percentiles_reverse_fisher.dta", replace

