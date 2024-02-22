#!/usr/bin/python3
# -*- coding: utf-8 -*-
import json
import os
import requests
import subprocess
import sys
import time

def main():
    if len(sys.argv) != 2:
        print("Usage: dtranslatebot-ltd [token]")
        return

    dtb_config = {
        'token': sys.argv[1],
        'translator': {
            'url': 'http://127.0.0.1:5000/'
        }
    }
    dtb_json = json.dumps(dtb_config)
    with open("/usr/local/etc/dtranslatebot.json", "w") as dtb_json_file:
        dtb_json_file.write(dtb_json)

    os.makedirs("/root/libretranslate", mode=755, exist_ok=True)
    lt_env = os.environ.copy()
    lt_env["LT_HOST"] = "127.0.0.1"
    lt_env["LT_PORT"] = "5000"
    lt_env["LT_DISABLE_FILES_TRANSLATION"] = "1"
    lt_env["LT_DISABLE_WEB_UI"] = "1"
    print("[Service] Launching LibreTranslate...")
    lt = subprocess.Popen(["/opt/libretranslate/bin/libretranslate"], cwd="/root/libretranslate", env=lt_env)

    while True:
        try:
            if lt.poll():
                print("[Error] LibreTranslate is not running")
                return lt.returncode
            r = requests.get("http://127.0.0.1:5000/languages", timeout=5)
            if r.status_code == 200:
                break;
            return r.status_code
        except requests.exceptions.ConnectionError:
            time.sleep(1)
        except requests.exceptions.Timeout:
            pass

    os.makedirs("/root/dtranslatebot", mode=755, exist_ok=True)
    os.makedirs("/root/dtranslatebot/db", mode=755, exist_ok=True)
    dtb_env = os.environ.copy()
    dtb_env["DTRANSLATEBOT_STORAGE"] = "/root/dtranslatebot/db"
    print("[Service] Launching dtranslatebot...")
    dtb = subprocess.run(["/usr/local/bin/dtranslatebot", "/usr/local/etc/dtranslatebot.json"], cwd="/root/dtranslatebot", env=dtb_env)
    return dtb.returncode

if __name__ == "__main__":
    sys.exit(main())
