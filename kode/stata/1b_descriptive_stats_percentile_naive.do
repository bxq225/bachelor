*******************************************
**** 1. Descriptive Stats by Percentile, Naive 
*******************************************

* i) load data and collapse by year-category & percentile
use "$dataroot/cex_micro_1984_2019_final", clear

* ii) generate aggregate expenditures and expenditure shares by decile
* => already done in initial file

* iii) compute Laspeyres inflation
bysort ref_yr inc_percentile: egen laspeyres_t_tp1=sum(expn_shr_t*annual_gross_infl_tplus1_t)
bysort ref_yr inc_percentile: egen geom_laspeyres_t_tp1=sum(expn_shr_t*log(annual_gross_infl_tplus1_t))
replace geom_laspeyres_t_tp1=exp(geom_laspeyres_t_tp1)
replace laspeyres_t_tp1 = geom_laspeyres_t_tp1 
* keep only data we need
keep ref_yr tot_expn laspeyres_t_tp1 geom_laspeyres_t_tp1 inc
duplicates drop
* compute cumulative inflation 
sort inc_p ref_yr
gen cum_laspeyres_t_tp1 = laspeyres_t_tp1 if ref_y==1984
by inc_p: replace cum_laspeyres_t_tp1=cum_laspeyres_t_tp1[_n-1]*laspeyres_t_tp1 if ref_y>1984
* rescale to 100 in 1984
gen laspeyres_price_index_final=100
by inc_p: replace laspeyres_price_index_final = cum_laspeyres_t_tp1[_n-1]*100 if ref_y>1984 

* Figure 2b
twoway connected laspeyres_price_index_final inc_p if ref_yr==2019, xtitle("Pre-tax Income Percentile") ytitle("Geometric Index in 2019 (1984=100)")  graphregion(color(white)) xlabel(0(5)100) 
graph export "$resrootfig/Fig2b.pdf", as(pdf) replace 

* Figure E1v
gen laspeyres_annual_infl = ((laspeyres_price_index_final/100)^(1/(2019-1984))-1)*100 if ref_yr==2019
twoway connected laspeyres_annual_infl  inc_percentile if ref_yr==2019, xtitle("Pre-tax Income Percentile") ytitle("Average Annual Geometric Inflation," "1984-2019, %")  graphregion(color(white)) xlabel(0(5)100) 
graph export "$resrootfig/FigE1v.pdf", as(pdf) replace 

* prepare and save comparison file we will need for later figures (Fig D3)
gen temp=tot_expn*(ref_yr==1984)
bysort inc_percentile: egen temp2=max(temp)
gen nominal_expenditure=tot_expn/temp2*100
drop temp temp2 

gen real_expenditure=nominal_expenditure/laspeyres_price_index_final*100
gen laspeyres_average=213.1559 // obtained from other do.file ("aggregate")
gen real_expenditure_naive=nominal_expenditure/laspeyres_average*100 if ref_yr==2019
gen real_expenditure_growth=(real_expenditure/100-1)*100
gen real_expenditure_growth_naive=(real_expenditure_naive/100-1)*100
gen change_real_exp = real_expenditure_growth_naive - real_expenditure_growth

* export data we can use later for comparison with the NH correction
save "$dataroot/temp", replace 
