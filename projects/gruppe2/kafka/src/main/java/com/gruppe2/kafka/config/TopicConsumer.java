package com.gruppe2.kafka.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.annotation.PartitionOffset;
import org.springframework.kafka.annotation.TopicPartition;
import org.springframework.stereotype.Service;

@Service
@Slf4j
public class TopicConsumer {

    @KafkaListener(
        topics = "${spring.kafka.template.default-topic}",
        groupId = "gruppe2",
        topicPartitions = @TopicPartition(
            topic = "${spring.kafka.template.default-topic}",
            partitionOffsets = {
                @PartitionOffset(partition = "0", initialOffset = "0")
            })
    )
    public void consume(String record) {
        log.debug("Received record: " + record);
        System.out.println("Received record: " + record);
    }

}