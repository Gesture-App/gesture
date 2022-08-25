FROM python:3.9

WORKDIR /usr/src/app

RUN pip install opencv-python-headless==4.6.0.66

COPY . .

CMD [ "python", "./clean_data.py" ]
