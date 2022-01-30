package gcp.config;

import gcp.messaging.EventMessageService;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.annotation.PreDestroy;

@Service
@AllArgsConstructor
@Slf4j
public class ShutdownHandler {

    private EventMessageService eventMessageService;

    @PreDestroy
    public void preDestroyHook() {
        log.info("Service is about to shutdown");
        this.eventMessageService.getState().print();
        try {
            eventMessageService.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
