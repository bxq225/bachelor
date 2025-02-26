
***************************************
**** 14bi NH Correction: run algorithm 
***************************************

* i) load data and collapse by year-category & percentile
use "$dataroot/cex_micro_1984_2019_final_fisher", clear

* ii) generate aggregate expenditures and expenditure shares by decile
* => already done in initial file

* reverse the order of time & invert price change (everything else in the code below is similar)
gen ref_yr_original = ref_yr
replace ref_yr = 1984+(2019-ref_yr)

* iii) compute Laspeyres inflation at each percentile (we focus on geom laspeyres here)
bysort ref_yr inc_percentile: egen double laspeyres_t_tp1=sum(expn_shr_t*log(annual_gross_infl_tplus1_t))
replace laspeyres_t_tp1=exp(laspeyres_t_tp1)

* compute the "reverse geometric" price index, which we will need to implement the second order algorithm 
bysort ref_yr inc_percentile: egen double reverse_laspeyres_t_tm1=sum(expn_shr_t*log(annual_gross_infl_t_tminus1^(-1)))
replace reverse_laspeyres_t_tm1=exp(reverse_laspeyres_t_tm1)

* to compute Fisher later, we also need to compute basic paasche and basic laspeyres: 
bysort ref_yr inc_percentile: egen double paasche_tm1_t=sum(expn_shr_t*(annual_gross_infl_t_tminus1)^(-1))
replace paasche_tm1_t=(paasche_tm1_t)^(-1)
bysort ref_yr inc_percentile: egen double laspeyres_t_tp1_basic=sum(expn_shr_t*annual_gross_infl_tplus1_t)

* keep only data we need (note that the variable for tot_expn was adjusted for the fisher price index in the previous do.file)
keep ref_yr tot_expn laspeyres_t_tp1 inc decile quintile laspeyres_t_tp1_basic paasche_tm1_t reverse_laspeyres_t_tm1  ref_yr_original 
duplicates drop

* iv) define variables we need for the algorithm
tsset inc_percentile ref_yr 
gen y=log(tot_expn)
gen Ly=L.y
gen p=log(laspeyres_t_tp1) 
gen double paasche_t_tp1 = L.paasche_tm1_t
gen double fischer_t_tp1 = sqrt(paasche_t_tp1*laspeyres_t_tp1_basic)

* in what follows, we now work with Fisher as the reference price index: 
replace p = log(fischer_t_tp1)
replace p = -p // we reverse time 
replace p = 0 if ref_yr==1984 // need to set prices at 0 at the beginning by symmetry relative to previous code with forward time

* get guess for real consumption from first-order RCF algorithm
merge 1:1 ref_yr inc_percentile using "$resrootdata/nh_percentiles_reverse_RCF.dta", keepusing(q)
rename q q_guess

* get real income for all households in the quarter
gen double Lq=.
gen double Lqu=.
gen double q=.
gen double qu=.
gen double Lam_t=.
gen double Lam_tminus1=.
replace Lq  = Ly if ref_yr==1985
replace Lqu = Ly if ref_yr==1985
replace q = y if ref_yr==1984 
replace qu = y if ref_yr==1984 
* variable for regression coefficients
gen double beta1=.
gen double beta2=.
gen double beta1_tminus1=.
gen double beta2_tminus1=.
* generate variable to keep track of convergence 
gen dev_q=.

* set up variable for the power log function of nominal income 
foreach k of numlist 2(1)2 {
	gen double y`k' = .
	gen double Ly`k' = .
}
* compute the power log function of nominal income (current and lagged)
foreach k of numlist 2(1)2 {
	replace y`k' = (y)^`k'
	replace Ly`k' = (Ly)^`k'
}

*set up guess for initial loop
gen baseline_q = q_guess 
replace q = q_guess

* vi) initiate loop in 1985 

tsset inc_percentile ref_yr 

foreach i of numlist 1985(1)2019 {
    
	display "running loop for year `i'"
	
	* define tolerance until convergence 
	local z = `i'
	
	while `z' > 0.00001 {

		display "deviation is`z' log points"
	
		* set baseline value for comparison and assessing convergnece 
		replace baseline_q = q if ref_yr==`i'
	
		* regress lagged real consumption on lagged nominal income (trivial step, which we show here for clarity only)
		reg Lq Ly Ly2 if ref_yr==`i', r
		matrix b_t2_tm1 = e(b)
		replace beta1_tminus1 = b_t2_tm1[1,1] if ref_yr==`i'
		replace beta2_tminus1 = b_t2_tm1[1,2] if ref_yr==`i'

		* regress current real consumption on current nominal income 
		reg baseline_q y y2 if ref_yr==`i', r
		* save coefficients
		matrix b_t2 = e(b)
		replace beta1 = b_t2[1,1] if ref_yr==`i'
		replace beta2 = b_t2[1,2] if ref_yr==`i'

		* generate lambdas:
		replace Lam_t =  (beta1 + beta2*2*y)^(-1)-1 if ref_yr==`i'
		replace Lam_tminus1 = (beta1_tminus1 + beta2_tminus1*2*Ly)^(-1)-1 if ref_yr==`i'
		
		* now compute real consumption, accounting for lambda
		replace q  = Lq + (y-Ly-p)/(1+(1/2)*(Lam_t+Lam_tminus1))  if ref_yr==`i'
		replace qu = Lqu + (y-Ly-p)         if ref_yr==`i' // also compute uncorrected

		* check convergence: 
		replace dev_q = abs(q-baseline_q)  if ref_yr==`i'
		sum dev_q if ref_yr==`i', d
		* update divegence
		local z = r(max)
		display "convergence for year `i' not complete" 
		
	}

	display "convergence for year `i' complete"

	* once converged, update values for next period 
	replace Lq = L.q 		if ref_yr==`i'+1 
	replace Lqu = L.qu      if ref_yr==`i'+1  // also compute uncorrected
	
}	

* viii) generate variables 
gen double Lam = (1/2)*(Lam_t+Lam_tminus1)
gen double Lambda_rescaled = Lam/(1+Lam)
gen double annual_growth_naive = y-Ly-p 
gen double annual_growth_q = q-Lq
gen double annual_bias_percent = (annual_growth_naive - annual_growth_q)/annual_growth_naive

* xi) save file 
save "$resrootdata/nh_percentiles_reverse_RCF_order2.dta", replace

