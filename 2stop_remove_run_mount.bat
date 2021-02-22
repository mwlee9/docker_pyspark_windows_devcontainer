docker stop pyspark

docker rm pyspark

docker run -dp 8889:8888 -p 4040:4040 ^
  -p 37899:37899 ^
  -p 5050:5050 ^
  -p 33139-33155:33139-33155 ^
  -p 45029-45045:45029-45045 ^
-it --mount type=bind,source=%cd%\VOLUMES,target=/home/volumes ^
--name pyspark ^
lee/pyspark ^
jupyter notebook --ip=0.0.0.0 --port=8888 --NotebookApp.token='' --allow-root
pause
