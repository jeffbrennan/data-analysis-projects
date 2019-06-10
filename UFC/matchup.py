import pandas as pd

df = pd.read_csv('output/dataset.csv')
# TODO: add difference column
def matchup_stats(fighter_A, fighter_B, df):
    result = []
    a_loc = df.loc[df['Name'] == fighter_A].index[0]
    b_loc = df.loc[df['Name'] == fighter_B].index[0]
    locs = [a_loc, b_loc]

    bio_stats = ['Age', 'Height', 'Weight', 'BMI', 'Reach', 'HR_Ratio', 'Style']

    striking_o = ['STR_F_MIN', 'TSAC_F_MIN']
    sig_striking_o = ['SIG_STR_F_MIN', 'SIG_ACC_F_MIN', 'SIG_HEAD_F_MIN', 'SIG_HEAD_ACC_F_MIN',
                      'SIG_BODY_F_MIN', 'SIG_BODY_ACC_F_MIN', 'SIG_LEG_F_MIN', 'SIG_LEG_ACC_F_MIN']
    striking_d = ['STR_O_MIN', 'TSAC_O_MIN']
    sig_striking_d = ['SIG_STR_O_MIN', 'SIG_ACC_O_MIN', 'SIG_HEAD_O_MIN', 'SIG_HEAD_ACC_O_MIN',
                      'SIG_BODY_O_MIN', 'SIG_BODY_ACC_O_MIN', 'SIG_LEG_O_MIN', 'SIG_LEG_ACC_O_MIN']

    grappling_o = ['PASS_F_MIN', 'REV_F_MIN', 'SUB_F_MIN']
    grappling_d = ['PASS_O_MIN', 'REV_O_MIN', 'SUB_O_MIN']
    columns = [bio_stats, striking_o, sig_striking_o, striking_d, sig_striking_d, grappling_o, grappling_d]

    for fighter in locs:
        for section in columns:
            for stat in section:
                result.append(df[stat][fighter])

    return result, columns


def matchup_printout(result, columns, fighter_A, fighter_B):
    print('========== BIOGRAPHY ==========')

    bio_df = pd.DataFrame(columns=['Stat', fighter_A, fighter_B])
    bio_df['Stat'] = columns[0]
    bio_df[fighter_A] = result[:7]
    bio_df[fighter_B] = result[33:40]
    print(bio_df)

    print('\n========== STRIKING OFFENSE ==========')
    str_o_df = pd.DataFrame(columns=['Stat', fighter_A, fighter_B])
    str_o_df['Stat'] = (columns[1] + columns[2])
    str_o_df[fighter_A] = result[7:17]
    str_o_df[fighter_B] = result[40:50]
    print(str_o_df)

    print('\n========== STRIKING DEFENSE ==========')
    str_d_df = pd.DataFrame(columns=['Stat', fighter_A, fighter_B])
    str_d_df['Stat'] = (columns[3] + columns[4])
    str_d_df[fighter_A] = result[17:27]
    str_d_df[fighter_B] = result[50:60]
    print(str_d_df)

    print('\n=========== GRAPPLING ===========')
    grap_df = pd.DataFrame(columns=['Stat', fighter_A, fighter_B])
    grap_df['Stat'] = (columns[5] + columns[6])
    grap_df[fighter_A] = result[27:33]
    grap_df[fighter_B] = result[60:66]
    print(grap_df)

matchup = input('Enter fighters separated by a comma: ')
fighter_A = matchup.split(',')[0].strip()
fighter_B = matchup.split(',')[1].strip()

result, columns = matchup_stats(fighter_A, fighter_B, df)
matchup_printout(result, columns, fighter_A, fighter_B)
