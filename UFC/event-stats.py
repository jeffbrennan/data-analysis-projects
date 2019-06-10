import requests
import pandas as pd
from bs4 import BeautifulSoup
import unidecode
import timing
fox_base_url = ('https://www.foxsports.com/ufc/')

def fox_event_get(base_url, fighter_df):
    results = []

    for i in range(len(fighter_df['Link'])):
        name = fighter_df['Name'][i]
        print('Grabbing event results for ' + name)

        try:
            response = requests.get(base_url + fighter_df['Link'][i] + '-results')
            html = response.content
            page = BeautifulSoup(html, 'html.parser')
            table = page.find_all('tbody')[2]  # 1st table is the fighter info, 2nd is event info

            for row in table.find_all('tr'):
                result_len = len(row.find_all('td'))
                result = [name] + [row.find_all('td')[i].text.strip('\n') for i in range(result_len)]

                # fox displays a title l/w as an image instead of plain text | scrapes alt text for the image
                # certain events lack all row data and calling index 7 results in error
                # if l/w is blank and fight length is not blank
                if not result[7] and result[6]:
                    result[7] = row.find_all('td')[6].find('img')['alt']
                    results.append(result)
                else:
                    results.append(result)

        except IndexError:  # some listed pages lead to 404 errors
            print(name + ' returns 404 error')
            continue

    event_df = pd.DataFrame(columns=['Fighter', 'Date', 'Event', 'Class', 'Opponent',
                                     'Method', 'Length', 'Result'])

    event_df = event_df.append(pd.DataFrame(results, columns=event_df.columns))
    event_df.to_csv('event_df.csv', index=False)
    return event_df

# Spits 'fight length' into round and time
def event_transform(event_df):
    last_rounds = []
    round_times = []

    # clarify column name
    event_df['Fight_Length'] = event_df['Length']

    # add a column
    for i in range(len(event_df)):
        print(i)
        try:
            if ',' in event_df['Fight_Length'][i]:
                last_round = event_df['Fight_Length'][i].split(',')[0]
                round_time = event_df['Fight_Length'][i].split(',')[1].strip()
            else:
                last_round = event_df['Fight_Length'][i]
                round_time = '0:00'
        except TypeError:
            last_round = ''
            round_time = ''

        last_rounds.append(last_round)
        round_times.append(round_time)

    event_df['Last_Round'] = last_rounds
    event_df['Round_Time'] = round_times

    event_df = event_df.drop(['Fight_Length', 'Length'], axis=1)
    event_df.to_csv('output/event-df-trans.csv')
    return event_df

fox_df = pd.read_csv('fox_df.csv')
event_df = fox_event_get(fox_base_url, fox_df)
clean_event_df = event_transform(event_df)
