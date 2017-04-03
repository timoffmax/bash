#!/usr/bin/bash

### How it use? ###
# Order of agruments: #
# 1 - destination folder - path to folder for save images;
# 2 - how many images you need?;
# 3 - width - image width;
# 4 - height - image height;
# 5 - image theme: 
	# abstract; 
	# animals;
	# business;
	# cats;
	# city;
	# food;
	# night;
	# life;
	# fashion;
	# people;
	# nature;
	# sports;
	# technics;
	# transport.

### Sample ###
# bash get_random_image.sh /var/www/news_portal/webroot/img/articles/ 400 720 480 technics

### Get script params ###
destination_folder=$1
quantity=$2
width=$3
height=$4
theme=$5

### Download images ###
cd ${destination_folder}

for (( i = 1; i <= $quantity; i++ )); do
	if [[ ! -f ${i}.jpg ]]; then
		curl http://lorempixel.com/${width}/${height}/technics/ > ${i}.jpg
	fi
done
