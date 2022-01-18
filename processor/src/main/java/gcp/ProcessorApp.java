package gcp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.io.IOException;

@SpringBootApplication(scanBasePackages = "gcp.*")
public class ProcessorApp {

    public static void main(String[] args) throws IOException {
        SpringApplication.run(ProcessorApp.class, args);
    }

}
