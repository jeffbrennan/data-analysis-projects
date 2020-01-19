# Libraries

library(dplyr)
library(tidyr)
library(data.table)

# Graphics
library(ggplot2)
library(ggpubr)
library(GGally)
library(EnvStats)
library(ggrepel)
library(stringr)
# Setup ----

# load cleaned data
juan_dt = fread('data/juan/cleaned_data.csv')

# TODO: add to cleaning
qcut = function(x, n) {
  quantiles = seq(0, 1, length.out = n+1)
  cutpoints = unname(quantile(x, quantiles, na.rm = TRUE))
  cut(x, cutpoints, include.lowest = TRUE)
}
# juan_dt$Year_Group =cut(juan_dt$Year_IMDB, seq(from = 1919, to = 2020, by = 20),
#                           labels = c('1920 - 1940', '1940 - 1960',
#                                      '1960 - 1980', '1980 - 2000',
#                                      '2000 - 2020'))

# TODO: make more elegant
juan_dt$Year_Group = factor()
juan_dt[Year_IMDB >= 1920 & Year_IMDB < 1980][, 'Year_Group'] = '1920 - 1980'
juan_dt[Year_IMDB >= 1980 & Year_IMDB < 2000][, 'Year_Group'] = '1980 - 2000'
juan_dt[Year_IMDB >= 2000 & Year_IMDB < 2010][, 'Year_Group'] = '2000 - 2010'
juan_dt[Year_IMDB >= 2010 & Year_IMDB < 2015][, 'Year_Group'] = '2010 - 2015'
juan_dt[Year_IMDB >= 2015 & Year_IMDB < 2020][, 'Year_Group'] = '2015 - 2020'


setDT(juan_dt)[, Popularity := qcut(Votes_IMDB, 5)]
levels(juan_dt$Popularity) = c('Indie', 'Regular', 'Regular', 'Regular', 'Blockbuster')

juan_dt$Type_IMDB = as.factor(juan_dt$Type_IMDB)

other_types = !(levels(juan_dt$Type_IMDB) %in% c('movie', 'tvSeries', 'tvSpecial'))
levels(juan_dt$Type_IMDB)[other_types] = 'other'

juan_dt$Top_Genre = as.factor(juan_dt$Top_Genre)
other_genres = (levels(juan_dt$Top_Genre) %in% c('Animation', 'Reality-TV', 'Fantasy', 'Music', 'Talk-Show'))
levels(juan_dt$Top_Genre)[other_genres] = 'Other'

juan_dt$Label = with(juan_dt, paste0(str_wrap(Title_IMDB, 20),
                                     '\nIMDB: ', round(Rating_IMDB, 1),
                                     ' | Juan: ', Rating))

# create subsets based on type
movie_dt = subset(juan_dt, Type_IMDB == 'movie')
tv_dt = subset(juan_dt, Type_IMDB == 'tvSeries')


# jayhawk colors
ku_blu = '#0066B1'
ku_red = '#E8000D'
ku_ylw = '#FFC82D'
ku_gry = '#85898A'

# EXPLORATION ----



# Overall - by movie type
ggplot(juan_dt, aes(x = reorder(Type_IMDB, as.factor(Type_IMDB), function(x) - length(x)),
                    y = Rating_Diff)) +
  geom_abline(slope = 0, intercept = 0, linetype = 'dashed', color = 'grey', size = 0.75) +
  geom_boxplot(outlier.shape = NA, size = 0.6, coef = 0) +
  geom_point(aes(color = abs(Rating_Diff), size = abs(Rating_Diff))) +
  stat_n_text(y.expand.factor = 0.15) +
  geom_label_repel(data = subset(juan_dt, Rating_Diff < -4.75 |
                                          Rating_Diff > 3 |
                                          (Rating_Diff < -4 & Type_IMDB != 'movie')),
                   mapping = aes(label = Label), min.segment.length = 0, size = 3.5) +
  scale_size_continuous('', range = c(0.5, 4)) +
  scale_color_continuous('', low = 'gray90', high = ku_ylw) +
  labs(x = '') +
  theme_pubr() +
  theme(axis.text.x = element_text(vjust = -0.5),
        legend.position = 'none')

# Decade
ggplot(juan_dt, aes(x = Year_Group, y = Rating_Diff)) +
  geom_abline(slope = 0, intercept = 0, linetype = 'dashed', color = 'grey', size = 0.75) +
  geom_boxplot(outlier.shape = NA, size = 0.6, coef = 0) +
  geom_point(aes(color = abs(Rating_Diff), size = abs(Rating_Diff))) +
  stat_n_text(y.expand.factor = 0.15) +
  geom_label_repel(data = subset(juan_dt, Rating_Diff < -4.75 |
                                 Rating_Diff > 3 |
                                 (Rating_Diff > 2.5 & Year_Group != '2015 - 2020')),
                   mapping = aes(label = Label), min.segment.length = 0) +
  scale_size_continuous('', range = c(0.5, 4)) +
  scale_color_continuous('', low = 'gray90', high = ku_red) +
  labs(x = '') +
  theme_pubr() +
  theme(legend.position = 'none')


