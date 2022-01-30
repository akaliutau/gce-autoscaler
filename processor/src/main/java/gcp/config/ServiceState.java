package gcp.config;

import com.google.pubsub.v1.PubsubMessage;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
@Slf4j
public class ServiceState {

    public enum ServiceStatus {STARTING, WORKING, STOPPING, STOPPED}

    @Getter
    private ServiceStatus status = ServiceStatus.STARTING;

    @Getter
    private Map<String, PubsubMessage> messageMap = new ConcurrentHashMap<>();

    synchronized public void setStatus(ServiceStatus status) {
        this.status = status;
    }

    public void setMessage(PubsubMessage message){
        log.info("adding {} to state", message.getData().toStringUtf8());
        this.messageMap.put(message.getMessageId(), message);
    }

    public void removeMessage(PubsubMessage message) {
        this.messageMap.remove(message.getMessageId());
        log.info("removing {} from state, the size is {}", message.getData().toStringUtf8(), this.messageMap.size());
    }

    public boolean hasUnfinishedWork(){
        return !this.messageMap.isEmpty();
    }

    void print() {
        log.info("      Current state");
        log.info("----------------------------------------");
        if (!hasUnfinishedWork()){
            log.info("Empty");
        }else{
            for (Map.Entry<String, PubsubMessage> msg : messageMap.entrySet()){
                log.info("{} => {}", msg.getKey(), msg.getValue().getData().toStringUtf8());
            }
        }
        log.info("----------------------------------------");
    }

    public String toString(){
        StringBuilder sb = new StringBuilder();
        if (!hasUnfinishedWork()){
            sb.append("Empty");
        }else{
            for (Map.Entry<String, PubsubMessage> msg : messageMap.entrySet()){
                sb.append(String.format("%s => %s", msg.getKey(), msg.getValue().getData().toStringUtf8()));
                sb.append("\n");
            }
        }
        return sb.toString();
    }

    public int size() {
        return this.messageMap.size();
    }



}
