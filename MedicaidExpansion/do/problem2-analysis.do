** 1. Read in Medicaid Expansion dates from my hand-collected data table

insheet using expansion_dates.csv, names clear
tab expansiondate

** 4. Make expansion date groupings. I decide to make rough groups by year of 
* implementation.  The largest group is 2014 implementers. I  make a category  
* for early implementers, group late-implementers adopting between 2015-2017 together 
* (because these states all implemented in the period for which we have uninsured rate data), 
* and include 2019 and TBD implementers with the non-implementers, because our data 
* ends in 2018. The only difficult case here is Maine, which KFF says implemented on 1/10/2019, 
* but coverage was eventually made retroactive to 7/2/2018. It's not totally clear 
* whether Maine should thus be counted for 2018, but I made the judgment call to assign to 2019
* because it is unlikely that people were making active coverage decisions in 2018 because they 
* anticipated they would eventually receive Medicaid. You might have also reasonably decided
* to put it into the "late implementers" group.

* You might have made different choices, but you should have come up with no more than 
* 3-5 logical state groups. 

gen group = "never" if expansiondate=="not implemented" | expansiondate=="approved; TBD"
replace group = "never" if strmatch(expansiondate, "*2019")
replace group = "early" if strmatch(expansiondate, "Early expansion*")
replace group = "late" if strmatch(expansiondate, "*2015")
replace group = "late" if strmatch(expansiondate, "*2016")
replace group = "late" if strmatch(expansiondate, "*2017")
replace group = "2014" if strmatch(expansiondate, "*2014")

count if missing(group)   /* As expected, I have succesfully categorized every state */

* Merge with cleaned data

merge 1:m state using hic04_acs_clean.dta

* Check the merge quality - everything without a match of 3

tab state if _merge==2
drop if state=="UNITED STATES"
drop _merge

tempfile merged_data_by_state
save `merged_data_by_state'

* Collapse down, taking the mean rate for each group-type-year

collapse (mean) Percent, by(group type year)

* To make overlaid graphing easier, I reshape the data so that there is one 
* column for each group. You might have done this in Excel, or you can
* make overlaid graphs using || like we did in the tutorial

reshape wide Percent, i(type year) j(group) string
order type year Percentearly Percent2014 Percentlate Percentnever /* Puts columns in order */
lab var Percent2014 "2014 adopters"
lab var Percentlate "Late adopters, 2015-2017"
lab var Percentnever "Non-adopters"
lab var Percentearly "Early Adopters"
lab var year Year

* Make uninsured graph

twoway line Percent* year if type == "Uninsured", ytitle("Percent Uninsured") title("Uninsured rate over time") subtitle("by Medicaid Expansion status") graphregion(fcolor(white) lcolor(white))
graph export uninsured.png, replace

** 5. Make Medicaid graph, and private insurance graph

twoway line Percent* year if type == "..Medicaid", ytitle("Percent Covered by Medicaid") title("Medicaid coverage rate over time") subtitle("by Medicaid Expansion status") graphregion(fcolor(white) lcolor(white))
graph export medicaid.png, replace

twoway line Percent* year if type == "Private", ytitle("Percent with Private Insurance") title("Private insurance coverage rate over time") subtitle("by Medicaid Expansion status") graphregion(fcolor(white) lcolor(white))
graph export private.png, replace

**************************************************************************************

** 7. Extra Credit. Difference-in-differences analysis - simple difference in means

use `merged_data_by_state', clear
keep if type == "Uninsured"
drop if group == "late"
replace group = "2014" if group == "early"
gen post_2014 = (year>=2014)

collapse (mean) Percent, by(group post_2014)

levelsof Percent if group=="never" & post_2014==0, clean local("never_pre")
levelsof Percent if group=="never" & post_2014==1, clean local("never_post")
levelsof Percent if group=="2014" & post_2014==0, clean local("2014_pre")
levelsof Percent if group=="2014" & post_2014==1, clean local("2014_post")

di (`2014_post' - `never_post') 
di (`2014_pre' - `never_pre')

di (`2014_post' - `2014_pre') 
di (`never_post' - `never_pre')

di (`2014_post' - `never_post') - (`2014_pre' - `never_pre')

* Difference-in-differences analysis - using a regression

use `merged_data_by_state', clear
keep if type == "Uninsured"
drop if group == "late"
replace group = "2014" if group == "early"

gen post_2014 = (year>=2014)
gen adopted_medicaid = (group=="2014")
gen adopted_medicaid_post_2014 = (post_2014 == 1 & adopted_medicaid == 1)

reg Percent post_2014 adopted_medicaid adopted_medicaid_post_2014

* There is a nifty way to make Stata give you coefficients on two variables plus
* their interaction term:

reg Percent post_2014##adopted_medicaid 

