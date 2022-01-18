FROM gcr.io/distroless/java11-debian11@sha256:a24bdd8a401a0c9e8fdddce980f09e3d38cc243e392f1cc58bcf898e7ea1d405

COPY target/processor-0.0.1.jar processor.jar
ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-jar", "processor.jar"]

EXPOSE 8080

