import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.producer.ProducerConfig;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;

public class MyConfig {

    public static final String TEST_TOPIC = "dbaier_test_topic";

    public MyConfig() {
    }

    Properties readConfig() throws IOException {
        Properties config = new Properties();
        config.load(new FileInputStream("/Users/db/.ccloud/config.properties"));

        config.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");
        config.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");
        config.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringDeserializer");
        config.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringDeserializer");

        return config;
    }
}