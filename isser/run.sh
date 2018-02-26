#!/bin/bash
source ~/.bash_profile

cd /app/tmr-issuer

#run server
python manage.py runserver -h 0.0.0.0

