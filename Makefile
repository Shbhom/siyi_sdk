run-sitl-docker:
	docker run --rm -p 5760-5780:5760-5780 -it --network=gcom-x_uasnet --name=uasitl ubcuas/uasitl:copter-arm-4.5.4
