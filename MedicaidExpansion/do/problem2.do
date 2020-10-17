
** 0. Cleaning Excel spreadsheet of health insurance rates by state from the Census

* Note: Many of you will have cleaned and manipulated this dataset in Excel. That is  
* fine for full credit, as long as you did the analysis work in Stata or another scripting  
* language. However, it can be useful to learn how to do this kind of cleaning 
* in Stata. There are many ways to do it, and the below is an (advanced)
* example that utilizes loops, if statements, and macros.

* Can import directly from the web or from hard disk, and use cellrange to specify which part of the table to import
import excel using https://www2.census.gov/programs-surveys/demo/tables/health-insurance/time-series/acs/hic04_acs.xlsx, clear cellrange(A6:AX577) 

* Keep only the percent variables
keep A B E I M Q U Y AC AG AK AO AS AW

* Rename variables so we know what they are - I consulted the spreadsheet, open in Excel at the same time,
* to make sure I was doing the right thing
ren A state
ren B type
ren E Percent2019
ren I Percent2018
ren M Percent2017
ren Q Percent2016
ren U Percent2015
ren Y Percent2014
ren AC Percent2013
ren AG Percent2012
ren AK Percent2011
ren AO Percent2010
ren AS Percent2009
ren AW Percent2008

* Reshape the data to be "long" where there is one line for each state-year-type
reshape long Percent, i(state type) j(year)

save hic04_acs_clean.dta, replace


** 1. Read in Medicaid Expansion dates from my hand-collected data table

insheet using expansion_dates.csv, names clear
tab expansiondate

** 4. Make expansion date groupings. I decide to make rough groups by year of 
* implementation.  The largest group is 2014 implementers. I  make a category  
* for early implementers, group late-implementers adopting between 2015-2019 together 
* (because these states all implemented in the period for which we have uninsured rate data), 
* and include 2020 and future implementers with the non-implementers, because our data 
* ends in 2019. You might have made different choices, but you should have come up with no 
* more than 3-5 logical state groups, based on their expansion timing. 

gen group = "never" if expansiondate=="not implemented" | expansiondate=="not implemented; planned for 7/1/2021"
replace group = "never" if strmatch(expansiondate, "*/20")
replace group = "early" if strmatch(expansiondate, "Early expansion*")
replace group = "late" if strmatch(expansiondate, "*/15")
replace group = "late" if strmatch(expansiondate, "*/16")
replace group = "late" if strmatch(expansiondate, "*/17")
replace group = "late" if strmatch(expansiondate, "*/18")
replace group = "late" if strmatch(expansiondate, "*/19")
replace group = "2014" if strmatch(expansiondate, "*/14")

count if missing(group)   /* As expected, I have succesfully categorized every state */
table expansiondate group

* Merge with cleaned data

merge 1:m state using hic04_acs_clean.dta

* Check the merge quality - everything without a match of 3

tab state if _merge==2
drop if state=="United States"
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

