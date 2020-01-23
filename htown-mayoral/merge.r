library(dplyr)
library(jsonlite)

# SETUP ----

# melt all contests
id_vars = c('i', 'p', 't', 'rv', 'bc', 's')

# load and combine .json data
all_files = list.files('data/contests')
all_files = paste0('data/contests/', all_files)

# load ballot data dictionary
contest_info = fromJSON(readLines(file('data/ballot.json'), -1L))[['contests']]


# point to individual json files and read them
load_files = lapply(all_files, function(x) file(x, 'r'))
read_files = lapply(load_files, function(x) readLines(x, -1L))
closeAllConnections()  # close open connections

# parse the raw string jsons into a list of lists, then convert to dataframe
json_parse = lapply(read_files, function(x) fromJSON(x, flatten = TRUE))
all_contests = lapply(json_parse, function(x) as.data.frame(x))


# replace auto generated var names (v.1, v2 ...) with corresponding contest choices
for (contest in seq(1:nrow(contest_info))){
  info_id = contest_info[contest, 'i']
  
  df_match = which(unlist(lapply(all_contests, function(x) info_id %in% x[['i']])))
  
  all_cols = colnames(all_contests[[df_match]])
  choice_cols = which(!colnames(all_contests[[df_match]]) %in% id_vars)
  all_cols[choice_cols] = unlist(contest_info[contest, 'ca'])
  
  colnames(all_contests[[df_match]]) = all_cols
}


contest_melt = lapply(all_contests, function(x) reshape2::melt(x, id = id_vars))
contest_df = do.call(rbind, contest_melt)


# CLEANING ----
colnames(contest_df) = c('contest', 'precinct', 'precinct_votes', 'reg_voters',
                         'ballots_cast', 's', 'choice', 'choice_votes')

# drop s (unsure what it does)
contest_df$s = NULL


# add calculated cols 
contest_df = contest_df %>%
  group_by(contest, precinct) %>%
  mutate(turnout = round(ballots_cast / reg_voters, 3)) %>%
  mutate(contest_votes = round(precinct_votes / ballots_cast, 3)) %>%
  group_by(choice) %>%
  mutate(choice_pct = round(choice_votes/precinct_votes, 2))


# check calculated cols
# TODO: resolve weird stuff with turnout and contest votes, for now, set NA
contest_df[which(contest_df$contest_votes > 1), 'contest_votes'] = NA
contest_df[which(contest_df$turnout > 1), 'turnout'] = NA


# add contest names by id
contest_df = merge(contest_df, contest_info[, c('i', 't')], by.x = 'contest', by.y = 'i')

colnames(contest_df)[1] = 'id'
colnames(contest_df)[which(names(contest_df) == 't')] <- 'contest'


# output for analysis
write.csv('data/contest_df.csv', row.names = FALSE)
