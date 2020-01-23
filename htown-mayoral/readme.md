# Houston Mayoral Election 2019 - Scraping & Analysis


## Motivation

The 2019 Houston Mayoral Election took place on November 5, 2019, wherein incumbent Sylvester Turner faced challenger Tony Buzbee, a local trial lawyer. Other issues on the ballot included parity between police officer and firefighter pay, funding for flooding infrastructure and public transportation, and a number of local positions. 

Harrisvotes.com published results from this election on their website shortly thereafter, including the voting distribution by precinct. Since different precincts in Houston have vastly different populations and economic interests, I thought it would be interesting to  identify voting trends based on a number of these unique precinct differences.
 

### Challenges

Unfortunately, harrisvotes did not offer an easy way to download this data as a spreadsheet. Moreover, they publish all of their results to one page. Since there has been another election since November, all of it was condensed into a single .pdf.

### Resources 

* Scraping: Python (selenium, requests); archive.org
* Visualization: R, ArcMap
* Analysis: R

---

### Progress

#### Completed:

* [x] Scraping the harrisvotes dynamically generated data
* [x] Merging and cleaning the multiple .jsons into one .csv

#### Forthcoming:

* [ ] Getting precinct level data from the US Census
* [ ] Visualizing differences in precincts
* [ ] Building models that can infer voting trends 


