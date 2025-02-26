
***************************************
**** 7 b i. NH Correction: run algorithm 
***************************************

* i) load data and collapse by year-category & percentile
use "$dataroot/cex_micro_1984_2019_robustness1.dta", clear

* ii) generate aggregate expenditures and expenditure shares by decile
* => already done in initial file

* iii) compute Laspeyres inflation at each percentile (we focus on basic laspeyres for now)
bysort ref_yr inc_percentile: egen double laspeyres_t_tp1=sum(expn_shr_t*log(annual_gross_infl_tplus1_t))
replace laspeyres_t_tp1=exp(laspeyres_t_tp1)
* keep only data we need
keep ref_yr tot_expn laspeyres_t_tp1 inc decile quintile
duplicates drop

* iv) define variables we need for the algorithm
tsset inc_percentile ref_yr 
gen y=log(tot_expn)
gen Ly=L.y
gen p=log(laspeyres_t_tp1) 

* v) for the analysis we need to use p from the previous year
gen temp=L.p if ref_yr>1984
replace temp=0 if ref_yr==1984
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
replace q  = Lq + (y-Ly-p)/(1+Lam)  if ref_y==1985
replace qu = Lqu + (y-Ly-p)         if ref_yr==1985 // also compute uncorrected

* update variables we need for the next period: 
replace Lq  = L.q  if ref_y==1986
replace Lqu = L.qu if ref_y==1986 // also compute uncorrected

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
	replace Lq  = L.q  if ref_y==`t'+1
	replace Lqu = L.qu if ref_y==`t'+1 // also compute uncorrected
	
}

* viii) generate variables 
gen double Lambda_rescaled = Lam/(1+Lam)
gen double annual_growth_naive = y-Ly-p 
gen double annual_growth_q = q-Lq
gen double annual_bias_percent = (annual_growth_naive - annual_growth_q)/annual_growth_naive

* xi) save file 
save "$resrootdata/nh_percentiles_robustness1.dta", replace

