# Libraries

library(dplyr)
library(tidyr)
library(data.table)
library(stringr)
library(fuzzyjoin)

Drop_Check = function(old_dropped, new_df){
  new_ids = unique(unlist(new_df[, 'ID_Juan']))
  all_ids = unlist(juan_dt[, 'ID_Juan'])
  new_dropped = juan_dt[!(all_ids %in% new_ids)][, 'ID_Juan']
  out = append(old_dropped, new_dropped)
  return(unique(unlist(out)))
}

Get_Dupe = function(x){return(duplicated(x) | duplicated(x, fromLast = TRUE))}

# import raw csv and save as data table
juan_dt = fread('data/juan/movies.csv')
colnames(juan_dt) = c('Title', 'Viewed')

# Juan setup ----

# Ratings

# Pull ratings from movie titles
# ?<=[(]) gets position of one char after a '('
# (?=[/]) gets position of '/'
# (.*?) returns values between '(' and '/'
juan_dt$Rating = str_extract(juan_dt$Title, "(?<=[(])(.*?)(?=[/])")

# Manually clean edge cases
juan_dt[nchar(juan_dt$Rating) > 3, ][, 'Rating'] = c(8.9, 9.2)


# Convert to numeric
juan_dt$Rating = as.numeric(juan_dt$Rating)

# Viewed
# Convert to factor
juan_dt$Viewed = as.factor(juan_dt$Viewed)


# Remove ratings from movie titles
juan_dt$Title_clean = gsub("(?=[(])(.*?)(?<=[)])", '', juan_dt$Title, perl = TRUE)

# Clean edge cases
# juan_dt[which(grepl('[(]', juan_dt$Title_clean)), ][, 'Movie_clean'] =
#   gsub('.*?(?=[(])', '.*?(?=[(])', juan_dt$Title_clean, perl = TRUE)
# Missing last parentheses
juan_dt$Title_clean = gsub('(?=[(]).*', '', juan_dt$Title_clean, perl = TRUE)

# trim whitespace
juan_dt$Title_clean = trimws(juan_dt$Title_clean)

# Manually cleaning additional issues
juan_dt$Title_clean[415] = 'Halloween [2018]'

# Fix character conversion issues
juan_dt$Title_clean = gsub('â€™', "'", juan_dt$Title_clean)
juan_dt$Title_clean = gsub('Ã', 'i', juan_dt$Title_clean)
juan_dt$Title_clean = gsub('i¼', 'ü', juan_dt$Title_clean)
juan_dt$Title_clean = gsub('i¡', 'a', juan_dt$Title_clean)
juan_dt$Title_clean = gsub('i©', 'e', juan_dt$Title_clean)

# Add movie / tv categorization
# possible tv indicators
# tv_matches = c('Season', 'Series', 'Episodes')
# juan_dt$Type = ifelse(grepl(paste(tv_matches, collapse = '|'), juan_dt$Title_clean), 'TV', 'Movie')

# standup
# fix typo
juan_dt$Title_clean = gsub('Hassan Minhaj', 'Hasan Minhaj', juan_dt$Title_clean)

# standup_matches = c('Louis C.K', 'James Acaster', 'Tom Segura', 'Rhys Darby',
#                     'Mike Birbiglia', 'Dave Chapelle', 'Trevor Noah', 'Hasan Minhaj',
#                     'Kevin Hart', 'Bo Burnham', 'Ramy Youssef', 'Neal Brennan',
#                     'Jerrod Carmichael', 'TJ Miller', 'Daniel Sloss', 'Adam Sandler',
#                     'Hannibal Buress', 'Lucas Bros', 'Bill Burr', 'Chris Rock', 'Dave Chappelle',
#                     'Fred Armisen', 'Garfunkel & Oates', 'David Cross', 'Jenny Slate',
#                     'Jerry Seinfeld', 'Jim Jeffries', 'Jimmy Carr', 'Lil Rel Howrey', 'Marc Maron',
#                     'Norm Macdonald', 'Hannah Gadsby', 'Hari Kondabolu', 'Simon Amstell',
#                     'Chelsea Peretti', 'Aziz Ansari', 'Ray Romano')
#
# juan_dt$Type[grepl(paste(standup_matches, collapse = '|'), juan_dt$Title_clean)] = 'Standup'

