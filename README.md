# Get started with cloud-native on the open Java stack 

## Abstract

Have a go at developing a cloud-native microservice on a fully open source and open standards stack. Use the Eclipse MicroProfile programming model to develop a robust and flexible microservice. Deploy it to the Open Liberty server running on the Eclipse OpenJ9 JVM.  Handle microservice metrics and alerting with MicroProfile Metrics and Health.  Finally, build and run the application in a Docker container ready for deployment to your favourite cloud.

### Pre-requisites

To take this quick tutorial you need the following pre-requisites:
1. A Java 8 JDK (the tutorial covers OpenJ9 but other Java distributions should work https://adoptopenjdk.net/?variant=openjdk8-openj9)
2. Apache Maven (https://maven.apache.org/)
3. An editor with Java support (e.g. Eclipse, VS Code, IntelliJ)
4. Docker (if you want to do the steps to build and run in a Docker container)

## Introduction

Cloud-native is an approach to application development and deployment.  It's the product of a number of industry movements over the past 10-15 years - agile development practices, DevOps, Microservices and Cloud.  Cloud-native applications are developed using agile practices, use continuous integration/continuous delivery to streamline deployment, are architected around team-aligned microservices, and leverage the cloud for rapid deployment at scale.

Cloud-native doesn't change the principles around which solutions are chosen and so often avoiding vendor lock-in is key.  Open source and open standards are essential enablers for avoiding vendors lock-in.  This quick tutorial takes you through using an Open Java Stack with Open Source and Open Standards at its heart; OpenJ9, AdoptOpenJDK, Open Liberty, MicroProfile, and Docker.

### 1. A look at OpenJ9 and AdoptOpenJDK

<a href="http://www.eclipse.org/openj9/">OpenJ9</a> is an Eclipse open source JVM. It resulted from the contribution of IBM's JVM implementation to Eclipse and so has many years of high-volume, high-availability production use behind it. It's low footprint, fast startup and high throughput characteristics make it an ideal choice for cloud-native applications - if you pay for your cloud by memory footprint, this is going to be important to you.

Every JVM needs a class library, and most people don't want to build their own Java distribution.  The best place to get a build of OpenJ9 is <a href="https://adoptopenjdk.net/">AdoptOpenJDK</a>.  This provides pre-built binaries of the OpenJDK class libraries with different JVMs.  The OpenJ9 + OpenJDK builds can be found here: https://adoptopenjdk.net/?variant=openjdk8-openj9 . 

In a terminal, type: `which java`

To find out more about the Java you have installed, type: `java -version`

```
openjdk version "1.8.0-internal"
OpenJDK Runtime Environment (build 1.8.0-internal-jenkins_2018_01_30_13_02-b00)
Eclipse OpenJ9 VM (build 2.9, JRE 1.8.0 Linux amd64-64 Compressed References 20180130_57 (JIT enabled, AOT enabled)
OpenJ9   - 8f03f71
OMR      - f410d65
JCL      - 687ce89 based on jdk8u152-b16)
```

### 2. Build a cloud-native microservice 

a. This tutorial comes with a pre-build Microservice for you to study and extend.  Start by cloning the repository.

``` 
git clone https://github.com/gcharters/open-cloud-native-intro.git
```

Inside the `open-cloud-native-intro` directory you'll see a `pom.xml` file for the maven build, a `Dockerfile` to build a docker image and a `src` directory containing the implementation.

b. Compile and run the microservice application

`mvn install liberty:run-server`

Building the application (`mvn install`) also downloads Open Liberty from Maven Central and installs it to `target/liberty`.  The build also packages the application in the `target` directory in a WAR file, called `mpservice.war` and creates a minimal runnable jar containing Open Liberty and the application, called `mpservice.jar`. The `liberty:run-server` command (Maven goal) starts the `mpserviceServer` server in the `target/liberty` directory.

Note: you will see some warnings from the server relating to SSL configuration.  These are expected and will be addressed later.

c. To see what the app does, open a web browser at the following URL: 
<a href="http://localhost:9080/mpservice">http://localhost:9080/mpservice</a>

This displays a simple web page that provides a link to the microservice.  On that page, click on the link to the greeting service.  This will call the microservice URL: 
<a href="http://localhost:9080/mpservice/greeting/hello/John%20Doe">http://localhost:9080/mpservice/greeting/hello/John%20Doe</a>

The response should look like:

```JSON
{
    "message": "Hello",
    "name": "John Doe"
}
```

### 3. A look at MicroProfile

<a href="http://microprofile.io">MicroProfile</a> is a set of industry specifications for developing Cloud-native applications. At its foundation are a small number of Java EE specifications; JAX-RS, CDI and JSON-P, which are then augmented with technologies addressing the needs of Cloud-native applications.  

The tutorial code shows example use of MicroProfile Health and Metrics.  

#### MicroProfile Health

a. When you started Open Liberty, it wrote out a number of available endpoints.  One of those is the health endpoint for the application: <a href="http://localhost:9080/health/">http://localhost:9080/health/</a>.

Open the health endpoint in a browser and you should see:

```JSON
{
    "checks": [
        {
            "data": { },
            "name": "GreetingService",
            "state": "UP"
        }
    ],
    "outcome": "UP"
}
```

The MicroProfile health for this application has an overall "outcome" which is determined by the outcome of any available individual health "checks".  If any of those checks are "DOWN" then the overall outcome is considered to be "DOWN".

As well as returning a JSON description of the health outcome, the health endpoint also reflects the outcome in the http response code.  An outcome of "UP" returns a 200 OK, whereas an outcome of "DOWN" returns a 503 Service Unavailable.  This means the endpoint can be hooked up to Kubernetes liveness or readiness probes to reflect the service availability.

The tutorial application health has one "check".  This is implemented in `src/main/java/my/demo/health/GreetingHealth.java`, the main code of which looks like:

```Java
@Health
@ApplicationScoped
public class GreetingHealth implements HealthCheck {

    public boolean isHealthy() {
        // Check the health of dependencies here
        return true;
    }

    @Override
    public HealthCheckResponse call() {
        boolean up = isHealthy();
        return HealthCheckResponse.named("GreetingService").state(up).build();
    }
}
```

A health check will typically check the availability of resources the service requires in order to correctly function (e.g. services it depends on, database connections, etc).  The tutorial application has a simple example health check which just returns true because this service does not have any other dependencies.

#### MicroProfile Metrics

b. When you started Open Liberty it wrote out an endpoint for MicroProfile Metrics: <a href="http://localhost:9080/metrics/">http://localhost:9080/metrics/</a>. If you tried to access the endpoint you will have found that it requires security configuration to work.  The Metrics endpoint is only available over https and also requires an authorized user in order to prevent disclosing potentially sensitive information.

Edit the source server configuration: `src/main/liberty/config/server.xml`

Note, this server configuration is for demo purposes.  It's not secure and must not be used in production deployments.  

Uncomment this section and save:

```XML
    <variable name="admin.password" value="change_it" />
    <variable name="keystore.password" value="change_it" />
    
    <quickStartSecurity userName="admin" userPassword="${admin.password}"/>
    <keyStore id="defaultKeyStore" password="${keystore.password}"/>   
```

Rebuild and start the server: `mvn clean install liberty:run-server`

Now when you access the metrics endpoint you should be asked to add an exception for the Open Liberty generated self-signed certificate and also requested to then sign in.  Use the admin user (`admin`) and password (`change_it`) from the `server.xml` shown above.

You should now see metrics data like this:

```
# TYPE base:classloader_total_loaded_class_count counter
# HELP base:classloader_total_loaded_class_count Displays the total number of classes that have been loaded since the Java virtual machine has started execution.
base:classloader_total_loaded_class_count 8807
# TYPE base:cpu_system_load_average gauge
...
```

The MicroProfile system metrics, for example, JVM heap, cpu, and garbage collection information, don't require any additional coding - they're produced automatically from the JVM.  The metrics data is in <a href="https://prometheus.io">Prometheus</a> format, the default for MicroProfile.  Using an `Accept` header on the request, you can also receive json format (not show in this tutorial).

The tutorial application also shows a MicroProfile application metric in the microservice implementation: `src/main/java/my/demo/GreetingService.java`

```Java
@Path("/hello")
@RequestScoped
public class GreetingService {


    @Inject
    @ConfigProperty(name="greetingServiceGreeting", defaultValue = "Hello")
    private String greetingStr;

    @GET
    @Path("/{name}")
    @Produces(MediaType.APPLICATION_JSON)
    @Timed(name = "sayHelloTime", displayName = "Call duration", 
           description = "Time spent in call")
    public Greeting sayHello(@PathParam("name") String name) {
        return new Greeting(greetingStr, name);
    }

}
```

The `@Timed` annotation is an example of one of a number of MicroProfile metric types.  This metric produces timing information for the execution of the `sayHello` service method.  Other metrics include counting method access to measure load, or gauges for custom measurement. 

Access the service endpoint to cause some application measurements to be recorded: <a href="http://localhost:9080/mpservice/greeting/hello/John%20Doe">http://localhost:9080/mpservice/greeting/hello/John%20Doe</a>.

These measurement will be available at the `/metrics` endpoint, but you can also just see the applications metrics at: <a href="https://localhost:9443/metrics/application">https://localhost:9443/metrics/application</a>.

c. Externalizing configuration is one of the key tenets of <a href="https://12factor.net/">12-factor applications</a>. Externalizing everything that varies between deployments into configuration means you can build once and deploy in the many stages of your DEvOps pipeline, thus removing the risk of your application changing between deployments and invalidating previous testing.  

The tutorial application has also included the use of MicroProfile Config for injecting a configuration property using `@ConfigProperty`.  Open Liberty supports a number of `config sources`.  The tutorial shows the use of Open Liberty `bootstrap.properties`.  

The `pom.xml` file contains the following configuration for the greeting:

```XML
<bootstrapProperties>
    ...
    <greetingServiceGreeting>Hello</greetingServiceGreeting>
</bootstrapProperties>
```

The maven build puts this value in: `target/ilberty/wlp/usr/servers/mpserviceServer/bootstrap.properites`

```
greetingServiceGreeting=Hello
```

This file is read at server startup and the value injected into the GreetingService bean when it is created.

Edit the pom.xml file and change the greeting to `Bonjour`

```XML
<bootstrapProperties>
    ...
    <greetingServiceGreeting>Bonjour</greetingServiceGreeting>
</bootstrapProperties>
```
Stop the server (e.g. `Ctrl-C`) and start it again: `mvn liberty:run-server`.  

Call the service again to see the greeting change: <a href="http://localhost:9080/mpservice/greeting/hello/John%20Doe">http://localhost:9080/mpservice/greeting/hello/John%20Doe</a>

You should now see:

```JSON
{
    "message": "Bonjour",
    "name": "John Doe"
}
```

This example shows static config injection, where the configuration is read at server start-up.  MicroProfile and Open Liberty also support dynamic configuration injection which means the configuration is re-read periodically (e.g. every 500ms) and so does not require a server restart.

#### MicroProfile OpenAPI

d. When you started Open Liberty it wrote out two endpoints for MicroProfile OpenAPI: <a href="http://localhost:9080/openapi/">http://localhost:9080/openapi/</a> and <a href="http://localhost:9080/openapi/ui/">http://localhost:9080/openapi/ui/</a>.  Clicking on the first link displays a machine-readable yaml description of the service, the format of which is defined by the <a href="https://www.openapis.org/">OpenAPI Initiative</a>.  

```YAML
openapi: 3.0.0
info:
  title: Deployed APIs
  version: 1.0.0
servers:
- url: http://localhost:9080/mpservice
- url: https://localhost:9443/mpservice
paths:
  /greeting/hello/{name}:
    get:
      operationId: sayHello
      parameters:
      - name: name
        in: path
        required: true
        schema:
          type: string
      responses:
        default:
          description: default response
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Greeting'
components:
  schemas:
    Greeting:
      type: object
      properties:
        message:
          type: string
        name:
          type: string
```

This yaml form of the API can be used by API Gateways or generators for clients to work with your service - for example, to generate client code to call your service.  A number of generators are available for a variety of languages.

The second link is to a web page that gives a human-readable representation of the API and also allows you to browse and call the API.  

The machine-readable and Web page API descriptions are created automatically from the JAX-RS definition with no additional work required.  As a result, the information provided for your service is pretty basic.  One of the things MicroProfile OpenAPI provides is a number of annotations to enable you to provide better API documentation.

Edit the `src/main/java/my/demo/GreetingService.java` to add documentation for the operation using the @Operation annotation:

```Java
   ...
    @GET
    @Path("/{name}")
    @Produces(MediaType.APPLICATION_JSON)
    @Timed(name = "sayHelloTime", displayName = "Call duration", 
           description = "Time spent in call")
    @Operation(
        summary = "Get a greeting",
        description = "Returns a greeting for the provided name.")
    public Greeting sayHello(@PathParam("name") String name) {
        return new Greeting(greetingStr, name);
    }
    ...
```

You'll also need to add the package import for the annotation:

```Java
import org.eclipse.microprofile.openapi.annotations.Operation;
```

If your service is not running and your IDE does not automatically recompile the class, re-run your build and start the server:

`mvn compile liberty:run-server`

Browse the OpenAPI endpoint <a href="http://localhost:9080/openapi/">http://localhost:9080/openapi/</a>

You'll see that your API now has additional documentation:

```yaml
...
  /greeting/hello/{name}:
    get:
      summary: Get a greeting
      description: Returns a greeting for the provided name.
      operationId: sayHello
      parameters:
...
```

There are additional annotations available to help you document the parameters and more.

#### Further Reading

MicroProfile has many other important capabilities, such as a type-safe REST client, and fault tolerance (the ability to gracefully handle failures in service dependencies).  Visit the <a href="https://openliberty.io/guides/?search=MicroProfile&key=tag">Open Liberty MicroProfile Guides</a> for more details and deeper dives into what we've covered here.

### 5. Containerization (Docker)

Docker has rapidly become the containerization technology of choice for deploying cloud-native applications. All major cloud vendors support Docker, including IBM Cloud and IBM Cloud Private. 

The tutorial includes a Dockerfile for building a docker image for the Microservice.  This Dockerfile is based on the Open Liberty docker image from Docker Hub and adds in the project's server configuration and application from an Open Liberty 'usr server package'.  A usr server package only contains an application and server configuration and is designed to be unzipped over an existing Open Liberty installation (such as the one on the Liberty Docker image).  The advantage of this approach over putting a 'fat jar' (an option supported by Liberty as well as Spring Boot) which contains a lot of infrastructure code, in a docker container, is Docker will cache the pre-req infrastructure layers (e.g. Open Liberty, Java, etc) which makes building and deploying much faster.

a. Build a usr server package

By default the `pom.xml` builds a 'fat jar': `target/mpservice.jar` so we need to build a different package that only includes the server configuration and application (not the server runtime) - a `usr` server package.

The project's maven pom file includes a maven profile for building a usr package, which isn't built by default.  Build the usr server package with: `mvn -P usr-package install`

This results in a server zip package: `target/defaultServer.zip`.  In the `usr-package` build we also use the name `defaultServer` for the server because this is the name of the server the base Liberty Docker images automatically runs when the container is started.

b. Build and run in Docker

In the directory where the `Dockerfile` is located run: `docker build -t my-demo:mpservice .`

If the server is already running, stop it: `mvn liberty:stop-server` or `Ctrl-C`

Run the docker image: `docker run -p 9080:9080 -p 9443:9443 my-demo:mpservice`

Because the service is running in docker you need to access it on 127.0.0.1: <a href="http://127.0.0.1:9080/mpservice/greeting/hello/John%20Doe">http://127.0.0.1:9080/mpservice/greeting/hello/John%20Doe</a>

Note: the `open-liberty` image referenced in the Dockerfile is based on IBM Java (built on Open J9) because we wanted to re-use the official Open Liberty Docker image. Creating an image based on Open J9 would be relatively straightforward.

## Summary

Congratulations, you've have built, a cloud-native application, seen how you can monitor it for health and metrics, change it's configuration, and package and run it in Docker, ready for deployment to your cloud of choice.  I recommend IBM Cloud or IBM Cloud Private, of course ;)
