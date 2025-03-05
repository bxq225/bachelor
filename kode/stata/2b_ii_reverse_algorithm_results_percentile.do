***************************************
**** 2b ii. NH Correction: plot results
***************************************

* i) load data
use "$resrootdata/nh_percentiles_reverse.dta", clear

* ii) show Laspeyres homothetic vs. corrected Laspeyres in last year 
gen p_naive = exp(y-qu)*100
gen p_full = exp(y-q)*100

* here can check we replicate exactly the previous price index with homothetic utility:
 gen check = 1/(p_naive/100)*100
 twoway connected check indkomstgruppe if ref_yr==2022
* this is identical to figure 7b, as desired 

* fig E2ii
twoway connected p_naive indkomstgruppe if ref_yr_o==2008 || connected p_full indkomstgruppe if ref_yr_o==2008, xtitle("Pre-tax Income Percentile") ytitle("Geometric Index in 2008 (2022=100)")  graphregion(color(white)) xlabel(1(1)5) ///
legend(order(1 "Group-specific Index" 2 "With NH correction") rows(2))
graph export "$resrootfig/FigE2ii.pdf", as(pdf) replace

** iii) show annual bias correction
replace annual_bias_percent=annual_bias_percent*100
* fig 4Aii
scatter annual_bias_percent indkomstgruppe if ref_yr_o==2008, xtitle("Pre-tax Income Percentile") ytitle("Annual Bias in Real Consumption Growth (%), 2008")  graphregion(color(white)) xlabel(1(1)5)
graph export "$resrootfig/Fig4Aii.pdf", as(pdf) replace

* plot adjustment to real consumption in level in final year
foreach i in y qu q {
	gen double `i'_level=exp(`i')
}
gen pc_dev_real_cons = (qu_level-q_level)/qu_level*100

* fig 4Bii
scatter pc_dev_real_cons indkomstgruppe if ref_yr_o==2008, xtitle("Pre-tax Income Percentile") ytitle("Bias in 2008 Real Consumption Level, %")  graphregion(color(white)) xlabel(1(1)5)
graph export "$resrootfig/Fig4Bii.pdf", as(pdf) replace


* iii) depict NH adjustment to real cumulative consumption growth 
keep if ref_yr_o==2008 | ref_yr_o==2022

sort indkomstgruppe ref_yr_o
foreach i in q qu y {
    
   by indkomstgruppe: gen double growth_`i'=`i'-`i'[_n-1]
   by indkomstgruppe: gen growth_`i'_pp=(exp(`i')/exp(`i'[_n-1])-1)*100
   
}

gen bias_pp=growth_qu_pp - growth_q_pp

drop ref_yr 
rename ref_yr_o ref_yr 

merge 1:1 indkomstgruppe ref_yr using "$dataroot/temp"
keep if _merge==3

twoway connected change_real_exp indkomstgruppe || connected bias_pp indkomstgruppe, xtitle("Pre-tax Income Percentile") ytitle("Bias in Cumulative Real Consumption Growth" "2008-2022, pp (% of 2022 Nominal Expenditure)")  graphregion(color(white)) xlabel(1(1)5) legend(order(1 "From Group-specific Index" 2 "From NH correction") rows(2))
graph export "$resrootfig/FigE3ii.pdf", as(pdf) replace

