import urllib3
import json

def lambda_handler(event,context):
    URL = urllib3.disable_warnings()
    http = urllib3.PoolManager()
    headers = urllib3.util.make_headers(basic_auth='apluser:nvillage201807+')

    try:
        res = http.request('GET', 'https://api.ibet.jp/v1/PaymentAgent/0x263c201c5e4c5a4cbf9adc81f81f7c67408755e5' , headers=headers)
    except :
        print('error:systemException:can not connect')
        return 1
    else:
        dat = json.loads(res.data.decode('utf-8'))
        if dat['meta']['code'] == 200:
            print('Success!:' + str(dat['meta']['code']))
        else:
            print('error:no data'+ str(dat['meta']['code']))
        return 0