# Add remake col
juan_dt$Year = str_extract(juan_dt$Title_clean, '\\d{4}')


# lower all titles to aid matching
juan_dt$Title_clean = tolower(juan_dt$Title_clean)

# exclude edge cases
year_cases = c('blade runner: 2049', 'the shop: 2018 episodes', '2017')
juan_dt[juan_dt$Title_clean %in% year_cases][, 'Year'] = NA

# remove years from titles
juan_dt$Title_clean = gsub('(\\[)(\\d{4})(\\])', '', juan_dt$Title_clean)


# Add season col
juan_dt$Season = str_extract(juan_dt$Title_clean, '(?<=season |series |volume )(\\d{2}|\\d{1})')

# Fix edge case
juan_dt[juan_dt$Title_clean == 'axe cop: seasons 1-2'][, 'Season'] = '1-2'
juan_dt[juan_dt$Title_clean == 'axe cop: seasons 1-2'][, 'Title_clean'] = 'axe cop'

# Ensure titles with  a season specifier are categorized as TV
# juan_dt[!is.na(juan_dt$Season)][, 'Type'] = 'TV'

# remove seasons from titles
remove_seasons = '(?i)(: |! | - |\\? | )(season |series |volume |part )(\\d{2}|\\d{1})'
juan_dt$Title_clean = gsub(remove_seasons, '', juan_dt$Title_clean)


# trim whitespace again
juan_dt$Title_clean = trimws(juan_dt$Title_clean)

juan_dt$Title = NULL
colnames(juan_dt)[3] = 'Title'
juan_dt$ID_Juan = seq(1: nrow(juan_dt))


# IMDB setup ----

# Set up IMDB dt
imdb_full = fread('data/imdb/title_basics.tsv', sep = '\t', na.strings = '\\N')
imdb_ratings = fread('data/imdb/title_ratings.tsv', sep = '\t')
imdb_season = fread('data/imdb/title_episode.tsv', sep = '\t')

# cut down imdb_full length & format
imdb_full$endYear = NULL
colnames(imdb_full) = c('tconst' ,'Type_IMDB', 'Title', 'Title_IMDB', 'Adult_YN', 'Year_IMDB', 'Runtime', 'Genres')

kept_types = c('movie', 'tvMiniSeries', 'tvMovie', 'tvSeries', 'tvSpecial', 'short', 'video', 'tvShort')
imdb_short = imdb_full[Type_IMDB %in% kept_types]
imdb_short$Year_IMDB = as.numeric(imdb_short$Year_IMDB)
imdb_short = imdb_short[Year_IMDB >= 1920]


# merge ratings
imdb_short = imdb_ratings[imdb_short, on = 'tconst']
colnames(imdb_short)[2:3] = c('Rating_IMDB', 'Votes_IMDB')

imdb_dt = imdb_short[!is.na(imdb_short$Votes_IMDB) & imdb_short$Votes_IMDB > 300 & !is.na(imdb_short$Genres), ]

# lower titles
imdb_dt$Title = tolower(imdb_dt$Title)

merged_full = juan_dt
merged_full = imdb_dt[merged_full, on = 'Title']

# copy for cleaning
merged_dt = merged_full

# # Cleaning round 1 ----
# # drop titles that did not match an imdb entry
merged_dt = merged_dt[!is.na(tconst)]

# null b/c first time function is called so nothing to append to
dropped_ids = Drop_Check(NULL, merged_dt)

# if a title contains a season, then drop anything besides tvSeries
merged_dt = merged_dt[!(!is.na(Season) & Type_IMDB != 'tvSeries')]
dropped_ids = Drop_Check(dropped_ids, merged_dt)

# match entry to rerun year
merged_dt = merged_dt[(!is.na(Year) & Year == Year_IMDB) | is.na(Year)]

# sort by votes and keep the top entry for duplicated entries
merged_dt = merged_dt[merged_dt[, .I[which.max(Votes_IMDB)], by=ID_Juan]$V1]
dropped_ids = Drop_Check(dropped_ids, merged_dt)

# Change titles of dropped ids, then remerge
merged_redo1 = juan_dt[juan_dt$ID_Juan %in% dropped_ids]
merged_check1 = merged_full[merged_full$ID_Juan %in% dropped_ids]

