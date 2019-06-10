import requests
import json
import pandas as pd
from bs4 import BeautifulSoup
import unidecode
import timing

wiki_url = ('https://en.wikipedia.org/wiki/List_of_current_UFC_fighters')
ufc_url = ('http://ufc-data-api.ufc.com/api/v3/iphone/fighters')
ufc_stat_url = ('http://ufc-data-api.ufc.com/api/v3/iphone/fighters/stats')
fox_stat_url = ('https://www.foxsports.com/ufc/stats?weightclass=11&category=ADVANCED&time=1&sort=0&opp=0&sortOrder=0&page=')

def ufc_basic_get(url):
    ufc_df = pd.DataFrame(columns=['Fighter_ID', 'First_Name', 'Nickname',
                                   'Last_Name', 'Weight_Class', 'StatID',
                                   'Wins', 'Losses', 'Draws', 'Title_Holder',
                                   'Rank', 'P4P_Rank', 'Status', 'Link'])

    fighter_data = requests.get(url)
    fighter_results = json.loads(fighter_data.content)

    row_counter = 0
    for i in fighter_results:
        fighter = [i['id'], i['first_name'], i['nickname'],
                   i['last_name'], i['weight_class'], i['statid'],
                   i['wins'], i['losses'], i['draws'], i['title_holder'],
                   i['rank'], i['pound_for_pound_rank'],
                   i['fighter_status'], i['link']]
        ufc_df.loc[row_counter] = fighter
        row_counter += 1

    ufc_df.to_csv('output/UFC-results.csv', encoding='utf8', index=False)
    return ufc_df

def ufc_stat_get(url):
    stat_columns = ['StatID', 'Stat', 'Value', 'Rank']
    stat_df = pd.DataFrame(columns=stat_columns)

    fighter_stats = requests.get(url)
    stat_results = json.loads(fighter_stats.content)

    row_counter = 0
    for i in stat_results:
        stat = [i['statid'], i['stat'], i['Value'], i['Rank']]

        stat_df.loc[row_counter] = stat
        row_counter += 1

    stat_df.to_csv('output/UFC-stats.csv', encoding='utf8', index=False)
    return stat_df

def fox_get(url):
    fox_stats = []
    for pg_counter in range(1, 16):
        print('Getting stats from page: ' + str(pg_counter))

        response = requests.get(url + (str(pg_counter)))
        html = response.content
        page = BeautifulSoup(html, 'html.parser')

        table = page.find('tbody')
        for row in table.find_all('tr'):

            link = row.find('td').find('a', attrs={'class': 'wisbb_fullPlayer'}, href=True)['href']
            link = link[5:-6:]

            name = row.find('td').find('a', attrs={'class': 'wisbb_fullPlayer'}).find('span').text
            last_first = name.split(',')
            first_last = last_first[1].strip() + ' ' + last_first[0]

            stat = [first_last] + [link] + [row.find_all('td')[i].text.strip('\n') for i in range(1, 10)]
            fox_stats.append(stat)

        page.decompose()
        response.close()  # closes connection so rapid retries don't fail

    fox_df = pd.DataFrame(columns=['Name', 'Link', 'Fights', 'TotStrike', 'StrikeAcc', 'HeadStrike', 'HeadAcc',
                                   'BodyStrike', 'BodyAcc', 'LegStrike', 'LegAcc'])

    fox_df = fox_df.append(pd.DataFrame(fox_stats, columns=fox_df.columns))
    return fox_df

