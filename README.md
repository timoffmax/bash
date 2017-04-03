My own collection of bash script for automatization some processes
===================================================================
***

get_random_image.sh
---------------------
#### Description
> This script may download random image from [this](http://lorempixel.com/) site with your parametrs, such as image resolution and theme.
>
> Order of arguments
> 1. destination folder - path to folder for save images;
> 2. how many images you need?;
> 3. width - image width;
> 4. height - image height;
> 5. image theme: 
>	* abstract; 
>	* animals;
>	* business;
>	* cats;
>	* city;
>	* food;
>	* night;
>	* life;
>	* fashion;
>	* people;
>	* nature;
>	* sports;
>	* technics;
>	* transport
 
 #### Sample
 ```bash
 bash get_random_image.sh /var/www/news_portal/webroot/img/articles/ 400 720 480 technics
 ```
