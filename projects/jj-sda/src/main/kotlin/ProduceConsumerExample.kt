import org.apache.kafka.clients.consumer.ConsumerRecords
import org.apache.kafka.clients.consumer.KafkaConsumer
import org.apache.kafka.clients.producer.KafkaProducer
import org.apache.kafka.clients.producer.Producer
import org.apache.kafka.clients.producer.ProducerRecord
import org.apache.kafka.common.serialization.StringDeserializer
import org.apache.kafka.common.serialization.StringSerializer
import org.slf4j.LoggerFactory
import java.time.Duration
import java.util.*
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.atomic.AtomicBoolean

private val logger = LoggerFactory.getLogger("kafka-hackathon-jj-sda")

fun main() {
    val service = Executors.newCachedThreadPool()

    val recordsToProduce = 20

    val topic = "jj-sda-test"
    val consumerGroup1 = "jj-sda-consumer-group-1"
    val consumer = Consumer(topic, "Consumer-1", consumerGroup1)
    service.submit {
        consumer.consume()
    }

    val consumer2 = Consumer(topic, "Consumer-2", consumerGroup1)
    service.submit {
        consumer2.consume()
    }

    val consumerGroup2 = "jj-sda-consumer-group-2"
    val consumer3 = Consumer(topic, "Consumer-3", consumerGroup2)
    service.submit {
        consumer3.consume()
    }

    val producer: Producer<String, String> = KafkaProducer(getProducerProperties())
    val producerDone: Future<*> = service.submit {
        for (i in 1..recordsToProduce) {
            val send = producer.send(
                ProducerRecord(
                    topic,
                    i.toString(),
                    UUID.randomUUID().toString()
                )
            )
            logger.info("Producing $i to partition ${send.get().partition()}")
        }
        logger.info("Producing done")
    }

    try {
        producerDone.get()
    } catch (ex: Exception) {
        logger.error("Problem during production", ex)
    } finally {
        logger.debug("Closing producer")
        producer.close(Duration.ofSeconds(1))
        logger.debug("Closed producer")
    }

    Thread.sleep(10000)
    stopConsumer(consumer)
    stopConsumer(consumer2)
    stopConsumer(consumer3)
    service.shutdown()
}

private fun stopConsumer(consumer: Consumer) {
    logger.debug("Closing consumer")
    consumer.close()
    logger.debug("Closed consumer")
}

private class Consumer(
    private val topic: String,
    private val consumerId: String,
    private val consumerGroupId: String
) {
    private val logger = LoggerFactory.getLogger(org.apache.kafka.clients.consumer.Consumer::class.java)
    private val isClosed = AtomicBoolean(false)

    fun consume() {
        val consumer: org.apache.kafka.clients.consumer.Consumer<String, String> = KafkaConsumer(getClientProperties(consumerId, consumerGroupId))
        consumer.subscribe(listOf(topic))
        while (!isClosed.get()) {
            val records: ConsumerRecords<String, String> = consumer.poll(Duration.ofMillis(100))
            records.forEach {
                logger.info(
                    "Consumer {} consumed partition = {}, offset = {}, key = {}, value = {}",
                    consumerId,
                    it.partition(),
                    it.offset(),
                    it.key(),
                    it.value()
                )
            }
        }
        consumer.close()
        logger.info("Consuming finished")
    }

    fun close() {
        isClosed.set(true)
    }
}

fun getProducerProperties() = Properties().also { props ->
    props.putAll(getCommonProperties())
    props["key.serializer"] = StringSerializer::class.java.name
    props["value.serializer"] = StringSerializer::class.java.name
}

fun getClientProperties(consumerId: String, groupId: String) = Properties().also { props ->
    props.putAll(getCommonProperties())
    props["client.id"] = "jj_sda_producer-consumer-example_$consumerId"
    props["group.id"] = groupId
    props["enable.auto.commit"] = "true"
    props["auto.commit.interval.ms"] = "1000"
    props["key.deserializer"] = StringDeserializer::class.java.name
    props["value.deserializer"] = StringDeserializer::class.java.name
}

fun getCommonProperties() = Properties().also { props ->
    props["sasl.jaas.config"] =
        "org.apache.kafka.common.security.plain.PlainLoginModule required username=\"RDUQLT3NZ4TXGSL6\" password=\"28kOn5mwMmR0Ub0RJYG03v7wp7ptN8kGAq9vTyCTsqHPZJVPRUCO44feRFGeV7Tg\";"
    props["bootstrap.servers"] = "SASL_SSL://pkc-4ygn6.europe-west3.gcp.confluent.cloud:9092"
    props["ssl.endpoint.identification.algorithm"] = "https"
    props["security.protocol"] = "SASL_SSL"
    props["sasl.mechanism"] = "PLAIN"
}
