import requests
import json
import pandas as pd
from bs4 import BeautifulSoup
import unidecode
import timing
import datetime as DT
import numpy as np
fox_stat_url = ('https://www.foxsports.com/ufc/stats?weightclass=11&category=ADVANCED&time=1&sort=0&opp=0&sortOrder=0&page=')

def bio_transform(bio_df):
    heights = []
    weights = []

    height_weight = bio_df['Height_Weight'].tolist()

    for i in range(len(height_weight)):
        height = height_weight[i].split(',')[0][:-1]
        height_in = (int(height.split("'")[0]) * 12) + int(height.split("'")[1])
        heights.append(height_in)

        weight = height_weight[i].split(',')[1][:-3]
        weights.append(int(weight))

    bio_df['Height'] = heights
    bio_df['Weight'] = weights
    bio_df['BMI'] = (bio_df['Weight'] / (bio_df['Height'] * bio_df['Height'])) * 703
    bio_df['Name'] = bio_df['Fighter']

    bio_df['Reach'] = bio_df['Reach'].replace(to_replace='--', value='')
    bio_df['Reach'] = bio_df['Reach'].astype(str).str[:-1]
    bio_df['Reach'] = pd.to_numeric(bio_df['Reach'], errors='coerce').__round__(3)
    bio_df['HR_Ratio'] = bio_df['Reach'] / bio_df['Height']

    now = pd.Timestamp(DT.datetime.now())
    bio_df['DoB'] = pd.to_datetime(bio_df['DoB'], format='%m-%d-%y')
    bio_df['DoB'] = bio_df['DoB'].where(bio_df['DoB'] < now, bio_df['DoB'] - np.timedelta64(100, 'Y'))
    bio_df['Age'] = (now - bio_df['DoB']).astype('<m8[Y]').astype(int)

    bio_df = bio_df.drop(['Height_Weight', 'Fighter'], axis=1)
    bio_df = bio_df[['Name', 'DoB', 'Age', 'Height', 'Weight', 'BMI', 'Reach', 'HR_Ratio', 'Style', 'From', 'Trains']]

    bio_df.to_csv('output/bio_df-1.csv', index=False)
    return bio_df

def fighter_transform(fighter_df):
    fighter_df['W/L'] = fighter_df['Wins'] / (fighter_df['Wins'] + fighter_df['Losses'])
    fighter_df.to_csv('output/fighter_df-1.csv', index=False)
    return fighter_df

def striking_transform(striking_df):
    print(striking_df)
    striking_df = striking_df.rename(index=str, columns={"F_FIGHTS": "FIGHTS", "F_ROUNDS": "ROUNDS", "F_MINS": "MINS"})
    striking_df = striking_df.drop(['O_FIGHTS', 'F_FIGHTS_2', 'O_FIGHTS_2', 'O_ROUNDS', 'O_MINS'], axis=1)
    striking_df.to_csv('output/striking_df-1.csv', index=False)
    return striking_df

def df_merge(bio_df, fighter_df, striking_df):

    ufc_df = fighter_df.merge(bio_df, left_on='Name', right_on='Name')
    ufc_df = ufc_df.merge(striking_df, left_on='Name', right_on='Name')
    ufc_df.to_csv('output/dataset.csv', index=False)
    return ufc_df


# bio_df = pd.read_csv('output/bio_df.csv')
# # bio_df = bio_transform(bio_df)

# # fighter_df = fighter_transform(fighter_df)

# striking_df = pd.read_csv('output/striking_stats_df.csv')
# striking_df = striking_transform(striking_df)
# ufc_df = df_merge(bio_df, fighter_df, striking_df)
# print(ufc_df)
# ufc_df.to_csv('merge-test-1.csv', index=False)

