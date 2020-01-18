import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Properties;
import java.util.UUID;

public class MyProducer {

    private final MyConfig myConfig = new MyConfig();
    private final int amntOfRecordsToSend = 10000;
    private final String testTopic = MyConfig.TEST_TOPIC;

    public static void main(String[] args) throws IOException {

        new MyProducer().run();
    }

    private void run() throws IOException {
        Properties config = getConfiguration();

        KafkaProducer producer = new KafkaProducer(config);

        Date startDate = new Date();

        sendRecords(producer);
        producer.flush();

        printSummery(startDate);

        producer.close();
    }

    private void sendRecords(KafkaProducer producer) {
        for (int i = 0; i < amntOfRecordsToSend; i++) {
            final ProducerRecord<String, String> record = new ProducerRecord(testTopic, null, UUID.randomUUID().toString());
            producer.send(record, MyProducer::onCompletion);
        }
    }

    private static void onCompletion(RecordMetadata m, Exception e) {
        if (e != null) {
            e.printStackTrace();
        } else {
            System.out.printf("Produced record to topic %s partition [%d] @ offset %d%n", m.topic(), m.partition(), m.offset());
        }
    }

    private void printSummery(Date startDate) {
        Date endDate = new Date();
        long elapsedTime = endDate.getTime() - startDate.getTime();
        System.out.println(amntOfRecordsToSend + " messages where produced to topic " + testTopic);
        System.out.println("It took " + elapsedTime + " milliseconds");
        System.out.println("Ended sending: " + new SimpleDateFormat("HH:mm:ss.SSS").format(endDate));
    }

    private Properties getConfiguration() throws IOException {
        Properties config = myConfig.readConfig();
        config.put(ProducerConfig.BATCH_SIZE_CONFIG, "0");
        config.put(ProducerConfig.ACKS_CONFIG, "all");
        return config;
    }
}
