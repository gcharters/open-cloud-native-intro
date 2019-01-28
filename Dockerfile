FROM open-liberty:kernel-java8-ibm
ADD /target/mpservice.tar.gz /opt/ol
EXPOSE 9080 9443
