
**************************************************
**** 5c ii. NH correction: run second-order algorithm
**************************************************

* Load file & initate the loop with the first-order approximation
use "$resrootdata/nh_percentiles_reverse_fisher.dta", clear
drop beta1 beta2
* recall that in this dataset, p is the fisher index from t-1 to t (which by normalization is set to 0 in the first period, 1984)
rename p p_fisher 
* note: since we start from the dataset with inverted time, we don't need to change the time convention again

* set up the 
gen double p_inv_geom = log(reverse_laspeyres_tp1_t)
drop Lq1 Lq2

* prepare variables we will need 
gen double first_order_q_fisher = q 
gen double first_order_Lq_fisher = Lq 

foreach i in baseline_q alpha1 alpha2 beta1 beta2 fprime_Lq fprime_q rho target dev_q LamLq beta1_temp beta2_temp {
	gen double `i' = . 
}
foreach k of numlist 1(1)2 {
	gen double q`k' = .
}	
foreach k of numlist 1(1)2 {
	gen double Lq`k' = .
}	
gen double Lam_old = Lam
drop Lam
gen double Lam = .

tsset inc_p ref_yr


***** Initiate loop in 1985 ****

foreach i of numlist 1985 {
    
	display "running loop for year `i'"
	
	* define tolerance until convergence 
	local z = `i'
	
	while `z' > 0.0000001 {
	
		display "deviation is`z' log points"
	
		* set baseline value for comparison and assessing convergnece 
		replace baseline_q = q if ref_yr==`i'

		* compute the power log function of real consumption that year using the guess 
		foreach k of numlist 1(1)2 {
			replace q`k' = q^`k' if ref_yr==`i'
		}	

		* regress the price index on real income at synthetic household level in each year:
		reg p_inv_geom q1 q2 if ref_yr==`i', r
		* save coefficients
		matrix a_t2 = e(b)
		replace alpha1 = a_t2[1,1] if ref_yr==`i'
		replace alpha2 = a_t2[1,2] if ref_yr==`i'

		* compute rho & target
		replace fprime_Lq = alpha1 + alpha2*2*Lq             if ref_yr==`i'
		replace fprime_q = alpha1 + alpha2*2*q               if ref_yr==`i'
		replace rho = (1/4)*(q-Lq)*(fprime_Lq+fprime_q)      if ref_yr==`i'
		replace target = p_fisher + rho                      if ref_yr==`i'

		* compute the power log function of real consumption in the previous year (which is our fully converged guess)
		foreach k of numlist 1(1)2 {
			replace Lq`k' = (Lq)^`k' if ref_yr==`i'
		}

		* regression
		reg target Lq1 Lq2 if ref_yr==`i', r
		* save coefficients
		matrix b_t2 = e(b)
		replace beta1 = b_t2[1,1] if ref_yr>=`i' 
		replace beta2 = b_t2[1,2] if ref_yr>=`i'

		* generate lagged lambda (for year after 1985 we take the converged value from the previous step so there is no lambda)
		replace LamLq = 0 if ref_yr==`i'

		* generate lambda: 
		replace Lam = beta1 + beta2*2*q if ref_yr==`i'

		* now compute real consumption at time t, accounting for lambda
		replace q  = Lq + (y-Ly-p_fisher)/(1+ 1/2*(LamLq+Lam) )  if ref_yr==`i'

		* check convergence 
		replace dev_q = abs(q-baseline_q)					     if ref_yr==`i'
		*gen double dev_ratio_growth = abs(((q-Lq)/(baseline_q-Lq)-1)*100) if ref_yr==1985 
		*gen double dev_ratio_lambda = abs(  ((y-Ly-p_fisher)/(q-Lq)-1)/((y-Ly-p_fisher)/(baseline_q-Lq)-1)  ) if ref_yr==1985 
		sum dev_q if ref_yr==`i', d
		* update divegence
		local z = r(max)
		display "convergence for year `i' not complete" 
		
	}
	
	display "convergence for year `i' complete"

	* once converged, update values for next period 
	replace Lq = L.q 		if ref_yr==`i'+1 
	replace LamLq = L.Lam   if ref_yr==`i'+1 

}	

sort inc ref_yr
order ref_yr inc y Ly q Lq baseline_q Lam LamLq Lam_old
*binscatter q first_order_q_fisher, nq(100) reportreg
*br
	
***** Now run loops for all other years ****
	
