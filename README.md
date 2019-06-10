# data-analysis-projects
Repository of my data analysis projects on various subjects


# UFC Scraper
###### Data on UFC fighters and event results

----
### fighter-stats.py

Scrapes the following information from https://www.foxsports.com/ufc

###### FOX/fighters
- Name (first, last)
- Link to their page
- Overall record (wins, losses, draws)

###### FOX/fighters/stats - Biographic info


- Date of Birth
- Height
- Weight
- Style
- Reach
- From
- Trains

###### FOX/fighters/stats - Striking info
Four time levels (total striking stats, stats per fight, stats per round, stats per minute)

###### Basic
- Strikes
- TSAC (strike accuracy)
- TD (takedowns)
- TDAC (takedown accuracy)
- KD (knockdowns)
- PASS (guard passes)
- REV (reversals)
- SUB (submissions)

###### Significant strikes
- Strikes and accuracy by region (total, head, body, leg)
###### Created columns
- W/L (win/loss ratio)
- Age (from DoB)
- BMI
- HR_Ratio (ratio of reach to height)


----
### event-stats.py

Scrapes the following information from https://www.foxsports.com/ufc

- Date
- Event name
- Class
- Opponent
- Method
- Length
- Result


# Juan's Movie Reviews

Combines movie reviews from my friend with the following information from https://www.imdb.com/interfaces/

---
## Data sources

#### Juan
- Year - year watched
- Period - semester/season watched
- Title - title of movie / special
- Title_Year - specific year of movie with multiple entries of the same title
- Juan_Rating - juan's rating  out of 10

#### IMDB

- Type -Type of media
- Runtime - runtime of media in minutes
- Genres - list of genres the movie is classified as
- IMDB_Rating -  Average rating from IMDB users
- Votes -  Total number of votes

#### Calculated
- Rating_Diff: Juan's Rating - IMDB rating
- Top_Genre: First genre listed in "Genres" column