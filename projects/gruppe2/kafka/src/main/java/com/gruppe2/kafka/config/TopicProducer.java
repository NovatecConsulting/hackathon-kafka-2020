package com.gruppe2.kafka.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;


@Service
public class TopicProducer {

    @Value("${spring.kafka.template.default-topic}")
    public String topic;

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    public void send(String toSend) {
        kafkaTemplate.send(topic, toSend);
    }

}