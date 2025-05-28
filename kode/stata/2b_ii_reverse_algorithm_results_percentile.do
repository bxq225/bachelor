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
 twoway connected check region if ref_yr==2022
* this is identical to figure 7b, as desired 

* fig E2ii
twoway connected p_naive region if ref_yr_o==2008, xtitle("") ytitle("Geometric Index in 2008 (2022=100)")  graphregion(color(white)) xlabel(1 "Hovedstaden" 2 "Sjælland" 3 "Syddanmark" 4 "Midtjylland" 5 "Nordjylland") ///
legend(order(1 "Region Indeks" 2 "Med IH korrektion") rows(2))
graph export "$resrootfig/FigE2ii_region.pdf", as(pdf) replace

** iii) show annual bias correction
replace annual_bias_percent=annual_bias_percent*100
* fig 4Aii with tendency line
twoway ///
    (scatter annual_bias_percent region if ref_yr_o==2008), ///
   xtitle("", margin(t=10)) ///
   ytitle("Årlig Bias i reel forbrugsvækst (%), 2008") ///
   xlabel(1 "Hovedstaden" 2 "Sjælland" 3 "Syddanmark" 4 "Midtjylland" 5 "Nordjylland", ///
        labgap(2) labsize(Vsmall) labstyle(angle(vertical))) ///
   legend(off) ///
   graphregion(color(white) margin(b=17))
graph export "$resrootfig/Fig4Aii_region.pdf", as(pdf) replace


* plot adjustment to real consumption in level in final year
foreach i in y qu q {
	gen double `i'_level=exp(`i')
}
gen pc_dev_real_cons = (qu_level-q_level)/qu_level*100

* fig 4Bii
scatter pc_dev_real_cons region if ref_yr_o==2008, xtitle("") ytitle("Bias in 2008 Real Consumption Level, %")  graphregion(color(white)) xlabel(1 "Hovedstaden" 2 "Sjælland" 3 "Syddanmark" 4 "Midtjylland" 5 "Nordjylland") legend(off) ///
   graphregion(color(white) margin(b=16))
graph export "$resrootfig/Fig4Bii_region.pdf", as(pdf) replace


* iii) depict NH adjustment to real cumulative consumption growth 
keep if ref_yr_o==2008 | ref_yr_o==2022

sort region ref_yr_o
foreach i in q qu y {
    
   by region: gen double growth_`i'=`i'-`i'[_n-1]
   by region: gen growth_`i'_pp=(exp(`i')/exp(`i'[_n-1])-1)*100
   
}

gen bias_pp=growth_qu_pp - growth_q_pp

drop ref_yr 
rename ref_yr_o ref_yr 

merge 1:1 region ref_yr using "$dataroot/temp"
keep if _merge==3

twoway connected change_real_exp region || connected bias_pp region, xtitle("Pre-tax Income Percentile") ytitle("Bias in Cumulative Real Consumption Growth" "2008-2022, pp (% of 2022 Nominal Expenditure)")  graphregion(color(white)) xlabel(1 "Hovedstaden" 2 "Sjælland" 3 "Syddanmark" 4 "Midtjylland" 5 "Nordjylland") legend(order(1 "From Group-specific Index" 2 "From NH correction") rows(2))
graph export "$resrootfig/FigE3ii_region.pdf", as(pdf) replace

