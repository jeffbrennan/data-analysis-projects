# Juan's Movie Reviews

Combines movie reviews from my friend with the following information from https://www.imdb.com/interfaces/

---
## Data sources

#### Juan
- Year - year watched
- Period - semester/season watched
- Title - title of movie / special
- Title_Year - specific year of movie with multiple entries of the same title
- Juan_Rating - juan's rating out of 10

#### IMDB

- Type -Type of media
- Runtime - runtime of media in minutes
- Genres - list of genres the movie is classified as
- IMDB_Rating -  Average rating from IMDB users
- Votes -  Total number of votes

#### Calculated
- Rating_Diff: Juan's Rating - IMDB rating
- Top_Genre: First genre listed in "Genres" column