# TODO: try this in python with fuzzy matching of some sort
title_changes = c(
  c("art and copy", "art & copy"),
  c("american crime story: the people vs. o.j simpson", "american crime story"),
  c("angry birds: the movie", "the angry birds movie"),
  c("ant-man and wasp", "ant-man and the wasp"),
  c("autumn's sonata", "autumn sonata"),
  c("best of enemies", "the best of enemies"),
  c("bobs burgers", "bob's burgers"),
  c("blade runner: 2049", "blade runner 2049"),
  c("blade runner: the final cut", "blade runner"),
  c("central park five", "the central park five"),
  c("chris rock: tambourine", "chris rock: tamborine"),
  c("christina p. mother inferior", "christina p: mother inferior"),
  c("clarence clemons: who do you think i am?", "clarence clemons: who do i think i am?"),
  c("dave chappelle: deep in the heart of texas", "Deep in the Heart of Texas: Dave Chappelle Live at Austin City Limits"),
  c("dave chappelle: sticks and stones", "dave chappelle: sticks & stones"),
  c("david cross: making america great again!", "david cross: making america great again"),
  c("demitri martin: the overthinker", "demetri martin: the overthinker"),
  c("detective pikachu", "PokÃ©mon Detective Pikachu"),
  c("documentary now", "documentary now!"),
  c("el infierno", "el narco"),
  c("everybody wants some", "everybody wants some!!"),
  c("frankenstein's monster's monster, frankenstein", "Frankenstein's Monster's Monster, Frankenstein"),
  c("friday the 13th, part vi: jason lives", "Friday the 13th Part VI: Jason Lives"),
  c("garfunkel & oates: trying to be special", "garfunkel and oates: trying to be special"),
  c("evil genius: the true story about america's most diabolical bank heist", "Evil Genius: The True Story of America's Most Diabolical Bank Heist"),
  c("furious seven", "furious 7"),
  c("ghostbusters: 2016", "ghostbusters"),
  c("guardians of the galaxy: vol 2", "guardians of the galaxy vol. 2"),
  c("handsome: a netflix murder mystery movie", "handsome: a netflix mystery movie"),
  c("hannah gadsby: nannette", "hannah gadsby: nanette"),
  c("harry and meghan: a royal romance", "harry & meghan: a royal romance"),
  c("hearts of darkness", "Hearts of Darkness: A Filmmaker's Apocalypse"),
  c("hello mary lou: prom night 2", "prom night II"),
  c("heroin", "heroin(e)"),
  c("hobbs and shaw", "Fast & Furious Presents: Hobbs & Shaw"),
  c("hottie and the nottie", "the hottie & the nottie"),
  c("i think you should leave - with tim robinson", "i think you should leave with tim robinson"),
  c("insidious 3", "insidious: chapter 3"),
  c("it: chapter 2", "it chapter two"),
  c("jaws iii", "Jaws 3-D"),
  c("jerry seinfeld: i'm telling you for the last time", "Jerry Seinfeld: 'I'm Telling You for the Last Time'"),
  c("jew süss", "Jud SÃ¼ÃŸ"),
  c("jimmy carr: the best pf ultimate gold greatest hits", "jimmy carr: the best of ultimate gold greatest hits"),
  c("joe mande: an award winning special", "Joe Mande's Award-Winning Comedy Special"),
  c("john wick 3: parabellum", "John Wick: Chapter 3 - Parabellum"),
  c("king of kong: a fistful of quarters", "The King of Kong: A Fistful of Quarters"),
  c("lego movie 2", "the lego movie 2: the second part"),
  c("lil rel howrey: live in crenshaw", "lil rel howery: live in crenshaw"),
  c("louis c.k: live at the comedy store", "louis c.k.: live at the comedy store"),
  c("love, death, and robots", "love, death & robots"),
  c("lucas bros: on drugs", "lucas brothers: on drugs"),
  c("lupin the 3rd: the castle it cagliostro", "lupin the 3rd: castle of cagliostro"),
  c("m.", "m"),
  c("michael bolton's big sexy valentine's day special", "michael bolton's big, sexy valentine's day special"),
  c("mission impossible: fallout", "mission: impossible - fallout"),
  c("muse: kobe bryant", "kobe bryant's muse"),
  c("nailed it", "nailed it!"),
  c("neal brennan: three mics", "Neal Brennan: 3 Mics"),
  c("norm macdonald: hitler's dog, gossip and trickery", "norm macdonald: hitler's dog, gossip & trickery"),
  c("nosferatu: a symphony of horror", "nosferatu"),
  c("nosferatu: phantom of the night", "Nosferatu the Vampyre"),
  c("oceans 8", "ocean's eight"),
  c("oh, hello: on broadway", "oh, hello on broadway"),
  c("once upon a time in hollywood", "Once Upon a Time... in Hollywood"),
  c("pixles", "pixels"),
  c("planes, trains and automobiles", "Planes, Trains & Automobiles"),
  c("patrick melrose: miniseries", "patrick melrose"),
  c("patriot act, with hasan minhaj", "patriot act with hasan minhaj"),
  c("pop star: never stop never stopping", "popstar: never stop never stopping"),
  c("queen and slim", "queen & slim"),
  c("queer eye: we're in japan", "queer eye: we're in japan!"),
  c("red riding: 1974", "Red Riding: The Year of Our Lord 1974"),
  c("red riding: 1980", "Red Riding: The Year of Our Lord 1980"),
  c("red riding: 1983", "Red Riding: The Year of Our Lord 1983"),
  c("saturday night live: david s. pumpkin halloween special", "The David S. Pumpkins Halloween Special"),
  c("seth myers: lobby baby", "seth meyers: lobby baby"),
  c("sky captain: and the world pf tomorrow", "sky captain and the world of tomorrow"),
  c("sky ladder: the art of cai� guo-qiang", "Sky Ladder: The Art of Cai Guo-Qiang"),
  c("spider-man: into the spiderverse", "spider-man: into the spider-verse"),
  c("show me a hero: complete mini series", "show me a hero"),
  c("spongebob square pants: sponge out of water", "The SpongeBob Movie: Sponge Out of Water"),
  c("star crash", "starcrash"),
  c("star trek: into darkness", "star trek into darkness"),
  c("star wars: rise of skywalker", "Star Wars: Episode IX - The Rise of Skywalker"),
  c("star wars: the last jedi", "Star Wars: Episode VIII - The Last Jedi"),
  c("spawn", "todd mcfarlane's spawn"),
  c("the avengers: infinity war", "avengers: infinity war"),
  c("the barkley marathons", "The Barkley Marathons: The Race That Eats Its Young"),
  c("the breaker uppers", "the breaker upperers"),
  c("the end of the fucking world", "The End of the F***ing World"),
  c("the incredibles 2", "incredibles 2"),
  c("the jerrod carmichael show", "the carmichael show"),
  c("the man from u.n.c.l.e", "the man from u.n.c.l.e."),
  c("the lonely island presents: the unauthorized bash brothers experience", "The Unauthorized Bash Brothers Experience"),
  c("the lucas bros moving co", "lucas bros moving co	"),
  c("the old man and the gun", "the old man & the gun"),
  c("the shop: 2018 episodes", "the shop"),
  c("three hazelnuts for cinderella", "Three Wishes for Cinderella"),
  c("the world of tomorrow", "World of Tomorrow"),
  c("tim and eric: awesome show great job", "Tim and Eric Awesome Show, Great Job!"),
  c("tj miller: ridiculous", "T.J. Miller: Meticulously Ridiculous"),
  c("too funny to fail: the life and death of the dana carvey show", "Too Funny to Fail: The Life & Death of The Dana Carvey Show"),
  c("ugly delicious presents - breakfast, lunch and dinner", "Breakfast, Lunch & Dinner"),
  c("war for planet of the apes", "War for the Planet of the Apes"),
  c("wes craven's: new nightmare", "Wes Craven's New Nightmare"),
  c("wet hot american summer: 10 years later", "Wet Hot American Summer: Ten Years Later"),
  c("you laugh, but it's true", "You Laugh But It's True"),
  c("james acaster: repertoire - recognise", "recognise"),
  c("james acaster: repertoire - recap", "recap"),
  c("james acaster: repertoire - represent", "represent"),
  c("james acaster: repertoire - reset", "reset"),
  c("jerrod carmichael: home videos", "home videos"),
  c("jerrod carmichael: sermon on the hill", "sermon on the mount"),
  c("rhys darby: night!", "rhys darby: it's rhys darby night!"),
  c("they call it myanmar", "they call it myanmar: lifting the curtain"),
  c("daniel sloss: dark", "dark"),
  c("daniel sloss: jigsaw", "jigsaw"),
  c("sherlock: the abominable bride", "The Abominable Bride"))

