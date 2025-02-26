***************************************
**** 2a ii. NH Correction: plot results
***************************************

* i) load data
use "$resrootdata/nh_percentiles.dta", clear

* ii) show Laspeyres homothetic vs. corrected Laspeyres in last year 
gen p_naive = exp(y-qu)*100
gen p_full = exp(y-q)*100

twoway connected p_naive inc_p if ref_yr==2019 || connected p_full inc_p if ref_yr==2019, xtitle("Pre-tax Income Percentile") ytitle("Geometric Index in 2019 (1984=100)")  graphregion(color(white)) xlabel(0(5)100) ///
legend(order(1 "Group-specific Index" 2 "With NH correction") rows(2))
graph export "$resrootfig/FigE2i.pdf", as(pdf) replace

** iii) show annual bias correction
replace annual_bias_percent=annual_bias_percent*100

scatter annual_bias_percent inc_p if ref_yr==2019, xtitle("Pre-tax Income Percentile") ytitle("Annual Bias in Real Consumption Growth (%), 2019")  graphregion(color(white)) xlabel(0(5)100)
graph export "$resrootfig/Fig4Ai.pdf", as(pdf) replace

* plot adjustment to real consumption in level in final year
foreach i in y qu q {
	gen double `i'_level=exp(`i')
}
gen pc_dev_real_cons = (qu_level-q_level)/qu_level*100

* fig 12d
scatter pc_dev_real_cons inc_p if ref_yr==2019, xtitle("Pre-tax Income Percentile") ytitle("Bias in 2019 Real Consumption Level, %")  graphregion(color(white)) xlabel(0(5)100)
graph export "$resrootfig/Fig4Bi.pdf", as(pdf) replace

* iii) depict NH adjustment to real cumulative consumption growth 
keep if ref_yr==1984 | ref_yr==2019

sort inc_p ref_yr
foreach i in q qu y {
    
   by inc_p: gen double growth_`i'=`i'-`i'[_n-1]
   by inc_p: gen growth_`i'_pp=(exp(`i')/exp(`i'[_n-1])-1)*100
   
}

gen bias_pp=growth_qu_pp-growth_q_pp

merge 1:1 inc_p ref_yr using "$dataroot/temp"
keep if _merge==3

twoway connected change_real_exp inc_p || connected bias_pp inc_p, xtitle("Pre-tax Income Percentile") ytitle("Bias in Cumulative Real Consumption Growth" "1984-2019, pp (% of 1984 Nominal Expenditure)")  graphregion(color(white)) xlabel(0(5)100) legend(order(1 "From Group-specific Index" 2 "From NH correction") rows(2))
graph export "$resrootfig/FigE3i.pdf", as(pdf) replace
