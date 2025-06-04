clear
import delimited "$dataroot/data.csv"

drop inflation_t_tminus1
drop inflation_t_tplus1
drop if ref_yr==2023

*Calculate the group total of 'forbrug',
gen forbrug_total = .
bysort a ref_yr (forbrug): replace forbrug_total = sum(forbrug)
bysort a ref_yr (forbrug): replace forbrug_total = forbrug_total[_N]

gen expn_shr_t = forbrug/forbrug_total

sort kategori a ref_yr

*keep if a == 5

keep if beskrivelse =="Alkoholiske drikkevarer"
*keep if beskrivelse == "Beregnet lejevaerdi af bolig"
*keep if beskrivelse == "Elektricitet, gas og andet braendsel"


gen expn_shr_t_graph = expn_shr_t*100
gsort -expn_shr_t

/*
twoway (line expn_shr_t_graph ref_yr if a==1, lcolor(blue) lpattern(solid)) ///
    (line expn_shr_t_graph ref_yr if a==5, lcolor(pink) lpattern(solid)), ///
    xlabel(2002(2)2022) ytitle("Andel af udgifter i %") xtitle("Aarstal") ///
    legend(order(1 "Indkomstgruppe 1" 2 "Indkomstgruppe 5")) ///)

graph export "$resrootfig/Fig1andel_indkomst.pdf", as(pdf) replace
*/
/*
twoway (line expn_shr_t ref_yr if a==1, lcolor(blue) lpattern(solid)) ///
    (line expn_shr_t ref_yr if a==2, lcolor(red) lpattern(dot)) ///
    (line expn_shr_t ref_yr if a==3, lcolor(green) lpattern(solid)) ///
    (line expn_shr_t ref_yr if a==4, lcolor(black) lpattern(solid)) ///
    (line expn_shr_t ref_yr if a==5, lcolor(pink) lpattern(solid)), ///
    xlabel(2002(2)2022) ytitle("Andel af udgifter") xtitle("Aarstal") ///
    legend(order(1 "Aldersgruppe 1" 2 "Aldersgruppe 2" 3 "Aldersgruppe 3" 4 "Aldersgruppe 4" 5 "Aldersgruppe 5"))

graph export "$resrootfig/Fig1andel_alder.pdf", as(pdf) replace