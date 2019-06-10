import pandas as pd
# import timing
import math

# Imports all needed csvs with encoding that handles foreign chars
titles = pd.read_csv('imdb_data/data.tsv', sep='\t', encoding='utf-8-sig')
ratings = pd.read_csv('imdb_data/ratings.tsv', sep='\t', encoding='utf-8-sig')
juans_movies = pd.read_csv('juan_files/juan_movies.csv', encoding='utf-8-sig')

# Gets top votes for each title, renames IMDB strings and drops unneeded columns
def imdb_format(df):
    # Removes rows with non-movie media types and then selects the one with the highest number of votes 
    new_df = df.sort_values('numVotes', ascending=False).drop_duplicates(['Title'])
    new_df = new_df.rename(index=str, columns={'runtimeMinutes': 'Runtime', 'Rating': 'Juan_Rating',
                                                    'averageRating': 'IMDB_Rating', 'startYear': 'Released',
                                                    'numVotes': 'Votes', 'titleType': 'Type'})                     
    new_df = new_df.drop(columns=['originalTitle', 'tconst', 'isAdult', 'endYear'])
    return new_df

# Gets imdb related info for most of juans movies
def movie_merge(titles, ratings, juans_movies):
    # merges ratings and titles from IMDB on their unique id, then drops specified title types
    # ~ returns all rows that do not include values of the list
    imdb = titles.merge(ratings, left_on='tconst', right_on='tconst')
    imdb = imdb.rename(index=str, columns={'primaryTitle': 'Title'})
    imdb = imdb[~imdb.titleType.isin(['tvEpisode', 'videoGame', 'tvSeries'])]

    # performs a left join - preserves all rows in juan's list and matches all titles in imdb list
    juan_imdb = juans_movies.merge(imdb, left_on='Title', right_on='Title', how='left')
    juan_imdb = imdb_format(juan_imdb)

    # finds the location of all valid numbers (years) in the Title_Year column
    year_loc = [i for i,x in enumerate(juan_imdb['Title_Year']) if not math.isnan(x)]

    # for each title from a specific year, grabs the matching title and release year from IMDB
    for row in year_loc:
        juan_title = juan_imdb['Title'][row].strip()
        juan_year = str(int(juan_imdb['Title_Year'][row]))

        correct_result = imdb.loc[(imdb['Title'] == juan_title) & (imdb['startYear'] == juan_year)]
        correct_result = imdb_format(correct_result)

        cr_list = correct_result.values.tolist()[0]
        del cr_list[1] # removes title to avoid duplication in new df 
        column_pointer = 5

        # replaces cell with correct info
        for item in cr_list:
            juan_imdb.iat[row, column_pointer] = item
            column_pointer += 1

    return juan_imdb

def movie_transform(combined_df):

    # Gets first genre, adds to list, then adds to dataframe
    genres = []
    df_genres = combined_df['genres'].tolist()
    for i in range(len(df_genres)):
        try:
            top_genre = df_genres[i].split(',')[0]
            genres.append(top_genre)
        except AttributeError: 
            genres.append('')

    combined_df = combined_df.replace(r'\\N','', regex=True) # remove any newlines from the imdb

    # creates two new calculated columns
    combined_df['Rating_Diff'] = combined_df['Juan_Rating'] - combined_df['IMDB_Rating']
    combined_df['Top_Genre'] = genres

    # Reindexes df to display original watched order (instead of most popular), sets header to 'Key'
    # Converting index to integer means that it goes 1,2,3 instead of 1,100,101...
    combined_df.index = combined_df.index.astype(int)
    combined_df.index.name = 'Key'
    combined_df = combined_df.sort_index()

    # 'utf-8-sig' fixes encoding errors when reading in excel [utf-8 still produces errors]
    combined_df.to_csv('output/juan_imdb.csv', encoding='utf-8-sig')
    return combined_df

combined_df = movie_merge(titles, ratings, juans_movies)
output_df = movie_transform(combined_df)