# classified as tv episodes
full_dt_titles = c('white right: meeting the enemy', 'the abominable bride',
                   'recognise', 'recap', 'represent', 'reset', 'home videos', 'sermon on the mount',
                   'ramy youssef: feelings', "rhys darby: i'm a fighter jet", "rhys darby: it's rhys darby night!",
                   "the price of gold", "they call it myanmar: lifting the curtain", 'daniel sloss: x', 'dark',
                   'jigsaw', 'clarence clemons: who do i think i am?', 't.j. miller: meticulously ridiculous',
                   'lil rel howery: live in crenshaw')

unsure_titles = c('children of the sun', '2017', 'a murder among us', 'big mouth: my furry valentine',
                  'dave chappelle: live in la', 'derek [special]', 'football fight club', 'little miss sumo')

# various episodes across multiple seasons / not on imdb
dropped_titles = c('conan abroad', 'party monster: scratching the surface', 'race, power and american sports',
                   "rhys darby: this way to spaceship!")

# replace titles
title_changes = trimws(tolower(title_changes))

original_titles = title_changes[seq(1, length(title_changes), 2)]
new_titles = title_changes[seq(2, length(title_changes), 2)]
merged_redo1$Title = mgsub::mgsub(merged_redo1$Title, original_titles, new_titles, recycle = FALSE, fixed=TRUE)

