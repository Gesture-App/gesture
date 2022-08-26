import glob, os
import cv2
import time
from pathlib import Path

Path("./data/open").mkdir(parents=True, exist_ok=True)
Path("./data/closed").mkdir(parents=True, exist_ok=True)
Path("./data/unknown").mkdir(parents=True, exist_ok=True)
os.chdir("./video")
for file in glob.glob("*.mov"):
    name, type = file.rstrip(".mov").split("_")

    count = 0
    vidcap = cv2.VideoCapture(file)
    success, image = vidcap.read()
    print(f"read {file}: {success}")
    while success:
        cv2.imwrite(f"../data/{type}/{name}_{count}.jpg", image)     # save frame as JPEG file
        print(f"  saved: {count}")
        vidcap.set(cv2.CAP_PROP_POS_MSEC,(count * 250))    # added this line 
        success, image = vidcap.read()
        count = count + 1

time.sleep(5000)
