import org.apache.kafka.clients.consumer.Consumer
import org.apache.kafka.clients.consumer.ConsumerRecords
import org.apache.kafka.clients.consumer.KafkaConsumer
import org.apache.kafka.clients.producer.KafkaProducer
import org.apache.kafka.clients.producer.Producer
import org.apache.kafka.clients.producer.ProducerRecord
import org.slf4j.LoggerFactory
import java.io.FileInputStream
import java.time.Duration
import java.util.*
import java.util.concurrent.Executors

fun main() {
    val props = Properties()
    props.load(FileInputStream("/home/jj/.ccloud/config"))
    props["bootstrap.servers"] = "SASL_SSL://pkc-4ygn6.europe-west3.gcp.confluent.cloud:9092"
    props["client.id"] = "jj-on-behalf-of-jj_sda"
    props["acks"] = "all"
    props["key.serializer"] = org.apache.kafka.common.serialization.StringSerializer::class.java.name
    props["value.serializer"] = "org.apache.kafka.common.serialization.StringSerializer"

    props.setProperty("group.id", "test2");
    props["auto.offset.reset"] = "earliest"
    props.setProperty("enable.auto.commit", "true");
    props.setProperty("auto.commit.interval.ms", "1000");
    props.setProperty("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
    props.setProperty("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");

    val logger = LoggerFactory.getLogger("kafka-hackathon")

    val topic = "jj-sda-test"
    val producer: Producer<String, String> = KafkaProducer(props)


    val service = Executors.newFixedThreadPool(2)
    service.submit {
        val consumer: Consumer<String, String> = KafkaConsumer(props)
        consumer.subscribe(listOf(topic))
        while (true) {
            val records: ConsumerRecords<String, String> = consumer.poll(Duration.ofMillis(100))
            records.forEach {
                logger.info ("Consumed partition = {}, offset = {}, key = {}, value = {}", it.partition(), it.offset(), it.key(), it.value())
            } }
        consumer.close()
    }
    val producerDone = service.submit {
        for (i in 0..99) {
            val send = producer.send(
                ProducerRecord(
                    topic,
                    i.toString(),
                    i.toString()
                )
            )
            logger.info("sending $i to partition ${send.get().partition()}")
        }
    }

    producerDone.get()
    producer.close(Duration.ofSeconds(1))
    service.shutdown()
}