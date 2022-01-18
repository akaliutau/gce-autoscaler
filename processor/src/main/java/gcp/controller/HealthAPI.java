package gcp.controller;

import gcp.config.CustomHealthIndicator;
import org.springframework.boot.actuate.health.Health;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthAPI {

    private final CustomHealthIndicator customHealthIndicator;

    public HealthAPI(CustomHealthIndicator customHealthIndicator) {
        this.customHealthIndicator = customHealthIndicator;
    }

    @GetMapping("/health")
    public Health get() {
        return customHealthIndicator.health();
    }

}
