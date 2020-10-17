* 3.

insheet using "Underlying Cause of Death, 1999-2018 - single year ages.txt", clear
drop notes
drop if missing(year)
drop if missing(singleyearages)
drop if singleyearagescode=="NS"
drop if population == "Not Applicable"
drop cruderate singleyearages yearcode

destring singleyearagescode population, replace
ren singleyearagescode age

gen birth_year = year - age
gen birth_cohort=round(birth_year, 5)

collapse (sum) deaths population, by(birth_cohort age)
gen rate = deaths/(population/100000)
drop deaths population

* Reshaping only makes it easier to draw the graph - you don't have to do this. 
* It's a useful command to know!

reshape wide rate, i(age) j(birth_cohort)
drop rate1915-rate1930 rate1985-rate2015

twoway line rate1935-rate1980 age if age>=21 & age<=65, graphregion(fcolor(white) lcolor(white))
graph export fig3a.png, replace


