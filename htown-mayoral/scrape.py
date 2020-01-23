import requests, json
from selenium import webdriver
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.firefox.firefox_binary import FirefoxBinary


# loads in headless firefox browser to get dynamically generated contests
def selenium_gen():
    binary = FirefoxBinary(r'C:\\Program Files\\Mozilla Firefox\\firefox.exe')
    options = Options()
    options.headless = True
    driver = webdriver.Firefox(firefox_binary=binary, options=options,
                               executable_path=r'C:\Users\jeffb\software\geckodriver.exe')
    return driver


# using the contestPanel- id prefix, get the corresponding contest number
def get_contests():
    contest_ids = []
    driver = selenium_gen()
    driver.get('https://web.archive.org/web/20191116202735/https://www.harrisvotes.com/ElectionResults/ElectionDay')

    contests = driver.find_elements_by_xpath('//div[contains(@id, "contestPanel-")]')

    for contest in contests:
        print(contest)
        contest_label = contest.get_attribute('id')
        contest_ids.append((contest_label.split('-'))[1])
    driver.quit()

    return contest_ids


# using contest number from get_contests(), access the corresponding .json file and save locally
# local saving reduces total number of requests (lowering chance of getting blacklisted)
def get_data(contest_ids):
    for id in contest_ids:
        print(id)
        response = requests.get('http://harrisvotes.com/Data/1119/pv-' + id + '.json')
        result = json.loads(response.content)
        response.close()

        with open('data/contests/' + id + '.json', 'w') as f:
            json.dump(result, f, ensure_ascii=False)


def main():
    print('Getting Contest IDs...')
    contest_ids = get_contests()

    print('Getting Contest Data...')
    get_data(contest_ids)


if __name__ == '__main__':
    main()
