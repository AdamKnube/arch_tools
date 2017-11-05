#!/bin/bash
#
if [ -z $1 ]; then
  echo "You must supply the URL or station number!"
else 
  echo "Playing $1..."
  echo "Press [CTRL]+[C] to stop."
  curl -s $@ | mpg123 -q -
fi  
