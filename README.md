# docker2singularity
This script exports a [Docker](https://www.docker.com/) image as a [Singularity](https://sylabs.io/singularity/) `.sif` file. This can be useful for porting Dockerized code to run on shared user systems like clusters, which sometimes run Singularity rather than Docker.

# Prerequisites
- Install Docker (tested with `20.10.6`)

# Usage
1. Build or pull the Docker image you wish to export to a Singularity `.sif` file

	```bash
	docker pull ubuntu:latest
	```

2. Run `docker2singularity.sh` to export the image as a `.sif` file
	
	```bash
	cd docker2singularity
	./docker2singularity.sh ubuntu
	```
	
	This should write a file called `ubuntu.sif` in the current working directory, e.g., `docker2singularity/ubuntu.sif`
	
	Optionally, you can specify where to save the output `.sif` file:
	
	```bash
	./docker2singularity.sh ubuntu $HOME/ubuntu_singularity.sif
	```
	#### Expected Output
	If it worked, you'll see output similiar to the following:
	
	```bash
	Exporting docker image ubuntu --> /Users/matt/ubuntu_singularity.sif 
	
	Image Format: squashfs
	Docker Image: ubuntu
	Container Name: ubuntu_singularity.sif
	
	Inspected Size: 73 MB
	
	(1/10) Creating a build sandbox...
	(2/10) Exporting filesystem...
	(3/10) Creating labels...
	(4/10) Adding run script...
	(5/10) Setting ENV variables...
	(6/10) Adding mount points...
	(7/10) Fixing permissions...
	(8/10) Stopping and removing the container...
	(9/10) Building squashfs container...
	INFO:    Starting build...
	INFO:    Creating SIF file...
	INFO:    Build complete: /tmp/ubuntu_singularity.sif
	(10/10) Moving the image to the output folder...
	     27,717,632 100%   80.25MB/s    0:00:00 (xfr#1, to-chk=0/1)
	Final Size: 27MB
	 Exported Docker image ubuntu --> /Users/matt/ubuntu_singularity.sif 

	```
	
	#### Help
	Run `./docker2singularity -h` to print the help screen, including usage.
	
	# Caveats
	In order to export a Docker image to `.sif` file, one of the following must be true:

	1. The Docker image is available locally (i.e., it has already been built using `docker build` or pulled using `docker pull`)
	
	2. A file named `Dockerfile` exists in the current working directory.

	If a `Dockerfile` is found, you are given the option to build the docker image and then export it to `.sif`.
	
	If neither of these conditions is met, an error message is printed and the program exits without doing anything.