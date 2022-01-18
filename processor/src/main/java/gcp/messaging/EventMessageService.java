package gcp.messaging;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.google.pubsub.v1.PubsubMessage;
import gcp.config.ServiceState;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.Map;
import java.util.function.Consumer;
import java.util.stream.Collectors;

@Service
@Slf4j
public class EventMessageService {

    private int processingTimeSec = 30;

    private static final Gson gson = new Gson().newBuilder().setPrettyPrinting().create();

    private SimplePublisher processedMessagesPub;
    private SimplePublisher incomingMessagesPub;// used for recovery only
    private SimpleSubscriber incomingMessagesSub;

    @Getter
    private ServiceState state;

    public EventMessageService(ServiceState state, Environment env) throws IOException {
        String projectId = env.getRequiredProperty("GOOGLE_CLOUD_PROJECT");
        processedMessagesPub = new SimplePublisher(projectId, "processed_files");
        incomingMessagesPub = new SimplePublisher(projectId, "incoming_files");// used for recovery only
        incomingMessagesSub = new SimpleSubscriber(projectId, "incoming_files", onMessage());
        incomingMessagesSub.start();
        this.state = state;
        this.state.setStatus(ServiceState.ServiceStatus.WORKING);
        log.info("creating an EventMessageService for project = {}", projectId);
        log.info("processingTimeSec= {}", this.processingTimeSec);

    }

    private Consumer<PubsubMessage> onMessage() {
        return message -> {
            Map<String, String> msg = gson.fromJson(
                    message.getData().toStringUtf8(),
                    new TypeToken<Map<String, String>>() {
                    }.getType());
            log.info("Message: {} ", msg);
            log.info("Updating state");
            state.setMessage(message);
            log.info("Start processing");
            try {
                Thread.sleep(processingTimeSec * 1000);
            } catch (InterruptedException e) {
                log.error(e.getMessage());
                state.removeMessage(message);
                return;
            }
            log.info("Finish processing");
            this.processedMessagesPub.publish(message.getData().toStringUtf8());
            state.removeMessage(message);
        };
    }

    public void close() {
        this.state.setStatus(ServiceState.ServiceStatus.STOPPING);
        processedMessagesPub.close();
        incomingMessagesSub.close();
        if (state.hasUnfinishedWork()){
            log.warn("Re-publish unfinished work");
            incomingMessagesPub.publish(state.getMessageMap().values().stream().map(m -> m.getData().toStringUtf8()).collect(Collectors.toList()));
            try {
                Thread.sleep(5000);
            } catch (InterruptedException e) {
                log.error(e.getMessage());
            }
            incomingMessagesPub.close();
        }
    }

}