foreach i of numlist 1986(1)2019 {
*foreach i of numlist 1986 {
 	
	display "running loop for year `i'"
	
	* define tolerance until convergence 
	local z = `i'
	
	while `z' > 0.0000001 {
	
		display "deviation = `z' log points"
	
		* set baseline value for comparison and assessing convergnece 
		replace baseline_q = q if ref_yr==`i'

		* compute the power log function of real consumption that year using the guess 
		foreach k of numlist 1(1)2 {
			replace q`k' = q^`k' if ref_yr==`i'
		}	

		* regress the price index on real income at synthetic household level in each year:
		reg p_inv_geom q1 q2 if ref_yr==`i', r

		* save coefficients
		matrix a_t2 = e(b)
		replace alpha1 = a_t2[1,1] if ref_yr==`i'
		replace alpha2 = a_t2[1,2] if ref_yr==`i'
	
		* compute rho & target
		replace fprime_Lq = alpha1 + alpha2*2*Lq             if ref_yr==`i'
		replace fprime_q = alpha1 + alpha2*2*q               if ref_yr==`i'
		replace rho = (1/4)*(q-Lq)*(fprime_Lq+fprime_q)      if ref_yr==`i'
		replace target = p_fisher + rho                      if ref_yr==`i'
	
		* compute the power log function of real consumption in the previous year (which is our fully converged guess)
		foreach k of numlist 1(1)2 {
			replace Lq`k' = (Lq)^`k' if ref_yr==`i'
		}
	
		* regression
		reg target Lq1 Lq2 if ref_yr==`i', r
		* save coefficients
		matrix b_t2 = e(b)
		replace beta1_temp = beta1+b_t2[1,1] if ref_yr==`i' 
		replace beta2_temp = beta2+b_t2[1,2] if ref_yr==`i'

		* note note we have the lagged Lambda, LamLq, from the previous step
		* generate lambda: 
		replace Lam = beta1_temp + beta2_temp*2*q if ref_yr==`i'
		*sum Lam if ref_yr==`i', d 

		* now compute real consumption at time t, accounting for lambda
		replace q  = Lq + (y-Ly-p_fisher)/(1+ 1/2*(LamLq+Lam) )  if ref_yr==`i'

		* check convergence 
		replace dev_q = abs(q-baseline_q)  if ref_yr==`i'
		*gen double dev_ratio_growth = abs(((q-Lq)/(baseline_q-Lq)-1)*100) if ref_yr==1985 
		*gen double dev_ratio_lambda = abs(  ((y-Ly-p_fisher)/(q-Lq)-1)/((y-Ly-p_fisher)/(baseline_q-Lq)-1)  ) if ref_yr==1985 
		sum dev_q if ref_yr==`i', d
		* update divergence
		local z = r(max)
		display "convergence for year `i' not complete" 
		
	}
	
	display "convergence for year `i' complete"
	
	* update values for next period 
	replace Lq = L.q 		if ref_yr==`i'+1 
	replace LamLq = L.Lam   if ref_yr==`i'+1 
	replace beta1 = beta1+b_t2[1,1] if ref_yr>=`i' 
	replace beta2 = beta2+b_t2[1,2] if ref_yr>=`i'

}	

/*	
sort inc ref
order ref inc y Ly q Lq baseline_q Lam LamLq Lam_old
br

binscatter q first_order_q_fisher if ref==1985, nq(100) reportreg
binscatter q first_order_q_fisher if ref==1990, nq(100) reportreg
binscatter q first_order_q_fisher if ref==1995, nq(100) reportreg
binscatter q first_order_q_fisher if ref==2000, nq(100) reportreg
binscatter q first_order_q_fisher if ref==2005, nq(100) reportreg
binscatter q first_order_q_fisher if ref==2010, nq(100) reportreg
binscatter q first_order_q_fisher if ref==2015 & q>0 & q<15, nq(100) reportreg
binscatter q first_order_q_fisher if ref==2019 & q>0 & q<15, nq(100) reportreg
*/

* generate variables 
drop p_inv_geom
foreach i in Lambda_rescaled annual_growth_naive annual_growth_q annual_bias_percent {
gen double `i'_old = `i'
}

replace Lambda_rescaled = 1/2*(LamLq+Lam)/(1+1/2*(LamLq+Lam))
replace annual_growth_naive = y-Ly-p_fisher 
replace annual_growth_q = q-Lq
replace annual_bias_percent = (annual_growth_naive - annual_growth_q)/annual_growth_naive

* save file 
save "$resrootdata/nh_percentiles_reverse_2nd_order_fisher.dta", replace