def wiki_get(url):
    ages = []
    names = []
    heights = []
    countries = []

    response = requests.get(url)
    html = response.content
    page = BeautifulSoup(html, 'html.parser')

    tables = page.find_all('table', attrs={'class': 'wikitable sortable'})  # get all tables

    for table in tables[3:15]:
        for row in table.find_all('tr')[1:]:
            try:
                name = row.find_all('td')[1].find('a').text
                name = unidecode.unidecode(name)
                names.append(name)

                age = row.find_all('td')[2].text[-3:].strip()
                ages.append(age)

                height = row.find_all('td')[3].text  # Remove extra tags
                height = height.replace(u'\xa0', u'').strip()  # Strip blankspace, remove unicode
                feet = int(height[0]) * 12  # Convert first character of cell to inches
                height = feet + int((height[height.find(' '): height.find('i')]))  # returns fighters height in inches
                heights.append(height)

                country = row.find_all('a', href=True)[0]['title']
                countries.append(country)

            except AttributeError:
                continue

    page.decompose()
    response.close()  # closes connection so rapid retries don't fail

    results = [names, countries, ages, heights]

    wiki_df = pd.DataFrame(results).T
    wiki_df.columns = ['Full_Name', 'Country', 'Age', 'Height']

    wiki_df.to_csv('output/wiki-results.csv', encoding='utf8', index=False)
    return wiki_df

def df_transform(main_df, helper_df, stat_df):

    weights = []
    weight_d = {'Heavyweight': 265, 'Light_Heavyweight': 205, 'Middleweight': 185, 'Welterweight': 170,
                'Lightweight': 155, 'Featherweight': 145, 'Bantamweight': 135, 'Flyweight': 125,
                'Women_Featherweight': 145, 'Women_Bantamweight': 135, 'Women_Flyweight': 125,
                'Women_Strawweight': 115}

    main_df['Full_Name'] = main_df['First_Name'] + ' ' + main_df['Last_Name']
    ufc_df = main_df.merge(helper_df, left_on='Full_Name', right_on='Full_Name')

    weight_classes = ufc_df['Weight_Class']

    for i in weight_classes:
            if i in weight_d:
                weights.append(weight_d[i])
            else:
                weights.append('')

    ufc_df['Weight'] = weights
    ufc_df['Weight'] = pd.to_numeric(ufc_df['Weight'], errors='coerce')
    ufc_df['Weight'] = ufc_df['Weight'].astype(float)

    ufc_df['Height'] = ufc_df['Height'].astype(float)

    ufc_df['BMI'] = (ufc_df['Weight'] / (ufc_df['Height'] * ufc_df['Height'])) * 703

    # Adding statistics to the dataframe
    stat_columns = ['AvgFightTimeLong', 'AvgFightTimeShort', 'TakedownsLanded', 'TakedownDefense',
                    'TakedownAccuracy', 'SubmissionAttempts', 'SubmissionAverage',
                    'SigStrikesLanded', 'SigStrikesAccuracy', 'Knockdowns', 'SLpM', 'SApM',
                    'PlusMinus', 'SigStrikingDefense', 'TotStrikesLanded']

    ufc_df = ufc_df.reindex(columns=[*ufc_df.columns.tolist(), *stat_columns])

    ufc_df['StatID'] = ufc_df['StatID'].astype(float)
    stat_df['StatID'] = stat_df['StatID'].astype(float)

    # Sets all columns to objects to aid in transfer from the statistics dataframe to the main dataframe
    for column in ufc_df.columns[20:]:
        ufc_df[column] = ufc_df[column].astype(object)

    column_pointer = 20
    for column in ufc_df.columns[20:]:
        for row in range(len(ufc_df)):
            for result in range(len(stat_df)):
                if (stat_df['Stat'][result] == column and ufc_df['StatID'][row] == stat_df['StatID'][result]):

                    ufc_df.iat[row, column_pointer] = stat_df.iat[result, 2]

        column_pointer += 1
    ufc_df = ufc_df.merge(fox_df, left_on='Full_Name', right_on='Full_Name', how='outer')
    ufc_df.to_csv('output/UFC-fighters.csv', index=False)

ufc_df = ufc_basic_get(ufc_url)
stat_df = ufc_stat_get(ufc_stat_url)
fox_df = fox_get(fox_stat_url)
wiki_df = wiki_get(wiki_url)

df_transform(ufc_df, wiki_df, stat_df, fox_df)