def stat_get(fighter_df, base_url):
    results = []
    time_dict = {0: 'Total', 1: 'Per fight', 2: 'Per round', 3: 'Per Minute'}
    for i in range(len(fighter_df['Link']))[1:2]:
        sub_results = []
        name = fighter_df['Name'][i]
        print('Grabbing striking stats for ' + name)

        try:
            for strike_time in range(4):

                response = requests.get(base_url + fighter_df['Link'][i] + '-stats?time=' + str(strike_time))
                html = response.content
                page = BeautifulSoup(html, 'html.parser')

                basic_table = page.find_all('tbody')[2]
                sig_table = page.find_all('tbody')[3]

                for i in range(2):
                    basic_row = basic_table.find_all('tr')[i]
                    basic_len = len(basic_row.find_all('td'))
                    basic_result = [basic_row.find_all('td')[i].text.strip('\n') for i in range(1, basic_len)]

                    sig_row = sig_table.find_all('tr')[i]
                    sig_len = len(sig_row.find_all('td'))
                    sig_result = [sig_row.find_all('td')[i].text.strip('\n') for i in range(2, sig_len)]

                    sub_results.extend(basic_result + sig_result)

        except IndexError:  # some listed pages lead to 404 errors
            print(name + ' 404 ERROR\n')
            continue
        
        results.append([name] + sub_results)
        print(results)

    # stat_df = pd.DataFrame(columns=['Stat_Time', 'Name', 'Fighter', 'Time_Unit', 'STR', 'TSAC',
    #                                 'TD', 'TDAC', 'KD', 'PASS', 'REV', 'SUB',
    #                                 'SIG_STR_TOT', 'SIG_STR_ACC', 'SIG_HEAD', 'SIG_HEAD_ACC',
    #                                 'SIG_BODY', 'SIG_BODY_ACC', 'SIG_LEG', 'SIG_LEG_ACC'])

    stat_df = pd.DataFrame(columns=['Name', 'F_FIGHTS', 'STR_F_TOT', 'TSAC_F_TOT',
                                    'TD_F_TOT', 'TDAC_F_TOT', 'KD_F_TOT', 'PASS_F_TOT', 'REV_F_TOT', 'SUB_F_TOT',
                                    'SIG_STR_F_TOT', 'SIG_ACC_F_TOT', 'SIG_HEAD_F_TOT', 'SIG_HEAD_ACC_F_TOT',
                                    'SIG_BODY_F_TOT', 'SIG_BODY_ACC_F_TOT', 'SIG_LEG_F_TOT', 'SIG_LEG_ACC_F_TOT',

                                    'O_FIGHTS', 'STR_O_TOT', 'TSAC_O_TOT', 'TD_O_TOT', 'TDAC_O_TOT', 'KD_O_TOT', 'PASS_O_TOT',
                                    'REV_O_TOT', 'SUB_O_TOT', 'SIG_STR_O_TOT', 'SIG_ACC_O_TOT', 'SIG_HEAD_O_TOT',
                                    'SIG_HEAD_ACC_O_TOT', 'SIG_BODY_O_TOT', 'SIG_BODY_ACC_O_TOT', 'SIG_LEG_O_TOT',
                                    'SIG_LEG_ACC_O_TOT',

                                    'F_FIGHTS_2', 'STR_F_FIGHT', 'TSAC_F_FIGHT', 'TD_F_FIGHT', 'TDAC_F_FIGHT', 'KD_F_FIGHT',
                                    'PASS_F_FIGHT', 'REV_F_FIGHT', 'SUB_F_FIGHT', 'SIG_STR_F_FIGHT', 'SIG_ACC_F_FIGHT',
                                    'SIG_HEAD_F_FIGHT', 'SIG_HEAD_ACC_F_FIGHT', 'SIG_BODY_F_FIGHT',
                                    'SIG_BODY_ACC_F_FIGHT', 'SIG_LEG_F_FIGHT', 'SIG_LEG_ACC_F_FIGHT',

                                    'O_FIGHTS_2', 'STR_O_FIGHT', 'TSAC_O_FIGHT', 'TD_O_FIGHT', 'TDAC_O_FIGHT', 'KD_O_FIGHT',
                                    'PASS_O_FIGHT', 'REV_O_FIGHT', 'SUB_O_FIGHT', 'SIG_STR_O_FIGHT', 'SIG_ACC_O_FIGHT',
                                    'SIG_HEAD_O_FIGHT', 'SIG_HEAD_ACC_O_FIGHT', 'SIG_BODY_O_FIGHT', 
                                    'SIG_BODY_ACC_O_FIGHT', 'SIG_LEG_O_FIGHT', 'SIG_LEG_ACC_O_FIGHT',

                                    'F_ROUNDS', 'STR_F_ROUND', 'TSAC_F_ROUND', 'TD_F_ROUND', 'TDAC_F_ROUND', 'KD_F_ROUND',
                                    'PASS_F_ROUND', 'REV_F_ROUND', 'SUB_F_ROUND', 'SIG_STR_F_ROUND',
                                    'SIG_ACC_F_ROUND', 'SIG_HEAD_F_ROUND', 'SIG_HEAD_ACC_F_ROUND', 'SIG_BODY_F_ROUND',
                                    'SIG_BODY_ACC_F_ROUND', 'SIG_LEG_F_ROUND', 'SIG_LEG_ACC_F_ROUND',

                                    'O_ROUNDS', 'STR_O_ROUND', 'TSAC_O_ROUND', 'TD_O_ROUND', 'TDAC_O_ROUND', 'KD_O_ROUND',
                                    'PASS_O_ROUND', 'REV_O_ROUND', 'SUB_O_ROUND', 'SIG_STR_O_ROUND',
                                    'SIG_ACC_O_ROUND', 'SIG_HEAD_O_ROUND', 'SIG_HEAD_ACC_O_ROUND', 'SIG_BODY_O_ROUND',
                                    'SIG_BODY_ACC_O_ROUND', 'SIG_LEG_O_ROUND', 'SIG_LEG_ACC_O_ROUND',

                                    'F_MINS', 'STR_F_MIN', 'TSAC_F_MIN', 'TD_F_MIN', 'TDAC_F_MIN', 'KD_F_MIN', 'PASS_F_MIN', 
                                    'REV_F_MIN', 'SUB_F_MIN', 'SIG_STR_F_MIN', 'SIG_ACC_F_MIN', 'SIG_HEAD_F_MIN',
                                    'SIG_HEAD_ACC_F_MIN', 'SIG_BODY_F_MIN', 'SIG_BODY_ACC_F_MIN', 'SIG_LEG_F_MIN', 
                                    'SIG_LEG_ACC_F_MIN',

                                    'O_MINS', 'STR_O_MIN', 'TSAC_O_MIN', 'TD_O_MIN', 'TDAC_O_MIN', 'KD_O_MIN', 'PASS_O_MIN', 
                                    'REV_O_MIN', 'SUB_O_MIN', 'SIG_STR_O_MIN', 'SIG_ACC_O_MIN', 'SIG_HEAD_O_MIN',
                                    'SIG_HEAD_ACC_O_MIN', 'SIG_BODY_O_MIN', 'SIG_BODY_ACC_O_MIN', 'SIG_LEG_O_MIN', 
                                    'SIG_LEG_ACC_O_MIN'])

    stat_df = stat_df.append(pd.DataFrame(results, columns=stat_df.columns))
    print(stat_df)
    # stat_df.to_csv('output/striking_df.csv', index=False)
    return stat_df

