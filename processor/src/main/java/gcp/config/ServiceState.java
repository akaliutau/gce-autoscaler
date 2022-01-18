package gcp.config;

import com.google.pubsub.v1.PubsubMessage;
import lombok.Getter;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
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
        this.messageMap.put(message.getMessageId(), message);
    }

    public void removeMessage(PubsubMessage message) {
        this.messageMap.remove(message.getMessageId());
    }

    public boolean hasUnfinishedWork(){
        return !this.messageMap.isEmpty();
    }

    @Override
    public String toString() {
        return "ServiceState {" + messageMap + '}';
    }


}
