***************************************
**** 18a. NH Correction: run algorithm 
***************************************


* 0) Prepare values from baseline first-order algorithm as guesses 
use "$resrootdata/nh_percentiles_refined_order1.dta", clear
keep ref_yr inc_percentile q
rename q q_guess 
save "$resrootdata/temp.dta", replace


* i) load data and collapse by year-category & percentile
use "$dataroot/cex_micro_1984_2019_final", clear

* ii) generate aggregate expenditures and expenditure shares by decile
* => already done in initial file

* iii) compute geometric Laspeyres inflation at each percentile 
bysort ref_yr inc_percentile: egen double laspeyres_t_tp1=sum(expn_shr_t*log(annual_gross_infl_tplus1_t))
replace laspeyres_t_tp1=exp(laspeyres_t_tp1)

* also compute geometric Paasche inflation at each percentile 
bysort ref_yr inc_percentile: egen double paasche_tm1_t=sum(expn_shr_t*log(annual_gross_infl_t_tminus1))
replace paasche_tm1_t=exp(paasche_tm1_t)

* keep only data we need
keep ref_yr tot_expn laspeyres_t_tp1 paasche_tm1_t inc decile quintile
duplicates drop

tsset inc ref_yr
gen double paasche_t_tp1=F.paasche_tm1_t
drop paasche_tm1_t

* document how laspeyres vs. paasche look like over time 
gen cumulative_laspeyres=laspeyres_t_tp1 if ref_yr==1984
replace  cumulative_laspeyre= L.cumulative_laspeyre*laspeyres_t_tp1 if ref_yr>1984

gen cumulative_paasche=paasche_t_tp1 if ref_yr==1984
replace cumulative_paasche= L.cumulative_paasche*paasche_t_tp1 if ref_yr>1984

scatter cumulative_paasche inc_percentile if ref_yr==2018  || scatter cumulative_laspeyres inc_percentile if ref_yr==2018

* iv) define variables we need for the algorithm
tsset inc_percentile ref_yr 
gen y=log(tot_expn)
gen Ly=L.y
gen double p_lasp=log(laspeyres_t_tp1) 
gen double p_paasche=log(paasche_t_tp1) 

foreach p in p_lasp p_paasche {
gen double temp=L.`p' if ref_yr>1984
replace temp=0 if ref_yr==1984
drop `p' 
gen double `p'=temp 
drop temp
}

* v) in each year, nonparametrically estimate the Laspeyres geometric index
* as a function of nominal income

* compute the power log functions of nominal income 
foreach k of numlist 2(1)4 {
	gen double y`k' = (y)^`k'
	gen double Ly`k' = (Ly)^`k' 
}

* generate variables to store regression coefficients for the geom. Laspeyres regressions
gen double beta0=.
gen double beta1=.
gen double beta2=.
gen double beta3=.
gen double beta4=.

* generate variables to store regression coefficients for the real consumption function regressions
gen double alpha0=.
gen double alpha1=.
gen double alpha2=.
gen double alpha3=.
gen double alpha4=.

* for Laspeyres, use nominal income in the base period as predictor
* for Paasche, use nominal income the next period as predictor
gen p_lasp_hat=.
gen p_paasche_hat=.
foreach t of numlist 1985(1)2019 { 
	reg p_lasp Ly Ly2 Ly3 Ly4 if ref_yr==`t'
	predict temp if ref_yr==`t'
	replace p_lasp_hat=temp if ref_yr==`t'
	matrix b_t2 = e(b)
	replace beta0 = b_t2[1,5] if ref_yr==`t'
	replace beta1 = b_t2[1,1] if ref_yr==`t'
	replace beta2 = b_t2[1,2] if ref_yr==`t'
	replace beta3 = b_t2[1,3] if ref_yr==`t'
	replace beta4 = b_t2[1,4] if ref_yr==`t'
	drop temp
	
	reg p_paasche y y2 y3 y4 if ref_yr==`t'
	predict temp if ref_yr==`t'
	replace p_paasche_hat=temp if ref_yr==`t'
	drop temp
	
}

* get real income for all households in the quarter (from our choice of normalization)
gen double Lq=.
gen double Lqu=.
gen double q=.
gen double qu=.
gen double Lam=.
replace Lq  = Ly if ref_yr==1985
replace Lqu = Ly if ref_yr==1985
replace q = y if ref_yr==1984 
replace qu = y if ref_yr==1984 

gen double dev_q=.
gen double q_update=.
gen double Ly_of_q=.
gen double dChi_tminus1_dq=.
gen double dPi_tminus1_dLy_of_q=.
gen double Lambda_t=.
gen double Pi_tminus1_of_Ly_of_q=.

*** Bring in guesses 
merge 1:1 ref_yr inc_percentile using "$resrootdata/temp.dta"
drop _merge 
	

***** Now run loops for 1985 ****
tsset inc_percentile ref_yr

	display "running loop for year `i'"
	
	* set up counter for convergence
	local z = 100
	
	* intial guess
	replace q = q_guess if ref_yr==1985
	
	* run regression expressing nominal income as a function of real consumption in the base period, 1984
	* note: we run this with the lagged variables in 1985 for convenience 
	* also note that this step is trivial for 1985, since the expenditure function is equal to utility 
	foreach k of numlist 2(1)4 {
		gen double Lq`k' = (Lq)^`k' if ref_yr==1985
	}
	reg Ly Lq Lq2 Lq3 Lq4 if ref_yr==1985
	matrix b_t2 = e(b)
	replace alpha0 = b_t2[1,5] if ref_yr==1985
	replace alpha1 = b_t2[1,1] if ref_yr==1985
	replace alpha2 = b_t2[1,2] if ref_yr==1985
	replace alpha3 = b_t2[1,3] if ref_yr==1985
	replace alpha4 = b_t2[1,4] if ref_yr==1985
	drop Lq2 Lq3 Lq4
	
	* iterate until convergence 
	while `z' > 0.0000001 {
		
		replace Ly_of_q = alpha0+alpha1*q+alpha2*q^2+alpha3*q^3+alpha4*q^4 if ref_yr==1985
		
		replace dChi_tminus1_dq = alpha1+2*alpha2*q+3*alpha3*q^2+4*alpha4*q^3 if ref_yr==1985
		
		replace dPi_tminus1_dLy_of_q = beta1+2*beta2*Ly_of_q+3*beta3*Ly_of_q^2+4*beta4*Ly_of_q^3 if ref_yr==1985
		
		replace Lambda_t = dChi_tminus1_dq*(1+dPi_tminus1_dLy_of_q) - 1 if ref_yr==1985
		
		replace Pi_tminus1_of_Ly_of_q = beta0+beta1*Ly_of_q+beta2*Ly_of_q^2+beta3*Ly_of_q^3+beta4*Ly_of_q^4 if ref_yr==1985
		
		replace q_update = q + 1/(1+Lambda_t)*(y - Ly_of_q - 1/2 * ( Pi_tminus1_of_Ly_of_q + p_paasche_hat ) )  if ref_yr==1985

		display "convergence for year `i' not complete" 
		replace dev_q = abs(q_update-q) if ref_yr==1985
		sum dev_q if ref_yr==1985, d
		* update divegence
		local z = r(max)
		display "convergence for year `i' not complete"
		display "deviation = `z' log points"
		replace q_guess = q_update if ref_yr==1985
		replace q = q_update if ref_yr==1985
		
	}
	
	* once converged, update values for next period 
	replace Lq = L.q 		if ref_yr==1986
	
	* get real consumption at time t without NH correction
	replace qu  = Lqu + (y-Ly- 1/2 * (p_lasp_hat + p_paasche_hat) )  if ref_yr==1985
	replace Lqu = L.qu 		if ref_yr==1986
	