# fox_fighter_url = ('https://www.foxsports.com/ufc/')
# stat_df = stat_get(fighter_df, fox_fighter_url)

# striking_df = pd.read_csv('output/striking_df.csv')
# striking_df = striking_transform(striking_df)


# fighter_df = pd.read_csv('output/fighter_df.csv')
# bio_df = pd.read_csv('output/bio_df.csv')
# striking_df = pd.read_csv('output/striking_df.csv')

# fighter_df = fighter_transform(fighter_df)
# bio_df = bio_transform(bio_df)
# striking_df = striking_transform(striking_df)

# df_merge(bio_df, fighter_df, striking_df)


def fighter_get():
    fox_records = []
    for i in range(1, 2):
        print('Getting stats from page: ' + str(i))

        page = fox_request('https://www.foxsports.com/ufc/fighters?weightclass=0& \
                            teamId=0&season=2018&position=0&page=' + str(i) + '&country=0& \
                            grouping=1&weightclass=1&association=0&circuit=0&competition=0&organizationId=0')
        table = page.find('tbody')
        for row in table.find_all('tr'):

            link = row.find('td').find('a', attrs={'class': 'wisbb_fullPlayer'}, href=True)['href']
            link = link[5:-6:]

            name = row.find('td').find('a', attrs={'class': 'wisbb_fullPlayer'}).find('span').text
            last_first = name.split(',')
            first_last = last_first[1].strip() + ' ' + last_first[0]

            record = [first_last] + [link] + [row.find_all('td')[i].text.strip('\n') for i in range(1, 5)]
            fox_records.append(record)

    fighter_df = pd.DataFrame(columns=['Name', 'Link', 'Wins', 'Losses', 'Draws', 'NC'])

    fighter_df = fighter_df.append(pd.DataFrame(fox_records, columns=fighter_df.columns))
    fighter_df.to_csv('output/fighter_df-funct-test.csv', index=False)
    return fighter_df

