### h2 My own collection of bash script for automatization some processes

***

### h4 get_random_image.sh
h5 This script may download random image from [this](http://lorempixel.com/) site with your parametrs, such as image resolution and theme.

* 1 - destination folder - path to folder for save images;
* 2 - how many images you need?;
* 3 - width - image width;
* 4 - height - image height;
* 5 - image theme: 
	1. abstract; 
	2. animals;
	3. business;
	4. cats;
	5. city;
	6. food;
	7. night;
	8. life;
	9. fashion;
	10. people;
	11. nature;
	12. sports;
	13. technics;
	14 transport
 
 h5 Sample
 ```bash
 bash get_random_image.sh /var/www/news_portal/webroot/img/articles/ 400 720 480 technics
 ```
