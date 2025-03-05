clear
*******************************************
**** 1. Descriptive Stats by Percentile, Naive 
*******************************************

* i) load data and collapse by year-category & percentile
use "$dataroot/Forbrugs_Data", clear

* ii) generate aggregate expenditures and expenditure shares by decile
* => already done in initial file

* iii) compute Laspeyres inflation
bysort ref_yr indkomstgruppe: egen laspeyres_t_tp1=sum(expn_shr_t*inflation_t_tplus1)
bysort ref_yr indkomstgruppe: egen geom_laspeyres_t_tp1=sum(expn_shr_t*log(inflation_t_tplus1))
replace geom_laspeyres_t_tp1=exp(geom_laspeyres_t_tp1)
replace laspeyres_t_tp1 = geom_laspeyres_t_tp1 
* keep only data we need
keep ref_yr tot_expn laspeyres_t_tp1 geom_laspeyres_t_tp1 indkomstgruppe
duplicates drop
* compute cumulative inflation 
sort indkomstgruppe ref_yr
gen cum_laspeyres_t_tp1 = laspeyres_t_tp1 if ref_y==2007
by indkomstgruppe: replace cum_laspeyres_t_tp1=cum_laspeyres_t_tp1[_n-1]*laspeyres_t_tp1 if ref_y>2007
* rescale to 100 in 2007
gen laspeyres_price_index_final=100
by indkomstgruppe: replace laspeyres_price_index_final = cum_laspeyres_t_tp1[_n-1]*100 if ref_y>2007 

* Figure 2b
twoway connected laspeyres_price_index_final indkomstgruppe if ref_yr==2022, xtitle("Pre-tax Income Percentile") ytitle("Geometric Index in 2019 (1984=100)")  graphregion(color(white)) xlabel(0(5)100) 
graph export "$resrootfig/Fig2b.pdf", as(pdf) replace 

* Figure E1v
gen laspeyres_annual_infl = ((laspeyres_price_index_final/100)^(1/(2022-2007))-1)*100 if ref_yr==2022
twoway connected laspeyres_annual_infl  indkomstgruppe if ref_yr==2022, xtitle("Pre-tax Income Percentile") ytitle("Average Annual Geometric Inflation," "2007-2022, %")  graphregion(color(white)) xlabel(0(5)100) 
graph export "$resrootfig/FigE1v.pdf", as(pdf) replace 

* prepare and save comparison file we will need for later figures (Fig D3)
gen temp=tot_expn*(ref_yr==2008)
bysort indkomstgruppe: egen temp2=max(temp)
gen nominal_expenditure=tot_expn/temp2*100
drop temp temp2 

gen real_expenditure=nominal_expenditure/laspeyres_price_index_final*100
egen laspeyres_max=max(laspeyres_price_index_final)
gen real_expenditure_naive=nominal_expenditure/laspeyres_max*100 if ref_yr==2022
gen real_expenditure_growth=(real_expenditure/100-1)*100
gen real_expenditure_growth_naive=(real_expenditure_naive/100-1)*100
gen change_real_exp = real_expenditure_growth_naive - real_expenditure_growth

* export data we can use later for comparison with the NH correction
save "$dataroot/temp", replace 
