/*
    Oracle Wallet ile bagli problem oldugu ucun python proxy server istifade etdim
*/
from flask import Flask, Response, request
from datetime import datetime
import requests

app = Flask(__name__)

@app.route("/cbar.xml")
def proxy():
    date = request.args.get('date')
    if not date:
        date = datetime.today().strftime('%d.%m.%Y')
    url = f"https://www.cbar.az/currencies/{date}.xml"
    r = requests.get(url)
    xml_text = r.text

    '''
    print("----------- XML TEXT -----------")
    print(xml_text)
    print("----------- END OF XML -----------")
    '''
    #if not xml_text.startswith('<?xml'):
        #xml_text = '<?xml version="1.0" encoding="UTF-8"?>\n' + xml_text

    return Response(
        xml_text,
        status=r.status_code,
        mimetype="application/xml",
        #content_type='application/xml; charset=UTF-8'
    )

app.run(host='localhost', port=5000)