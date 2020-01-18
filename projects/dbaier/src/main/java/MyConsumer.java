import org.apache.kafka.clients.consumer.*;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.time.Duration;
import java.util.*;

public class MyConsumer {

    private final MyConfig myConfig = new MyConfig();
    private long recordsCountTotal = 0L;
    private final Map<Integer, Long> recordsPerPartition = new HashMap();

    public static void main(String[] args) throws IOException {
        new MyConsumer().run();
    }

    private void run() throws IOException {
        Properties config = getConfig();

        final Consumer<String, String> consumer = new KafkaConsumer(config);
        consumer.subscribe(Arrays.asList(MyConfig.TEST_TOPIC));

        try {
            while (true) {
                pollForRecords(consumer);
            }
        } finally {
            consumer.close();
        }

    }

    private void pollForRecords(Consumer<String, String> consumer) {

        ConsumerRecords<String, String> records = consumer.poll(Duration.ofSeconds(10L));

        for (ConsumerRecord<String, String> record : records) {
            printInfoAboutRecord(record);
            calculateReadRecordsPerPartition(record.partition());
        }

        if (records.count() > 0) {
            printSummeryAndCalculateNewTotalCount(records.count());
        }
    }

    private void printSummeryAndCalculateNewTotalCount(long recordsCount) {
        Date endDate = new Date();
        recordsCountTotal += recordsCount;
        System.out.println("Received " + recordsCount + " records.");
        System.out.println("Received " + recordsCountTotal + " records in total.");
        System.out.println(recordsPerPartition);
        System.out.println("Ended receiving: " + new SimpleDateFormat("HH:mm:ss.SSS").format(endDate));
    }

    private void calculateReadRecordsPerPartition(int partition) {
        Long actRecordsPerPartition = 0L;
        if (recordsPerPartition.containsKey(partition)) {
            actRecordsPerPartition = recordsPerPartition.get(partition);
        }
        actRecordsPerPartition++;
        recordsPerPartition.put(partition, actRecordsPerPartition);
    }

    private void printInfoAboutRecord(ConsumerRecord<String, String> record) {
        int partition = record.partition();
        String key = record.key();
        String value = record.value();
        String text = "Consumed record with key " + key + " and value " + value + " from partition " + partition;
        System.out.println(text);
    }

    private Properties getConfig() throws IOException {
        Properties config = myConfig.readConfig();
        config.put(ConsumerConfig.GROUP_ID_CONFIG, "dbaier-consumer-" + UUID.randomUUID().toString());
        config.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        return config;
    }
}
