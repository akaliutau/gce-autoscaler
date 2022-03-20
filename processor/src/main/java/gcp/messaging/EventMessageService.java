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
import java.util.concurrent.TimeoutException;
import java.util.function.Consumer;
import java.util.stream.Collectors;

@Service
@Slf4j
public class EventMessageService {

    private final static int minProcessingTimeSec = 10;
    private final  static int maxProcessingTimeSec = 100;
    private final  static int waitingCycles = 6;
    private final  static int waitingTime = 10;

    private static final Gson gson = new Gson().newBuilder().setPrettyPrinting().create();

    private SimplePublisher processedMessagesPub;
    private SimplePublisher incomingMessagesPub;// used for recovery only
    private SimplePublisher infoChannelPub;     // used for recovery only
    private SimpleSubscriber incomingMessagesSub;

    @Getter
    private ServiceState state;

    public EventMessageService(ServiceState state, Environment env) throws IOException {
        String projectId = env.getRequiredProperty("GOOGLE_CLOUD_PROJECT");
        String mode = env.getRequiredProperty("MODE");
        processedMessagesPub = new SimplePublisher(projectId, "processed_files");
        incomingMessagesPub = new SimplePublisher(projectId, "incoming_files");// used for recovery only
        infoChannelPub = new SimplePublisher(projectId, "info_channel");  // used for recovery only
        incomingMessagesSub = new SimpleSubscriber(projectId, "incoming_files", onMessage());
        incomingMessagesSub.start();
        this.state = state;
        this.state.setStatus(ServiceState.ServiceStatus.WORKING);
        log.info("creating an EventMessageService for project = {}", projectId);
        log.info("mode = {}", mode);
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
            int processingTimeSec = (int) (minProcessingTimeSec + Math.random() * maxProcessingTimeSec);
            log.info("Start processing msg#{}, time to process is {}s", msg.get("id"), processingTimeSec);
            try {
                 Thread.sleep(processingTimeSec * 1000);
            } catch (InterruptedException e) {
                log.error(e.getMessage());
                state.removeMessage(message);
                return;
            }
            log.info("Finish processing msg#{}", msg.get("id"));
            this.processedMessagesPub.publish(message.getData().toStringUtf8());
            state.removeMessage(message);
        };
    }

    public void close() throws TimeoutException, InterruptedException {
        this.state.setStatus(ServiceState.ServiceStatus.STOPPING);
        this.incomingMessagesSub.setAckMessage(false);
        log.warn("Started draining phase");
        infoChannelPub.publish("Started draining phase: \n" + this.state.toString());
        int totalWaitingTime = 0;
        for (int i = 0; i < waitingCycles && this.state.hasUnfinishedWork(); i++){
            log.warn("Still have unfinished work, waiting for {}s", totalWaitingTime);
            infoChannelPub.publish("Still have unfinished work, totalWaiting time: "+ totalWaitingTime +", state size = "+ this.state.size());
            totalWaitingTime += waitingTime;
            Thread.sleep(waitingTime * 1000);
        }
        log.warn("Completed draining phase");
        infoChannelPub.publish("Completed draining phase: \n" + this.state.toString());
        if (state.hasUnfinishedWork()){
            log.warn("Re-publish unfinished work");
            incomingMessagesPub.publish(state.getMessageMap().values().stream().map(m -> m.getData().toStringUtf8()).collect(Collectors.toList()));
        }
        incomingMessagesPub.close();
        incomingMessagesSub.close();
        processedMessagesPub.close();
        infoChannelPub.close();
    }

}