# keep only titles that can be changed with the shortened imdb_dt
merged_redo2 = merged_redo1[!(merged_redo1$Title %in% dropped_titles |
                              merged_redo1$Title %in% unsure_titles |
                              merged_redo1$Title %in% full_dt_titles)]

# additional fixes
merged_redo2[merged_redo2$ID_Juan == 214][, 'Title'] = 'sky ladder: the art of cai guo-qiang'
merged_redo2[merged_redo2$ID_Juan %in% c(544, 546, 547)][, 'Year'] = NA
merged_redo2[merged_redo2$ID_Juan == 167][, 'Year'] = 1995

merged_redo1[!(merged_redo1$ID_Juan %in% merged_redo2$ID_Juan)]

# merge w/ imdb
merged_redo2 = imdb_dt[merged_redo2, on = 'Title']

# Cleaning round 2----

# identify dupes
merged_redo2[Get_Dupe(merged_redo2$ID_Juan)]

# drop if release year is after watched year
merged_redo2 = merged_redo2[as.numeric(as.character(merged_redo2$Viewed)) >= Year_IMDB]

# match sequel year
merged_redo2 = merged_redo2[!(!is.na(Year) & Year_IMDB != Year)]

# keep most voted
merged_redo2 = merged_redo2[merged_redo2[, .I[which.max(Votes_IMDB)], by=ID_Juan]$V1]

# add fixed titles to new manual df
merged_manual = rbind(merged_dt, merged_redo2)


# Cleaning round 3----

# merge with full imdb
merged_special = merged_redo1[Title %in% full_dt_titles]

# imdb_full$primaryTitle = tolower(imdb_full$primaryTitle)
imdb_full$Title = tolower(imdb_full$Title)

merged_special = imdb_full[merged_special, on = 'Title']

merged_special = merged_special[!(ID_Juan == 165 & Year_IMDB != 2014)]

tv_episode_ids = c(59, 165, 354, 373, 396, 412, 444, 534)

merged_special = merged_special[!(ID_Juan %in% tv_episode_ids & Type_IMDB != 'tvEpisode')]

tv_movie_ids  = c(582)
merged_special = merged_special[!(ID_Juan %in% tv_movie_ids & Type_IMDB != 'tvMovie')]

merged_special = merged_special[!(ID_Juan == 563 & Type_IMDB != 'tvSeries')]