# Genre
ggplot(juan_dt, aes(x = reorder(Top_Genre, as.factor(Top_Genre), function(x) - length(x)),
                    y = Rating_Diff)) +
  geom_abline(slope = 0, intercept = 0, linetype = 'dashed', color = 'grey', size = 0.75) +
  geom_boxplot(outlier.shape = NA, size = 0.6, coef = 0) +
  geom_point(aes(color = abs(Rating_Diff), size = abs(Rating_Diff))) +
  stat_n_text(y.expand.factor = 0.15) +
  geom_label_repel(data = subset(juan_dt, Rating_Diff < -4.75 |
                                   Rating_Diff > 3 |
                                   (Rating_Diff < - 5)),
                   mapping = aes(label = Label), min.segment.length = 0, size = 3.5) +
  scale_size_continuous('', range = c(0.5, 4)) +
  scale_color_continuous('', low = 'gray90', high = ku_blu) +
  labs(x = '') +
  theme_pubr() +
  theme(axis.text.x = element_text(vjust = -0.5, angle = -45),
        legend.position = 'none')


# Popularity
ggplot(subset(juan_dt, !is.na(Popularity)), aes(x = Popularity, y = Rating_Diff)) +
  geom_abline(slope = 0, intercept = 0, linetype = 'dashed', color = 'grey', size = 0.75) +
  geom_boxplot(outlier.shape = NA, size = 0.6, coef = 0) +
  geom_point(aes(color = abs(Rating_Diff), size = abs(Rating_Diff))) +
  stat_n_text() +
  geom_label_repel(data = subset(juan_dt, Rating_Diff < -4.75 | Rating_Diff > 3),
                   mapping = aes(label = Title_IMDB), min.segment.length = 0) +
  scale_size_continuous('', range = c(0.5, 4)) +
  scale_color_continuous('', low = 'gray90', high = ku_red) +
  labs(x = '') +
  theme_pubr() +
  theme(legend.position = 'none')

# Votes
ggplot(juan_dt, aes(x = log(Votes_IMDB), y = Rating_Diff)) +
  geom_abline(slope = 0, intercept = 0, linetype = 'dashed', color = 'grey', size = 0.75) +
  # geom_boxplot(outlier.shape = NA, size = 0.6, coef = 0) +
  geom_point(color = ku_red) +
  geom_smooth(size = 1.5, fill = 'grey80') +
  # stat_n_text(y.expand.factor = 0.15) +
  # geom_label_repel(data = subset(juan_dt, Rating_Diff < -4.75 |
                                   # Rating_Diff > 3 |
                                   # (Rating_Diff > 2.5 & Votes_IMDB != '2015 - 2020')),
                   # mapping = aes(label = Label), min.segment.length = 0) +
  # scale_size_continuous('', range = c(0.5, 4)) +
  # scale_color_continuous('', low = 'gray90', high = ku_red) +
  scale_color_manual('', values = c(ku_gry, ku_ylw, ku_blu, ku_red)) +
  # lab +
  theme_pubr() +
  theme(legend.position = 'none')



# Time
ggplot(juan_dt, aes(x = ID_Juan, y = Rating_Diff, color = as.factor(Viewed))) +
  geom_abline(slope = 0, intercept = 0, linetype = 'dashed', color = 'grey', size = 0.75) +
  # geom_point(size = abs(juan_dt$Rating_Diff)) +
  geom_point(alpha = 0.5) +
  geom_smooth(size = 1.5, fill = 'grey80') +
  # facet_wrap(~ Viewed, nrow = 1) +
  scale_color_manual('', values = c(ku_gry, ku_ylw, ku_blu, ku_red)) +
  labs(x = '') +
  theme_pubr()


# Movies ----
ggplot(movie_dt, aes(x = Top_Genre, y = Rating_Diff)) +
  geom_boxplot(fill = ku_blu) +
  stat_n_text() +
  theme_pubr()


# Votes
ggplot(movie_dt, aes(x = log(Votes_IMDB), y = Rating_Diff, color = as.factor(Viewed))) +
  geom_point(size = 2) +
  geom_smooth(fill = NA) +
  geom_text() +
  scale_color_manual('', values = c(ku_gry, ku_blu, ku_ylw, ku_red)) +
  theme_pubr()


# Viewed year
ggplot(movie_dt, aes(x = Viewed, y = Rating_Diff)) +
  geom_boxplot() +
  stat_n_text() +
  theme_pubr()


# Movie year
ggplot(movie_dt, aes(x = Year_IMDB, y = Rating, color = Viewed)) +
  geom_point() +
  theme_pubr()

# TV ----

tv_dt$Season = as.numeric(tv_dt$Season)
tv_dt$Season_group = cut(tv_dt$Season, c(0, 1, 3, max(tv_dt$Season, na.rm = T)),
                         labels = c('1', '2 & 3', '4+'))


ggplot(tv_dt, aes(x = Season_group, y = Rating_Diff)) +
  geom_boxplot() +
  stat_n_text() +
  theme_pubr()


# REGRESSION ----

# Movies ----
# TV ----