***************************************
**** 2a ii. NH Correction: plot results
***************************************

* i) load data
use "$resrootdata/nh_percentiles.dta", clear

* ii) show Laspeyres homothetic vs. corrected Laspeyres in last year 
gen p_naive = exp(y-qu)*100
gen p_full = exp(y-q)*100

twoway connected p_naive a if ref_yr==2022 || connected p_full a if ref_yr==2022, xtitle("") ytitle("Geometrisk Indeks i 2022 (2003=100)")  graphregion(color(white)) xlabel(1 "under 30 aar" 2 "30-44 aar" 3 "45-59 aar" 4 "60 - 74 aar" 5 "75 aar og derover") ///
legend(order(1 "Alder Indeks" 2 "Med NH korrektion") rows(2))
graph export "$resrootfig/FigE2i_alder.pdf_2003", as(pdf) replace

** iii) show annual bias correction
replace annual_bias_percent=annual_bias_percent*100

scatter annual_bias_percent a if ref_yr==2022 || qfit annual_bias_percent a if ref_yr==2022, ///
   xtitle("", margin(t=10)) ///
   ytitle("Årlig Bias i reel forbrugsvækst (%), 2022") ///
   xlabel(1 "under 30 aar" 2 "30-44 aar" 3 "45-59 aar" 4 "60 - 74 aar" 5 "75 aar og derover", ///
        labgap(2) labsize(small) labstyle(angle(vertical))) ///
   legend(off) ///
    graphregion(margin(b=18))
graph export "$resrootfig/Fig4Ai_alder_2003.pdf", as(pdf) replace


* plot adjustment to real consumption in level in final year
foreach i in y qu q {
	gen double `i'_level=exp(`i')
}
gen pc_dev_real_cons = (qu_level-q_level)/qu_level*100

* fig 12d
scatter pc_dev_real_cons a if ref_yr==2022 || qfit pc_dev_real_cons a if ref_yr==2022, xtitle("") ytitle("Bias i 2022 reel forbrugs niveau, %")  graphregion(color(white)) xlabel(1 "under 30 aar" 2 "30-44 aar" 3 "45-59 aar" 4 "60 - 74 aar" 5 "75 aar og derover") legend(off)
graph export "$resrootfig/Fig4Bi_alder_2003.pdf", as(pdf) replace

* iii) depict NH adjustment to real cumulative consumption growth 
keep if ref_yr==2003 | ref_yr==2022

sort a ref_yr
foreach i in q qu y {
    
   by a: gen double growth_`i'=`i'-`i'[_n-1]
   by a: gen growth_`i'_pp=(exp(`i')/exp(`i'[_n-1])-1)*100
   
}

gen bias_pp=growth_qu_pp-growth_q_pp

merge 1:1 a ref_yr using "$dataroot/temp"
keep if _merge==3

twoway connected change_real_exp a || connected bias_pp a, xtitle("Pre-tax Income Percentile") ytitle("Bias in Cumulative Real Consumption Growth" "1984-2022, pp (% of 1984 Nominal Expenditure)")  graphregion(color(white)) xlabel(1 "under 30 aar" 2 "30-44 aar" 3 "45-59 aar" 4 "60 - 74 aar" 5 "75 aar og derover") legend(order(1 "From Group-specific Index" 2 "From NH correction") rows(2))
graph export "$resrootfig/FigE3i_alder_2003.pdf", as(pdf) replace