***** Now run loops for all years ****
tsset inc_percentile ref_yr

foreach i of numlist 1986(1)2019 {
 	
	display "running loop for year `i'"
	
	* set up counter for convergence
	local z = 100
	
	* intial guess
	replace q = q_guess if ref_yr==`i'
	
	* run regression expressing nominal income as a function of real consumption in the base period, 1984
	* note: we run this with the lagged variables in 1985 for convenience 
	* also note that this step is trivial for 1985, since the expenditure function is equal to utility 
	foreach k of numlist 2(1)4 {
		gen double Lq`k' = (Lq)^`k' if ref_yr==`i'
	}
	reg Ly Lq Lq2 Lq3 Lq4 if ref_yr==`i'
	matrix b_t2 = e(b)
	replace alpha0 = b_t2[1,5] if ref_yr==`i'
	replace alpha1 = b_t2[1,1] if ref_yr==`i'
	replace alpha2 = b_t2[1,2] if ref_yr==`i'
	replace alpha3 = b_t2[1,3] if ref_yr==`i'
	replace alpha4 = b_t2[1,4] if ref_yr==`i'
	drop Lq2 Lq3 Lq4
	
	* iterate until convergence 
	while `z' > 0.0000001 {
		
		replace Ly_of_q = alpha0+alpha1*q+alpha2*q^2+alpha3*q^3+alpha4*q^4 if ref_yr==`i'
		
		replace dChi_tminus1_dq = alpha1+2*alpha2*q+3*alpha3*q^2+4*alpha4*q^3 if ref_yr==`i'
		
		replace dPi_tminus1_dLy_of_q = beta1+2*beta2*Ly_of_q+3*beta3*Ly_of_q^2+4*beta4*Ly_of_q^3 if ref_yr==`i'
		
		replace Lambda_t = dChi_tminus1_dq*(1+dPi_tminus1_dLy_of_q) - 1 if ref_yr==`i'
		
		replace Pi_tminus1_of_Ly_of_q = beta0+beta1*Ly_of_q+beta2*Ly_of_q^2+beta3*Ly_of_q^3+beta4*Ly_of_q^4 if ref_yr==`i'
		
		replace q_update = q + 1/(1+Lambda_t)*(y - Ly_of_q - 1/2 * ( Pi_tminus1_of_Ly_of_q + p_paasche_hat ) )  if ref_yr==`i'

		display "convergence for year `i' not complete" 
		replace dev_q = abs(q_update-q) if ref_yr==`i'
		sum dev_q if ref_yr==`i', d
		* update divegence
		local z = r(max)
		display "convergence for year `i' not complete"
		display "deviation = `z' log points"
		replace q_guess = q_update if ref_yr==`i'
		replace q = q_update if ref_yr==`i'
		
	}
	
	* once converged, update values for next period 
	replace Lq = L.q 		if ref_yr==`i'+1
	
	* get real consumption at time t without NH correction
	replace qu  = Lqu +  (y-Ly- 1/2 * (p_lasp_hat + p_paasche_hat) )  if ref_yr==`i'
	replace Lqu = L.qu 						if ref_yr==`i'+1
}

* viii) generate variables 
gen double annual_growth_naive = y-Ly-p_lasp_hat
gen double annual_growth_q = q-Lq
gen double annual_bias_percent = (annual_growth_naive - annual_growth_q)/annual_growth_naive

* xi) save file 
save "$resrootdata/nh_percentiles_refined_order2.dta", replace


	