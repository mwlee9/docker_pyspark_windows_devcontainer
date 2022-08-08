docker stop pyspark

docker rm pyspark

docker run -dp 8889:8888 -p 4040:4040 ^
-it --mount type=bind,source="%cd%"\VOLUMES,target=/home/volumes ^
--name pyspark ^
lee/pyspark ^
jupyter lab --ip=0.0.0.0 --port=8888 --NotebookApp.token='' --allow-root
pause
