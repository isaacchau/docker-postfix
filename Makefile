all:
	 docker build -t isaacchau/postfix .

clean:
	docker image  prune -f
	docker volume prune -f
