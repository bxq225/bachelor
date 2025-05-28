*******************************************
**** 1. Descriptive Stats by Percentile, Naive 
*******************************************

* i) load data and collapse by year-category & percentile
use "$dataroot/Forbrugs_Data.dta", clear

* ii) generate aggregate expenditures and expenditure shares by decile
* => already done in initial file

* iii) compute Laspeyres inflation
bysort ref_yr region: egen laspeyres_t_tp1=sum(expn_shr_t*inflation_t_tplus1)
bysort ref_yr region: egen geom_laspeyres_t_tp1=sum(expn_shr_t*log(inflation_t_tplus1))

replace geom_laspeyres_t_tp1=exp(geom_laspeyres_t_tp1)
replace laspeyres_t_tp1 = geom_laspeyres_t_tp1 

* keep only data we need
keep ref_yr tot_expn laspeyres_t_tp1 geom_laspeyres_t_tp1 region
duplicates drop
* compute cumulative inflation 
sort region ref_yr
gen cum_laspeyres_t_tp1 = laspeyres_t_tp1 if ref_y==2008
by region: replace cum_laspeyres_t_tp1=cum_laspeyres_t_tp1[_n-1]*laspeyres_t_tp1 if ref_y>2008

* rescale to 100 in 2007
gen laspeyres_price_index_final=100
by region: replace laspeyres_price_index_final = cum_laspeyres_t_tp1[_n-1]*100 if ref_y>2008 

* Figure 2b
twoway connected laspeyres_price_index_final region if ref_yr==2022, ///
    ytitle("Geometrisk indeks (2007=100)") ///
    xtitle("") ///
    xlabel(1 "Region Hovedstaden" 2 "Region Sjælland" 3 "Region Syddanmark" 4 "Region Midtjylland" 5 "Region Nordjylland", ///
        labstyle(angle(vertical)) labsize(vsmall)) ///
    graphregion(color(white) margin(b=16))
graph export "$resrootfig/Fig2b_region.pdf", as(pdf) replace 

* Figure E1v
gen laspeyres_annual_infl = ((laspeyres_price_index_final/100)^(1/(2022-2008))-1)*100 if ref_yr==2022
twoway connected laspeyres_annual_infl  region if ref_yr==2022, xtitle("Region") ytitle("Average Annual Geometric Inflation," "2007-2022, %")  graphregion(color(white))  xlabel(1 "Region Hovedstaden" 2 "Region Sjælland" 3 "Region Syddanmark" 4 "Region Midtjylland" 5 "Region Nordjylland", ///
        labgap(2) labsize(small) labstyle(angle(vertical)))
graph export "$resrootfig/FigE1v_region.pdf", as(pdf) replace 

* prepare and save comparison file we will need for later figures (Fig D3)
gen temp=tot_expn*(ref_yr==2008)
bysort region: egen temp2=max(temp)
gen nominal_expenditure=tot_expn/temp2*100

drop temp temp2 

gen real_expenditure=nominal_expenditure/laspeyres_price_index_final*100
egen laspeyres_Max=max(laspeyres_price_index_final) // obtained from other do.file ("aggregate")
gen real_expenditure_naive=nominal_expenditure/laspeyres_Max*100 if ref_yr==2022
gen real_expenditure_growth=(real_expenditure/100-1)*100
gen real_expenditure_growth_naive=(real_expenditure_naive/100-1)*100
gen change_real_exp = real_expenditure_growth_naive - real_expenditure_growth

* export data we can use later for comparison with the NH correction
save "$dataroot/temp", replace 
