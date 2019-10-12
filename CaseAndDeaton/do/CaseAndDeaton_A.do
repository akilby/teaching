
* 1. 

use mort2017.dta, clear
tab restatus
count if restatus != 4


* 2. 

insheet using "Compressed Mortality, 1979-1998.txt", clear
drop notes racecode yearcode
drop if missing(year)
tempfile early 
save `early'

insheet using "Underlying Cause of Death, 1999-2017.txt", clear
drop notes racecode yearcode
drop if missing(year)
tab race
replace race = "Other Race" if race == "American Indian or Alaska Native"
replace race = "Other Race" if race == "Asian or Pacific Islander"

collapse (sum) deaths population, by(race year) 
gen cruderate = 100000*deaths/population
append using `early'
sort race year

drop if year<=1989
lab var cruderate "Crude Rate"


twoway line cruderate year if race=="Black or African American" || line cruderate year if race=="White" || line cruderate year if race=="Other Race", legend(label(1 "US-Black or African American") label(2 "US-White") label(3 "US-Other Race")) graphregion(fcolor(white) lcolor(white))
graph export fig2a.png, replace

twoway line cruderate year if race=="White" || line cruderate year if race=="Other Race", legend( label(1 "US-White") label(2 "US-Other Race")) graphregion(fcolor(white) lcolor(white))
graph export fig2d.png, replace
