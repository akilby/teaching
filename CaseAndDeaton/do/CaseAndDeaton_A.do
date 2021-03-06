
* 1. 

* Download and unzip most recent year of mortality data from 
* http://www.nber.org/data/vital-statistics-mortality-data-multiple-cause-of-death.html
* Direct link to 2017 data here:
* http://www.nber.org/mortality/2017/mort2017.dta.zip

use Mort2018US.PubUse.dta, clear
tab restatus
count if restatus != 4


* 2. 

* The below raw text files were downloaded from CDC Wonder

insheet using "Compressed Mortality, 1979-1998.txt", clear
drop notes racecode yearcode
drop if missing(year)
tempfile early 
save `early'

insheet using "Underlying Cause of Death, 1999-2018.txt", clear
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