merged_special = merged_special[!(ID_Juan %in% c(373, 396, 412, 444) & (Year_IMDB != 2018 | Genres != 'Comedy'))]
merged_special = merged_special[!(ID_Juan == 373 & tconst != 'tt7894296')]


# merge w/ ratings
merged_special = imdb_ratings[merged_special, on = 'tconst']
colnames(merged_special)[2:3] = c('Rating_IMDB', 'Votes_IMDB')


# add to merged_manual
merged_manual = rbind(merged_manual, merged_special)

# Cleaning round 4 ----
# check what is still missing
dropped_ids = Drop_Check(NULL, merged_manual)

merged_full[merged_full$ID_Juan %in% dropped_ids]  # fine

# fix manual types (video)

merged_manual[Type_IMDB == 'video'][, 'Type_IMDB'] = 'tvSpecial'

# Post processing ----


# Assume missing season is the first one
merged_manual[Type_IMDB == 'tvSeries' & is.na(Season)][, 'Season'] = 1

tv_ids = unlist(merged_manual[Type_IMDB == 'tvSeries'][, 'tconst'])

tv_dt = imdb_season[parentTconst %in% tv_ids]
tv_dt = imdb_ratings[tv_dt, on = 'tconst']

# Change IMDB Votes and Ratings for seasons of TV
for (id in tv_ids) {

  row_select = merged_manual[tconst == id, ]

  for (season in unlist(row_select[, 'Season'])){
    tv_subset = tv_dt[parentTconst == id & seasonNumber == season]

    votes = mean(unlist(tv_subset[, 'numVotes']), na.rm = TRUE)
    ratings = mean(unlist(tv_subset[, 'averageRating']), na.rm = TRUE)
    episodes = length(unlist(tv_subset[, 'episodeNumber']))

    dt_row = which(merged_manual$tconst == id & merged_manual$Season == season)

    merged_manual[dt_row, 'Rating_IMDB'] = ratings
    merged_manual[dt_row, 'Votes_IMDB'] = votes
    merged_manual[dt_row, 'Episodes'] = episodes
  }
}


# add top genres
setDT(merged_manual)[, 'Top_Genre':= tstrsplit(Genres, ',')[1]]

# add rating_delta
setDT(merged_manual)[, 'Rating_Diff':= (Rating - Rating_IMDB)]

# ensure types are ready for analysis
summary(merged_manual)

merged_manual$Top_Genre = as.factor(merged_manual$Top_Genre)
merged_manual$Year = as.numeric(merged_manual$Year)
merged_manual$Type_IMDB = as.factor(merged_manual$Type_IMDB)

qcut = function(x, n) {
  quantiles = seq(0, 1, length.out = n+1)
  cutpoints = unname(quantile(x, quantiles, na.rm = TRUE))
  cut(x, cutpoints, include.lowest = TRUE)
}

merged_manual$Year_IMDB = cut(merged_manual$Year_IMDB,
                         breaks = c(1920, 1979, 1999, 2009, 2014, 2019),
                         labels = c('1920 - 1980', '1980 - 2000', '2000 - 2010',
                                    '2010 - 2015', '2015 - 2020'))

setDT(merged_manual)[, Popularity := qcut(Votes_IMDB, 5)]
levels(merged_manual$Popularity) = c('Indie', 'Regular', 'Regular', 'Regular', 'Blockbuster')

merged_manual$Type_IMDB = as.factor(merged_manual$Type_IMDB)

other_types = !(levels(merged_manual$Type_IMDB) %in% c('movie', 'tvSeries', 'tvSpecial'))
levels(merged_manual$Type_IMDB)[other_types] = 'other'

merged_manual$Top_Genre = as.factor(merged_manual$Top_Genre)
other_genres = (levels(merged_manual$Top_Genre) %in% c('Animation', 'Reality-TV', 'Fantasy', 'Music', 'Talk-Show'))
levels(merged_manual$Top_Genre)[other_genres] = 'Other'

merged_manual$Label = with(merged_manual, paste0(str_wrap(Title_IMDB, 20),
                                                 '\nIMDB: ', round(Rating_IMDB, 1),
                                                 ' | Juan: ', Rating))

# export to different file to avoid loading times
write.csv(merged_manual, 'data/juan/cleaned_data.csv', row.names = FALSE)
