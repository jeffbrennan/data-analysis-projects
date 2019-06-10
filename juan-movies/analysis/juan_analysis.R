setwd("/Users/jeffb/Desktop/Life/data-analysis/juan-movie-reviews")
juan = read.csv('output/juan_imdb.csv', header=TRUE, na.strings=c('','NA'))

#--- Exploratory analysis ----
# Weird encoding error - in column header
names(juan)[1] = 'Year'

mean(juan$Juan_Rating)              #  - 7.311
mean(juan$IMDB_Rating, na.rm=TRUE)  # - 6.99
mean(juan$Runtime, na.rm=TRUE)      # - 102.07

summary(juan)

library(ggplot2)
# Juan's rating by Genre
ggplot(data = juan) +
    aes(x = Top_Genre, y = Juan_Rating) +
    geom_boxplot(fill = "#4292c6") +
    labs(title = "Juan's Rating by Genre",
         x = "Genre",
         y = "Rating") +
    scale_x_discrete(labels=c('Action', 'Adv.', 'Anim.', 'Bio.', 'Comedy', 'Crime', 'Doc.', 'Drama', 'Fantasy', 'Horror', 'Sci-Fi')) +
    theme_classic()

ggsave('viz/juan-rating-genre.png')

#Rating differential by Genre
ggplot(data = subset(juan, !is.na(Top_Genre)),
    aes(x = Top_Genre, y = Rating_Diff)) +
    geom_boxplot(fill = "#4292c6") +
    labs(title = "Rating Differential by Genre",
         x = "Genre",
         y = "Juan - IMDB Rating") +
    scale_x_discrete(labels=c('Action', 'Adv.', 'Anim.', 'Bio.', 'Comedy', 'Crime', 'Doc.', 'Drama', 'Fantasy', 'Horror', 'Sci-Fi')) +
    theme_classic()

ggsave('viz/rating-diff-genre.png')

# Rating differential by year
ggplot(data = juan) +
    aes(x = factor(Year), y = Rating_Diff) +
    geom_boxplot(fill = "#4292c6") +
    labs(title = "Rating Differential by Year",
         x = "Year",
         y = "Rating") +
    theme_classic()

ggsave('viz/rating-diff-year.png')

# IMDB Rating by Year (general consensus)
ggplot(data = juan) +
    aes(x = factor(Year), y = IMDB_Rating) +
    geom_boxplot(fill = "#4292c6") +
    labs(title = "IMDB Rating by Year",
         x = "Year",
         y = "Rating") +
    theme_classic()

ggsave('viz/IMDB-rating-year.png')

# Average release year by year watched - lots of old movies in 2017
ggplot(data = juan) +
    aes(x = factor(Year), y = Released) +
    geom_boxplot(fill = "#4292c6") +
    labs(title = "Release year by Year Watched",
         x = "Year Watched",
         y = "Release Year") +
    theme_classic()

ggsave('viz/release-year.png')

# Rating differential by semester/season
ggplot(data = juan) +
    aes(x = factor(Period), y = Rating_Diff) +
    geom_boxplot(fill = "#4292c6") +
    labs(title = "Rating Differential by Season",
         x = "Year",
         y = "Rating") +
    theme_classic()

ggsave('viz/rating-diff-season.png')

# IMDB rating by semester/season
ggplot(data = juan) +
    aes(x = factor(Period), y = IMDB_Rating) +
    geom_boxplot(fill = "#4292c6") +
    labs(title = "IMDB Rating by Season",
         x = "Year",
         y = "Rating") +
    theme_classic()

ggsave('viz/IMDB-rating-season.png')

# Average release year by semester - lots of old movies in 2017
ggplot(data = juan) +
    aes(x = factor(Period), y = Released) +
    geom_boxplot(fill = "#4292c6") +
    labs(title = "Release year by Season",
         x = "Year Watched",
         y = "Release Year") +
    theme_classic()

ggsave('viz/release-semester.png')

#### ---- Scatter plots ----
library(ggplot2)

# Rating differential by movie popularity | r2 = 0.000, p = 0.71
votes_diff = lm(juan$Votes ~ juan$Rating_Diff)
summary(votes_diff)

ggplot(data = juan, aes(x = log(Votes), y = Rating_Diff)) +
    geom_point(color = "#0c4c8a") +
    geom_smooth(method='lm', formula = y~x) +
    labs(title = "Rating differential by log(Votes)",
         x = "log(Votes)",
         y = "Rating differential") +
    theme_minimal()

ggsave('viz/rating-diff-votes.png')

# IMDB rating by movie popularity | r2 = 0.089, p = ~0 
votes_imdb = lm(juan$Votes ~ juan$IMDB_Rating)
summary(votes_imdb)

ggplot(data = juan, aes(x = log(Votes), y = IMDB_Rating)) +
    geom_point(color = "#0c4c8a") +
    geom_smooth(method='lm', formula = y~x) +
    labs(title = "IMDB Rating by log(Votes)",
         x = "log(Votes)",
         y = "IMDB Rating") +
    theme_minimal()

ggsave('viz/IMDB-rating-votes.png')

# Juan rating by movie popularity | r2 = 0.019 , p = 0.01
votes_juan = lm(juan$Votes ~ juan$Juan_Rating)
summary(votes_juan)

ggplot(data = juan, aes(x = log(Votes), y = Juan_Rating)) +
    geom_point(color = "#0c4c8a") +
    geom_smooth(method='lm', formula = y~x) +
    labs(title = "Juan Rating by log(Votes)",
         x = "log(Votes)",
         y = "Juan Rating") +
    theme_minimal()

ggsave('viz/juan-rating-votes.png')

# IMDB rating by runtime | r2 = 0.03 , p= ~0
runtime_imdb = lm(juan$Runtime ~ juan$IMDB_Rating)
summary(runtime_imdb)

ggplot(data = juan, aes(x = Runtime, y = IMDB_Rating)) +
    geom_point(color = "#0c4c8a") +
    geom_smooth(method='lm', formula = y~x) + 
    labs(title = "IMDB Rating by Runtime (min)",
         x = "Runtime (min)",
         y = "IMDB Rating") +
    theme_minimal()

ggsave('viz/IMDB-rating-runtime.png')



    