def striking_get(fighter_df, base_url):
    results = []
    for i in range(len(fighter_df['Link'])):
        sub_results = []  # all striking stats are added to this, then added to main list
        name = fighter_df['Name'][i]
        print('Grabbing striking stats for ' + name)

        try:  # IndexError occurs when trying to find 'tbody' on a 404 page
            for strike_time in range(4):  # 4 striking times (0 - total, 1 - per fight, 2 - per round, 3 - per minute)

                strike_url = (base_url + fighter_df['Link'][i] + '-stats?time=' + str(strike_time))
                page = fox_request(strike_url)

                basic_table = page.find_all('tbody')[2]
                sig_table = page.find_all('tbody')[3]

                for x in range(2):  # gets data from the basic striking table and the significant striking table

                    # Grabs all data from the basic table (iterates twice - fighter and opponent, omits fighter type)
                    basic_row = basic_table.find_all('tr')[x]
                    basic_len = len(basic_row.find_all('td'))
                    basic_result = [basic_row.find_all('td')[cell].text.strip('\n') for cell in range(1, basic_len)]

                    # Grabs all data from sig striking table (omits the time unit and fighter type)
                    sig_row = sig_table.find_all('tr')[x]
                    sig_len = len(sig_row.find_all('td'))
                    sig_result = [sig_row.find_all('td')[cell].text.strip('\n') for cell in range(2, sig_len)]

                    # Extends results each loop (4 times total - 8 types of data -> 1 list for each fighter)
                    sub_results.extend(basic_result + sig_result)

        except IndexError:  # some listed pages lead to 404 errors
            print(name + ' 404 ERROR\n')
            continue

        results.append([name] + sub_results)
    # F_ / O_ = fighter / opponent
    # TOT / FIGHT / ROUND / MIN = total stats, stats per fight, stats per round, stats per min
    stat_df = pd.DataFrame(columns=['Name', 'F_FIGHTS', 'STR_F_TOT', 'TSAC_F_TOT',
                                    'TD_F_TOT', 'TDAC_F_TOT', 'KD_F_TOT', 'PASS_F_TOT', 'REV_F_TOT', 'SUB_F_TOT',
                                    'SIG_STR_F_TOT', 'SIG_ACC_F_TOT', 'SIG_HEAD_F_TOT', 'SIG_HEAD_ACC_F_TOT',
                                    'SIG_BODY_F_TOT', 'SIG_BODY_ACC_F_TOT', 'SIG_LEG_F_TOT', 'SIG_LEG_ACC_F_TOT',

                                    'O_FIGHTS', 'STR_O_TOT', 'TSAC_O_TOT', 'TD_O_TOT', 'TDAC_O_TOT', 'KD_O_TOT',
                                    'PASS_O_TOT', 'REV_O_TOT', 'SUB_O_TOT', 'SIG_STR_O_TOT', 'SIG_ACC_O_TOT',
                                    'SIG_HEAD_O_TOT', 'SIG_HEAD_ACC_O_TOT', 'SIG_BODY_O_TOT', 'SIG_BODY_ACC_O_TOT',
                                    'SIG_LEG_O_TOT', 'SIG_LEG_ACC_O_TOT',

                                    'F_FIGHTS_2', 'STR_F_FIGHT', 'TSAC_F_FIGHT', 'TD_F_FIGHT', 'TDAC_F_FIGHT',
                                    'KD_F_FIGHT', 'PASS_F_FIGHT', 'REV_F_FIGHT', 'SUB_F_FIGHT', 'SIG_STR_F_FIGHT',
                                    'SIG_ACC_F_FIGHT', 'SIG_HEAD_F_FIGHT', 'SIG_HEAD_ACC_F_FIGHT', 'SIG_BODY_F_FIGHT',
                                    'SIG_BODY_ACC_F_FIGHT', 'SIG_LEG_F_FIGHT', 'SIG_LEG_ACC_F_FIGHT',

                                    'O_FIGHTS_2', 'STR_O_FIGHT', 'TSAC_O_FIGHT', 'TD_O_FIGHT', 'TDAC_O_FIGHT',
                                    'KD_O_FIGHT', 'PASS_O_FIGHT', 'REV_O_FIGHT', 'SUB_O_FIGHT', 'SIG_STR_O_FIGHT',
                                    'SIG_ACC_O_FIGHT', 'SIG_HEAD_O_FIGHT', 'SIG_HEAD_ACC_O_FIGHT', 'SIG_BODY_O_FIGHT',
                                    'SIG_BODY_ACC_O_FIGHT', 'SIG_LEG_O_FIGHT', 'SIG_LEG_ACC_O_FIGHT',

                                    'F_ROUNDS', 'STR_F_ROUND', 'TSAC_F_ROUND', 'TD_F_ROUND', 'TDAC_F_ROUND',
                                    'KD_F_ROUND', 'PASS_F_ROUND', 'REV_F_ROUND', 'SUB_F_ROUND', 'SIG_STR_F_ROUND',
                                    'SIG_ACC_F_ROUND', 'SIG_HEAD_F_ROUND', 'SIG_HEAD_ACC_F_ROUND', 'SIG_BODY_F_ROUND',
                                    'SIG_BODY_ACC_F_ROUND', 'SIG_LEG_F_ROUND', 'SIG_LEG_ACC_F_ROUND',

                                    'O_ROUNDS', 'STR_O_ROUND', 'TSAC_O_ROUND', 'TD_O_ROUND', 'TDAC_O_ROUND',
                                    'KD_O_ROUND', 'PASS_O_ROUND', 'REV_O_ROUND', 'SUB_O_ROUND', 'SIG_STR_O_ROUND',
                                    'SIG_ACC_O_ROUND', 'SIG_HEAD_O_ROUND', 'SIG_HEAD_ACC_O_ROUND', 'SIG_BODY_O_ROUND',
                                    'SIG_BODY_ACC_O_ROUND', 'SIG_LEG_O_ROUND', 'SIG_LEG_ACC_O_ROUND',

                                    'F_MINS', 'STR_F_MIN', 'TSAC_F_MIN', 'TD_F_MIN', 'TDAC_F_MIN', 'KD_F_MIN',
                                    'PASS_F_MIN', 'REV_F_MIN', 'SUB_F_MIN', 'SIG_STR_F_MIN', 'SIG_ACC_F_MIN',
                                    'SIG_HEAD_F_MIN', 'SIG_HEAD_ACC_F_MIN', 'SIG_BODY_F_MIN', 'SIG_BODY_ACC_F_MIN',
                                    'SIG_LEG_F_MIN', 'SIG_LEG_ACC_F_MIN',

                                    'O_MINS', 'STR_O_MIN', 'TSAC_O_MIN', 'TD_O_MIN', 'TDAC_O_MIN', 'KD_O_MIN',
                                    'PASS_O_MIN', 'REV_O_MIN', 'SUB_O_MIN', 'SIG_STR_O_MIN', 'SIG_ACC_O_MIN',
                                    'SIG_HEAD_O_MIN', 'SIG_HEAD_ACC_O_MIN', 'SIG_BODY_O_MIN', 'SIG_BODY_ACC_O_MIN',
                                    'SIG_LEG_O_MIN', 'SIG_LEG_ACC_O_MIN'])

    stat_df = stat_df.append(pd.DataFrame(results, columns=stat_df.columns))
    stat_df.to_csv('output/striking_df-test.csv', index=False)
    return stat_df

base_url = 'https://www.foxsports.com/ufc/'
fighter_df = fighter_get()
striking_get(fighter_df, base_url)