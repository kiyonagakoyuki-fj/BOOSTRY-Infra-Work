#!/bin/bash
source ~/.bash_profile

cd /app/tmr-issuer

# async
nohup python async/processor_IssueEvent.py &

#run server
python manage.py runserver -h 0.0.0.0

