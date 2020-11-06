# EBcb EasyBuild Container build

Nov 2020
Notes on Building the container 
Creating a clean build room for Easybuild 

REPOSITORY          TAG                   IMAGE ID            CREATED             SIZE
fredhutch/ls2       eb-4.3.1-foss-2019b   68f1036bb36d        9 minutes ago       2.72GB
fredhutch/ls2       eb-4.3.1-foss-2019b   e24f1e686c7e        10 hours ago        5.09GB
fredhutch/ls2       eb-4.2.1-foss-2019b   89ecd53e1174        4 months ago        5.36GB   
ubuntu              18.04                 56def654ec22        5 weeks ago         63.2MB

Record of trying to reduce the size of the EasyBuild container
/eb contains lmod  modules  software
du -sh /eb   2.4G    /eb

The "build" stage of constructing the container installs EasyBuild and a Toolchain in /eb.
/eb is COPYed into the "easybuild" stage. If any changes are made to ```/eb`` after the copy to 
the final stage it will be copied into a new layer and double the size of the conatiner!
Ensure each step is complete at each stage of the mulit-stage. 

Example of Multi-Stage issues
Initial config of EasyBuild is setup to install into ```/eb``` volume. After EB and the
Toolchain are installed the EasyBuild configuration is modified to install software into
```/app```.  This step needs to be performed in the "build" stage.
